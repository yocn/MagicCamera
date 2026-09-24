import UIKit

enum PhotoComposerError: LocalizedError {
    case unableToCreateImage

    var errorDescription: String? { "照片合成失败，请再试一次。" }
}
struct PictureInPicturePhoto {
    let image: UIImage
    let layout: PictureInPictureLayout
}

struct PhotoComposer {
    func compose(
        image: UIImage,
        previewSize: CGSize,
        layers: [StickerLayer],
        frameStyle: FrameStyle = .none,
        pictureInPicture: PictureInPicturePhoto? = nil,
        doodle: UIImage? = nil,
        filter: PhotoFilter = .original
    ) throws -> UIImage {
        guard let normalized = image.normalized(), previewSize.width > 0, previewSize.height > 0 else {
            throw PhotoComposerError.unableToCreateImage
        }
        let canvas = normalized.centerCropped(toAspect: previewSize.width / previewSize.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: canvas.size, format: format)
        let composed = renderer.image { context in
            canvas.draw(in: CGRect(origin: .zero, size: canvas.size))
            if let pip = pictureInPicture, let front = pip.image.normalized() {
                let rect = pip.layout.rect(in: canvas.size)
                let border = rect.width * 0.015
                context.cgContext.saveGState()
                let clip = UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.14)
                clip.addClip()
                front.centerCropped(toAspect: 1).draw(in: rect)
                UIColor.white.setStroke()
                let outline = UIBezierPath(roundedRect: rect.insetBy(dx: border / 2, dy: border / 2), cornerRadius: rect.width * 0.14 - border / 2)
                outline.lineWidth = border
                outline.stroke()
                context.cgContext.restoreGState()
            }
            for layer in layers {
                guard let sticker = StickerImageProvider.image(named: layer.assetName) else { continue }
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
            // 涂鸦压在贴纸上，但要留在边框下面。
            if let doodle {
                doodle.draw(in: CGRect(origin: .zero, size: canvas.size))
            }
            FrameRenderer.draw(frameStyle, in: CGRect(origin: .zero, size: canvas.size))
        }

        // 滤镜是最后一层，贴纸、涂鸦、边框跟着一起调色。
        return PhotoFilterRenderer.apply(filter, to: composed) ?? composed
    }
}
