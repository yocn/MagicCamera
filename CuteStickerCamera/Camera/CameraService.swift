import AVFoundation
import UIKit

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

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published private(set) var permissionState: CameraPermissionState = .ready
    @Published private(set) var capturedImage: UIImage?
    @Published private(set) var isCapturing = false

    private let sessionQueue = DispatchQueue(label: "cute-camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var currentPosition: AVCaptureDevice.Position = .front
    private var isConfigured = false

    func start() {
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
        sessionQueue.async { [session] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    func switchCamera() {
        currentPosition = currentPosition == .front ? .back : .front
        sessionQueue.async { [weak self] in
            self?.replaceCameraInput()
        }
    }

    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning, !self.isCapturing else { return }
            self.isCapturing = true
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            settings.photoQualityPrioritization = .speed
            if let connection = self.photoOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
                connection.isVideoMirrored = self.currentPosition == .front
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureAndRun() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .high
                defer { self.session.commitConfiguration() }
                self.replaceCameraInput()
                guard self.session.canAddOutput(self.photoOutput) else {
                    self.setPermissionState(.unavailable)
                    return
                }
                self.session.addOutput(self.photoOutput)
                self.isConfigured = true
            }
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    private func replaceCameraInput() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition) else {
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

    private func setPermissionState(_ state: CameraPermissionState) {
        DispatchQueue.main.async { self.permissionState = state }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { DispatchQueue.main.async { self.isCapturing = false } }
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.capturedImage = image }
    }
}
