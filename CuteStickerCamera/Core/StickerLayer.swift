import CoreGraphics
import Foundation

public struct StickerLayer: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let assetName: String
    public var center: CGPoint
    public var scale: CGFloat
    public var rotation: CGFloat

    public init(
        id: UUID = UUID(),
        assetName: String,
        center: CGPoint = CGPoint(x: 0.5, y: 0.5),
        scale: CGFloat = 0.24,
        rotation: CGFloat = 0
    ) {
        self.id = id
        self.assetName = assetName
        self.center = center
        self.scale = scale
        self.rotation = rotation
    }
}

extension StickerLayer {
    func moved(by translation: CGSize, in previewSize: CGSize) -> StickerLayer {
        var moved = self
        moved.center = CGPoint(
            x: min(1, max(0, center.x + translation.width / previewSize.width)),
            y: min(1, max(0, center.y + translation.height / previewSize.height))
        )
        return moved
    }

    func rotated(by angle: CGFloat) -> StickerLayer {
        var rotated = self
        rotated.rotation += angle
        return rotated
    }

    func scaled(by factor: CGFloat) -> StickerLayer {
        var scaled = self
        scaled.scale = min(0.8, max(0.08, scale * factor))
        return scaled
    }
}

struct StickerHandlePositions {
    let close: CGPoint
    let rotate: CGPoint
    let scale: CGPoint
}

struct StickerHandleLayout {
    let contentRect: CGRect

    func positions(transform: CGAffineTransform) -> StickerHandlePositions {
        StickerHandlePositions(
            close: transformed(contentRect.topRight, by: transform),
            rotate: transformed(contentRect.bottomLeft, by: transform),
            scale: transformed(contentRect.bottomRight, by: transform)
        )
    }

    private func transformed(_ point: CGPoint, by transform: CGAffineTransform) -> CGPoint {
        let center = CGPoint(x: contentRect.midX, y: contentRect.midY)
        let offset = CGPoint(x: point.x - center.x, y: point.y - center.y).applying(transform)
        return CGPoint(x: center.x + offset.x, y: center.y + offset.y)
    }
}

private extension CGRect {
    var topRight: CGPoint { CGPoint(x: maxX, y: minY) }
    var bottomLeft: CGPoint { CGPoint(x: minX, y: maxY) }
    var bottomRight: CGPoint { CGPoint(x: maxX, y: maxY) }
}
