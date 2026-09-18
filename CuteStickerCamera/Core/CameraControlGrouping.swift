import Foundation

enum CameraControlAction: String, Identifiable {
    case stickers
    case frames
    case switchCamera
    case aspectRatio
    case sound
    case pictureInPicture

    var id: String { rawValue }
}
enum CameraControlGrouping {
    static let quickActions: [CameraControlAction] = [.stickers, .frames]
    static let settingsActions: [CameraControlAction] = [.aspectRatio, .sound]
    /// Left-to-right visual order; the last option sits nearest the settings button.
    static let expandedSettingsActions: [CameraControlAction] = [.pictureInPicture, .sound, .aspectRatio]
    static let bottomTrailingAction: CameraControlAction = .switchCamera

    static func settingsActions(supportsPictureInPicture: Bool) -> [CameraControlAction] {
        settingsActions + (supportsPictureInPicture ? [.pictureInPicture] : [])
    }
}
