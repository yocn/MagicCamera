import UIKit

enum PhotoComposerError: LocalizedError {
    case unableToCreateImage

    var errorDescription: String? { "照片合成失败，请再试一次。" }
}

struct PhotoComposer {
    func compose(image: UIImage, previewSize: CGSize, layers: [StickerLayer], frameStyle: FrameStyle = .none) throws -> UIImage {
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
            FrameRenderer.draw(style: frameStyle, in: canvas.size)
        }
    }
}

private enum FrameRenderer {
    static func draw(style: FrameStyle, in size: CGSize) {
        guard style != .none else { return }
        let inset: CGFloat = 18
        let rect = CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2)
        let cornerRadius: CGFloat = 34

        switch style {
        case .heart:
            UIColor.systemPink.withAlphaComponent(0.9).setStroke()
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).stroke(with: .normal, alpha: 1)
            drawSymbols(["💗", "🩷", "💞", "💖"], in: size)
        case .rainbow:
            let colors: [UIColor] = [.systemPink, .systemOrange, .systemYellow, .systemMint, .systemCyan, .systemPurple]
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.lineWidth = 18
            for (index, color) in colors.enumerated() {
                color.setStroke()
                path.stroke(with: .normal, alpha: CGFloat(index + 1) / CGFloat(colors.count))
            }
            drawText("☁️  🌈  ☁️", at: CGPoint(x: size.width / 2, y: 43), size: 30)
            drawText("✨", at: CGPoint(x: 48, y: size.height - 46), size: 24)
            drawText("✨", at: CGPoint(x: size.width - 48, y: size.height - 46), size: 24)
        case .flower:
            UIColor.systemYellow.setStroke()
            let outer = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            outer.lineWidth = 16
            outer.stroke()
            UIColor.systemPink.withAlphaComponent(0.72).setStroke()
            let inner = UIBezierPath(roundedRect: rect.insetBy(dx: 10, dy: 10), cornerRadius: cornerRadius)
            inner.lineWidth = 5
            inner.stroke()
            drawSymbols(["🌸", "🌼", "🌷", "🌺"], in: size)
        case .stars:
            UIColor.systemPurple.withAlphaComponent(0.88).setStroke()
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.lineWidth = 18
            path.stroke()
            drawSymbols(["🌟", "⭐️", "💫", "✨"], in: size)
            drawText("⋆｡°✩", at: CGPoint(x: size.width / 2, y: 45), size: 26)
        case .none:
            break
        }
    }

    private static func drawSymbols(_ symbols: [String], in size: CGSize) {
        drawText(symbols[0], at: CGPoint(x: 45, y: 45), size: 34)
        drawText(symbols[1], at: CGPoint(x: size.width - 45, y: 45), size: 34)
        drawText(symbols[2], at: CGPoint(x: 45, y: size.height - 45), size: 34)
        drawText(symbols[3], at: CGPoint(x: size.width - 45, y: size.height - 45), size: 34)
    }

    private static func drawText(_ text: String, at point: CGPoint, size: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: size)]
        let textSize = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(at: CGPoint(x: point.x - textSize.width / 2, y: point.y - textSize.height / 2), withAttributes: attributes)
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
