import Foundation

enum CameraScreenChrome {
    static let showsAppTitle = false

    /// Places the full 48-point control below the Dynamic Island/status bar.
    static func topPadding(safeAreaTop: CGFloat) -> CGFloat {
        max(56, safeAreaTop + 56)
    }
}
