import UIKit

enum PhotoComposerError: LocalizedError {
    case unableToCreateImage

    var errorDescription: String? { "照片合成失败，请再试一次。" }
}

struct PhotoComposer {
    func compose(image: UIImage, previewSize: CGSize, layers: [StickerLayer]) throws -> UIImage {
        guard let normalized = image.normalized(), previewSize.width > 0, previewSize.height > 0 else {
            throw PhotoComposerError.unableToCreateImage
        }
        let canvas = normalized.centerCropped(toAspect: previewSize.width / previewSize.height)
        let renderer = UIGraphicsImageRenderer(size: canvas.size)
        return renderer.image { context in
            canvas.draw(in: CGRect(origin: .zero, size: canvas.size))
            for layer in layers {
                guard let sticker = UIImage(named: layer.assetName) else { continue }
                let placement = StickerRenderTransform.placement(for: layer, in: canvas.size)
                let rect = CGRect(
                    x: placement.center.x - placement.sideLength / 2,
                    y: placement.center.y - placement.sideLength / 2,
                    width: placement.sideLength,
                    height: placement.sideLength
                )
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: placement.center.x, y: placement.center.y)
                context.cgContext.rotate(by: placement.rotation)
                sticker.draw(in: rect.offsetBy(dx: -placement.center.x, dy: -placement.center.y))
                context.cgContext.restoreGState()
            }
        }
    }
}

private extension UIImage {
    func normalized() -> UIImage? {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }

    func centerCropped(toAspect aspect: CGFloat) -> UIImage {
        let currentAspect = size.width / size.height
        let cropSize: CGSize
        if currentAspect > aspect {
            cropSize = CGSize(width: size.height * aspect, height: size.height)
        } else {
            cropSize = CGSize(width: size.width, height: size.width / aspect)
        }
        let crop = CGRect(
            x: (size.width - cropSize.width) / 2,
            y: (size.height - cropSize.height) / 2,
            width: cropSize.width,
            height: cropSize.height
        )
        let renderer = UIGraphicsImageRenderer(size: cropSize)
        return renderer.image { _ in draw(in: CGRect(origin: crop.origin.negated, size: size)) }
    }
}

private extension CGPoint {
    var negated: CGPoint { CGPoint(x: -x, y: -y) }
}
