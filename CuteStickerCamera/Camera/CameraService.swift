import AVFoundation
import UIKit
import os

enum CameraPermissionState: Equatable {
    case ready
    case cameraDenied
    case unavailable

    var message: String? {
        switch self {
        case .ready: nil
        case .cameraDenied: "需要相机权限才能拍照，请前往设置开启。"
        case .unavailable: "这台设备暂时不能使用相机。"
        }
    }

    /// Sticker placement is useful even in the simulator, where no camera is available.
    var allowsStickerEditing: Bool {
        true
    }

    /// The unavailable-camera notice should not cover a newly added sticker.
    var allowsPermissionOverlayInteraction: Bool {
        self == .cameraDenied
    }
}

enum CameraMessage: Equatable {
    case sessionInterrupted
    case transient(String)

    var text: String {
        switch self {
        case .sessionInterrupted:
            "相机暂时中断，正在恢复。"
        case .transient(let text):
            text
        }
    }

    func clearedWhenSessionRecovers() -> CameraMessage? {
        switch self {
        case .sessionInterrupted: nil
        case .transient: self
        }
    }
}

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published private(set) var permissionState: CameraPermissionState = .ready
    @Published private(set) var capturedImage: UIImage?
    @Published private(set) var isCapturing = false
    @Published private(set) var dualCamera: DualCameraSession?
    @Published private(set) var isTransitioning = false
    @Published private(set) var cameraMessage: CameraMessage?
    private(set) var capturedFrontImage: UIImage?
    let isPictureInPictureSupported = DualCameraSession.isSupported
    var isPictureInPictureEnabled: Bool { dualCamera != nil }

    private let sessionQueue = DispatchQueue(label: "cute-camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var currentPosition: AVCaptureDevice.Position = .front
    private var isConfigured = false
    private var captureStartedAt: Date?
    // These fields are confined to sessionQueue; published UI state is main-thread only.
    private var activeDualCamera: DualCameraSession?
    private var wantsRunning = false
    private var captureInFlight = false
    private var activeCaptureID: Int64?
    private var pendingFrontImage: UIImage?
    private var observers: [NSObjectProtocol] = []
    private let captureLogger = Logger(subsystem: "com.yocn.CuteStickerCamera", category: "CaptureTiming")

    override init() {
        super.init()
        for name in [AVCaptureSession.runtimeErrorNotification, AVCaptureSession.wasInterruptedNotification, AVCaptureSession.interruptionEndedNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] notification in
                guard let affected = notification.object as? AVCaptureSession else { return }
                self?.sessionQueue.async { [weak self] in
                    self?.handleSessionNotification(notification, session: affected)
                }
            })
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        let dual = activeDualCamera
        let single = session
        sessionQueue.async {
            dual?.tearDown()
            if single.isRunning { single.stopRunning() }
        }
    }

    func start() {
        sessionQueue.async { [weak self] in self?.wantsRunning = true }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                granted ? self?.configureAndRun() : self?.setPermissionState(.cameraDenied)
            }
        default:
            setPermissionState(.cameraDenied)
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.wantsRunning = false
            self.stopDualCamera()
            if self.session.isRunning { self.session.stopRunning() }
            self.finishCapture()
        }
    }

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self, self.activeDualCamera == nil, !self.captureInFlight else { return }
            self.currentPosition = self.currentPosition == .front ? .back : .front
            self.replaceCameraInput()
        }
    }

    func setPictureInPictureEnabled(_ enabled: Bool) {
        guard !isTransitioning, !isCapturing else { return }
        isTransitioning = true
        sessionQueue.async { [weak self] in
            guard let self else { return }
            defer { DispatchQueue.main.async { self.isTransitioning = false } }
            guard self.wantsRunning, !self.captureInFlight else { return }
            if enabled {
                guard self.activeDualCamera == nil, self.isPictureInPictureSupported else { return }
                if self.session.isRunning { self.session.stopRunning() }
                do {
                    let dual = try DualCameraSession(queue: self.sessionQueue) { [weak self] in
                        self?.fallbackToSingleCamera(message: DualCameraError.budget.localizedDescription)
                    }
                    self.activeDualCamera = dual
                    dual.session.startRunning()
                    guard dual.session.isRunning else { throw DualCameraError.configuration }
                    DispatchQueue.main.async {
                        self.dualCamera = dual
                        self.permissionState = .ready
                        self.cameraMessage = nil
                    }
                } catch {
                    self.fallbackToSingleCamera(message: error.localizedDescription)
                }
            } else {
                self.stopDualCamera()
                self.runSingleCamera()
            }
        }
    }

    private func stopDualCamera() {
        activeDualCamera?.tearDown()
        activeDualCamera = nil
        DispatchQueue.main.async { self.dualCamera = nil }
    }

    private func fallbackToSingleCamera(message: String) {
        stopDualCamera()
        finishCapture()
        DispatchQueue.main.async { self.cameraMessage = .transient(message) }
        if wantsRunning { runSingleCamera() }
    }

    private func handleSessionNotification(_ notification: Notification, session affected: AVCaptureSession) {
        guard affected === session || affected === activeDualCamera?.session else { return }
        let isDual = affected === activeDualCamera?.session
        guard isDual || activeDualCamera == nil else { return }
        if notification.name == AVCaptureSession.interruptionEndedNotification {
            if wantsRunning, activeDualCamera == nil { runSingleCamera() }
            return
        }
        let error = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError
        captureLogger.error("camera session interrupted/failed: \(error?.description ?? notification.name.rawValue, privacy: .public)")
        if isDual {
            fallbackToSingleCamera(message: DualCameraError.configuration.localizedDescription)
        } else {
            finishCapture()
            setPermissionState(.unavailable)
            DispatchQueue.main.async { self.cameraMessage = .sessionInterrupted }
        }
    }

    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self, !self.captureInFlight else { return }
            let activeSession = self.activeDualCamera?.session ?? self.session
            guard activeSession.isRunning, !activeSession.isInterrupted else { return }
            let output = self.activeDualCamera?.photoOutput ?? self.photoOutput
            if let dual = self.activeDualCamera {
                guard let front = dual.snapshot() else {
                    DispatchQueue.main.async { self.cameraMessage = .transient("前摄画面还没准备好，请稍等再拍。") }
                    return
                }
                self.pendingFrontImage = front
            } else {
                self.pendingFrontImage = nil
            }
            self.captureInFlight = true
            DispatchQueue.main.async {
                self.isCapturing = true
                self.cameraMessage = nil
            }
            self.captureStartedAt = Date()
            let settings = AVCapturePhotoSettings()
            self.activeCaptureID = settings.uniqueID
            settings.flashMode = .off
            settings.photoQualityPrioritization = .speed
            if let connection = output.connection(with: .video) {
                CameraConnectionConfiguration.apply(to: connection, mirrored: self.activeDualCamera == nil && self.currentPosition == .front)
            }
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureAndRun() {
        sessionQueue.async { [weak self] in
            guard let self, self.wantsRunning, self.activeDualCamera == nil else { return }
            self.runSingleCamera()
        }
    }

    private func runSingleCamera() {
        guard wantsRunning else { return }
        if !isConfigured {
            session.beginConfiguration()
            session.sessionPreset = .high
            defer { session.commitConfiguration() }
            replaceCameraInput()
            guard currentInput != nil else { return }
            guard session.canAddOutput(photoOutput) else {
                setPermissionState(.unavailable)
                return
            }
            session.addOutput(photoOutput)
            isConfigured = true
        }
        if !session.isRunning { session.startRunning() }
        let isReady = session.isRunning && !session.isInterrupted
        setPermissionState(isReady ? .ready : .unavailable)
        if isReady {
            DispatchQueue.main.async {
                self.cameraMessage = self.cameraMessage?.clearedWhenSessionRecovers()
            }
        }
    }

    private func finishCapture() {
        captureInFlight = false
        activeCaptureID = nil
        pendingFrontImage = nil
        DispatchQueue.main.async { self.isCapturing = false }
    }

    private func replaceCameraInput() {
        guard let device = cameraDevice(for: currentPosition) else {
            setPermissionState(.unavailable)
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.beginConfiguration()
            if let currentInput { session.removeInput(currentInput) }
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                setPermissionState(.unavailable)
                return
            }
            session.addInput(input)
            currentInput = input
            session.commitConfiguration()
        } catch {
            setPermissionState(.unavailable)
        }
    }

    private func cameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        guard position == .back else {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
        }
        let types: [(RearCameraKind, AVCaptureDevice.DeviceType)] = [
            (.triple, .builtInTripleCamera),
            (.dualWide, .builtInDualWideCamera),
            (.dual, .builtInDualCamera),
            (.wide, .builtInWideAngleCamera)
        ]
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: types.map(\.1), mediaType: .video, position: .back
        )
        let available = Set(types.compactMap { kind, type in
            discovery.devices.contains(where: { $0.deviceType == type }) ? kind : nil
        })
        guard let preferred = RearCameraSelection.preferred(from: available),
              let type = types.first(where: { $0.0 == preferred })?.1 else { return nil }
        return discovery.devices.first(where: { $0.deviceType == type })
    }

    private func setPermissionState(_ state: CameraPermissionState) {
        DispatchQueue.main.async { self.permissionState = state }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let data = error == nil ? photo.fileDataRepresentation() : nil
        sessionQueue.async { [weak self] in
            guard let self, self.captureInFlight, self.activeCaptureID == photo.resolvedSettings.uniqueID else { return }
            if let started = self.captureStartedAt {
                self.captureLogger.notice("photo callback in \(Date().timeIntervalSince(started) * 1000) ms")
            }
            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { self.cameraMessage = .transient("拍照失败，请再试一次。") }
                return
            }
            let front = self.pendingFrontImage
            DispatchQueue.main.async {
                self.capturedFrontImage = front
                self.capturedImage = image
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        sessionQueue.async { [weak self] in
            guard let self, self.activeCaptureID == resolvedSettings.uniqueID else { return }
            if let error {
                DispatchQueue.main.async { self.cameraMessage = .transient(error.localizedDescription) }
            }
            self.finishCapture()
        }
    }
}
