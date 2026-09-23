import CoreGraphics
import Foundation

/// 大头贴预览浮层的位置，宽度取画幅短边比例，高度随排版比例变化。
public struct CollageOverlayLayout: Equatable, Sendable {
    public static let widthRatio: CGFloat = 0.28
    public static let margin: CGFloat = 16
    /// 默认位置要让开状态栏和灵动岛。
    public static let topMargin: CGFloat = 96

    public var center: CGPoint?

    public init(center: CGPoint? = nil) {
        self.center = center
    }

    public func size(in canvas: CGSize, aspectRatio: CGFloat) -> CGSize {
        let width = min(canvas.width, canvas.height) * Self.widthRatio
        return CGSize(width: width, height: width / aspectRatio)
    }

    public func rect(in canvas: CGSize, aspectRatio: CGFloat) -> CGRect {
        guard canvas.width > 0, canvas.height > 0, aspectRatio > 0 else { return .zero }
        let size = size(in: canvas, aspectRatio: aspectRatio)
        let initial = center ?? CGPoint(
            x: (Self.margin + size.width / 2) / canvas.width,
            y: (Self.topMargin + size.height / 2) / canvas.height
        )
        let x = min(canvas.width - size.width / 2, max(size.width / 2, initial.x * canvas.width))
        let y = min(canvas.height - size.height / 2, max(size.height / 2, initial.y * canvas.height))
        return CGRect(x: x - size.width / 2, y: y - size.height / 2, width: size.width, height: size.height)
    }

    public func normalizedCenter(afterDragging translation: CGSize, in canvas: CGSize, aspectRatio: CGFloat) -> CGPoint {
        guard canvas.width > 0, canvas.height > 0 else { return CGPoint(x: 0.5, y: 0.5) }
        let current = rect(in: canvas, aspectRatio: aspectRatio)
        let next = CollageOverlayLayout(center: CGPoint(
            x: (current.midX + translation.width) / canvas.width,
            y: (current.midY + translation.height) / canvas.height
        )).rect(in: canvas, aspectRatio: aspectRatio)
        return CGPoint(x: next.midX / canvas.width, y: next.midY / canvas.height)
    }
}
