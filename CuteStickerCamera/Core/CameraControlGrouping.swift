import Foundation

enum CameraControlAction: String, Identifiable {
    case stickers
    case frames
    case collage
    case doodle
    case switchCamera
    case aspectRatio
    case sound
    case timer
    case pictureInPicture

    var id: String { rawValue }
}
enum CameraControlGrouping {
    static let quickActions: [CameraControlAction] = [.stickers, .frames, .collage, .doodle]
    static let settingsActions: [CameraControlAction] = [.aspectRatio, .sound, .timer]
    /// Left-to-right visual order; the last option sits nearest the settings button.
    static let expandedSettingsActions: [CameraControlAction] = [.pictureInPicture, .sound, .timer, .aspectRatio]
    static let bottomTrailingAction: CameraControlAction = .switchCamera

    static func settingsActions(supportsPictureInPicture: Bool) -> [CameraControlAction] {
        settingsActions + (supportsPictureInPicture ? [.pictureInPicture] : [])
    }
}
