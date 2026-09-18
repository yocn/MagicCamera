import AVFoundation
import CoreImage
import UIKit

enum DualCameraError: LocalizedError {
    case unsupported, configuration, budget

    var errorDescription: String? {
        switch self {
        case .unsupported: "这台设备不支持前后双摄。"
        case .configuration: "双摄暂时无法启动，已恢复单摄。"
        case .budget: "设备负载较高，已关闭双摄。"
        }
    }
}

/// All session operations and frame callbacks run on CameraService's sessionQueue.
/// Only the layer geometry is managed by the main-thread preview hosts.
final class DualCameraSession: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureMultiCamSession()
    let photoOutput = AVCapturePhotoOutput()
    let rearPreview = AVCaptureVideoPreviewLayer()
    let frontPreview = AVCaptureVideoPreviewLayer()
    private let frontOutput = AVCaptureVideoDataOutput()
    private let imageContext = CIContext()
    private var latestBuffer: CVPixelBuffer?
    private var latestFrameTime: CFTimeInterval = 0
    private var pressureObservations: [NSKeyValueObservation] = []
    private var isTornDown = false
    private var originalFormats: [(device: AVCaptureDevice, format: AVCaptureDevice.Format, min: CMTime, max: CMTime)] = []

    static var isSupported: Bool { devicePair() != nil }

    private static func devicePair() -> (AVCaptureDevice, AVCaptureDevice)? {
        guard AVCaptureMultiCamSession.isMultiCamSupported else { return nil }
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified
        )
        guard let rear = discovery.devices.first(where: { $0.position == .back }),
              let front = discovery.devices.first(where: { $0.position == .front }),
              discovery.supportedMultiCamDeviceSets.contains(where: { $0.contains(rear) && $0.contains(front) }) else { return nil }
        return (rear, front)
    }

    init(queue: DispatchQueue, onPressure: @escaping () -> Void) throws {
        super.init()
        guard let (rear, front) = Self.devicePair() else { throw DualCameraError.unsupported }
        do {
            try configure(rear: rear, front: front, queue: queue)
            guard MultiCameraPolicy.canRun(hardwareCost: session.hardwareCost, pressureCost: session.systemPressureCost) else {
                throw DualCameraError.budget
            }
            guard ![rear, front].contains(where: { Self.isUnderPressure($0.systemPressureState) }) else {
                throw DualCameraError.budget
            }
            pressureObservations = [rear, front].map { device in
                device.observe(\.systemPressureState, options: [.new]) { [weak self] device, _ in
                    guard Self.isUnderPressure(device.systemPressureState) else { return }
                    queue.async { [weak self] in
                        guard let self, !self.isTornDown else { return }
                        onPressure()
                    }
                }
            }
        } catch {
            tearDown()
            throw error
        }
    }

    private static func isUnderPressure(_ state: AVCaptureDevice.SystemPressureState) -> Bool {
        state.level == .serious || state.level == .critical || state.level == .shutdown
    }

    private func configure(rear: AVCaptureDevice, front: AVCaptureDevice, queue: DispatchQueue) throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        // MultiCam always uses inputPriority; never set a single-camera preset.
        let rearInput = try addInput(rear, maximumWidth: 1920)
        let frontInput = try addInput(front, maximumWidth: 1280)
        guard let rearPort = rearInput.ports.first(where: { $0.mediaType == .video }),
              let frontPort = frontInput.ports.first(where: { $0.mediaType == .video }),
              session.canAddOutput(photoOutput), session.canAddOutput(frontOutput) else {
            throw DualCameraError.configuration
        }
        session.addOutputWithNoConnections(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .speed
        frontOutput.alwaysDiscardsLateVideoFrames = true
        frontOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        frontOutput.setSampleBufferDelegate(self, queue: queue)
        session.addOutputWithNoConnections(frontOutput)
        try connect(AVCaptureConnection(inputPorts: [rearPort], output: photoOutput), mirrored: false)
        try connect(AVCaptureConnection(inputPorts: [frontPort], output: frontOutput), mirrored: true)
        rearPreview.setSessionWithNoConnection(session)
        frontPreview.setSessionWithNoConnection(session)
        rearPreview.videoGravity = .resizeAspectFill
        frontPreview.videoGravity = .resizeAspectFill
        try connect(AVCaptureConnection(inputPort: rearPort, videoPreviewLayer: rearPreview), mirrored: false)
        try connect(AVCaptureConnection(inputPort: frontPort, videoPreviewLayer: frontPreview), mirrored: true)
    }

    private func addInput(_ device: AVCaptureDevice, maximumWidth: Int32) throws -> AVCaptureDeviceInput {
        let candidates = device.formats.filter { format in
            let size = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return format.isMultiCamSupported && size.width <= maximumWidth && size.height <= 1080 &&
                size.width >= 640 && format.videoSupportedFrameRateRanges.contains { $0.minFrameRate <= 30 && $0.maxFrameRate >= 30 }
        }
        guard let format = candidates.sorted(by: {
            if $0.isVideoBinned != $1.isVideoBinned { return $0.isVideoBinned }
            let lhs = CMVideoFormatDescriptionGetDimensions($0.formatDescription)
            let rhs = CMVideoFormatDescriptionGetDimensions($1.formatDescription)
            return lhs.width * lhs.height > rhs.width * rhs.height
        }).first else { throw DualCameraError.configuration }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw DualCameraError.configuration }
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        originalFormats.append((device, device.activeFormat, device.activeVideoMinFrameDuration, device.activeVideoMaxFrameDuration))
        session.addInputWithNoConnections(input)
        device.activeFormat = format
        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
        device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
        input.videoMinFrameDurationOverride = CMTime(value: 1, timescale: 30)
        return input
    }

    private func connect(_ connection: AVCaptureConnection, mirrored: Bool) throws {
        guard session.canAddConnection(connection) else { throw DualCameraError.configuration }
        session.addConnection(connection)
        CameraConnectionConfiguration.apply(to: connection, mirrored: mirrored)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isTornDown else { return }
        latestBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        latestFrameTime = CACurrentMediaTime()
    }

    /// Take a fresh, already portrait-oriented and mirrored frame at shutter time.
    /// No UIImage conversions or SwiftUI invalidations on every video frame.
    func snapshot() -> UIImage? {
        guard let buffer = latestBuffer, CACurrentMediaTime() - latestFrameTime < 0.5 else { return nil }
        let image = CIImage(cvPixelBuffer: buffer)
        guard let cgImage = imageContext.createCGImage(image, from: image.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    func tearDown() {
        guard !isTornDown else { return }
        isTornDown = true
        pressureObservations.removeAll()
        if session.isRunning { session.stopRunning() }
        frontOutput.setSampleBufferDelegate(nil, queue: nil)
        latestBuffer = nil
        session.beginConfiguration()
        for connection in session.connections { session.removeConnection(connection) }
        for output in session.outputs { session.removeOutput(output) }
        for input in session.inputs { session.removeInput(input) }
        session.commitConfiguration()
        rearPreview.session = nil
        frontPreview.session = nil
        for original in originalFormats {
            do {
                try original.device.lockForConfiguration()
                original.device.activeFormat = original.format
                original.device.activeVideoMinFrameDuration = original.min
                original.device.activeVideoMaxFrameDuration = original.max
                original.device.unlockForConfiguration()
            } catch {
                // A later single-camera session preset can negotiate its format again.
            }
        }
        originalFormats.removeAll()
    }
}

enum CameraConnectionConfiguration {
    static func apply(to connection: AVCaptureConnection, mirrored: Bool) {
        if connection.isVideoOrientationSupported { connection.videoOrientation = .portrait }
        if connection.isVideoMirroringSupported {
            // AVFoundation throws NSException if manual mirroring is changed while automatic is enabled.
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = mirrored
        }
    }
}
