import CoreGraphics

public struct StickerRenderPlacement: Equatable, Sendable {
    public let center: CGPoint
    public let sideLength: CGFloat
    public let rotation: CGFloat

    public init(center: CGPoint, sideLength: CGFloat, rotation: CGFloat) {
        self.center = center
        self.sideLength = sideLength
        self.rotation = rotation
    }
}

public enum StickerRenderTransform {
    public static func placement(for layer: StickerLayer, in canvasSize: CGSize) -> StickerRenderPlacement {
        let shortestSide = min(canvasSize.width, canvasSize.height)
        return StickerRenderPlacement(
            center: CGPoint(x: canvasSize.width * layer.center.x, y: canvasSize.height * layer.center.y),
            sideLength: shortestSide * layer.scale,
            rotation: layer.rotation
        )
    }
}
