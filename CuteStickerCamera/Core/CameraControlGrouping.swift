import Foundation

enum CameraControlAction: String, Identifiable {
    case stickers
    case frames
    case switchCamera
    case aspectRatio
    case sound
    case undo

    var id: String { rawValue }
}

enum CameraControlGrouping {
    static let quickActions: [CameraControlAction] = [.stickers, .frames]
    static let settingsActions: [CameraControlAction] = [.switchCamera, .aspectRatio, .sound, .undo]
}
