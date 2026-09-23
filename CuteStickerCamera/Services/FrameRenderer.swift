import UIKit

struct FrameDrawMetrics: Equatable {
    /// 源图等比缩放到成图的倍率。
    let scale: CGFloat
    /// 四角在成图上的边长。
    let cap: CGFloat
    /// 四角在源图上的边长。
    let sourceCap: CGFloat

    init(sourceSize: CGSize, destinationSize: CGSize, capInsets: FrameCapInsets) {
        let sourceCap = min(sourceSize.width, sourceSize.height) * capInsets.sourceRatio
        let destinationShortSide = min(destinationSize.width, destinationSize.height)
        // 四角合起来不能吃掉整条边，否则中缝被挤没。
        let cap = min(destinationShortSide * capInsets.destinationRatio, destinationShortSide / 2)

        self.sourceCap = sourceCap
        self.cap = cap
        self.scale = sourceCap > 0 ? cap / sourceCap : 1
    }
}

enum FrameRenderer {
    private static let cache = NSCache<NSString, UIImage>()

    /// 手写九宫格：四角等比缩放，四边按原始比例重复，中心不画。
    /// 不用 resizableImage，它在图片 scale 与绘制上下文 scale 不一致时会把整张图铺满。
    static func draw(_ style: FrameStyle, in rect: CGRect) {
        guard let assetName = style.assetName,
              let source = UIImage(named: assetName),
              let cgImage = source.cgImage,
              rect.width > 0, rect.height > 0 else { return }

        let sourceSize = CGSize(width: cgImage.width, height: cgImage.height)
        let metrics = FrameDrawMetrics(sourceSize: sourceSize, destinationSize: rect.size, capInsets: style.capInsets)
        let sourceCap = metrics.sourceCap
        let cap = metrics.cap
        guard cap > 0, sourceCap > 0 else { return }

        let sourceMidWidth = max(0, sourceSize.width - sourceCap * 2)
        let sourceMidHeight = max(0, sourceSize.height - sourceCap * 2)
        let midWidth = max(0, rect.width - cap * 2)
        let midHeight = max(0, rect.height - cap * 2)

        drawSlice(
            cgImage,
            CGRect(x: 0, y: 0, width: sourceCap, height: sourceCap),
            into: CGRect(x: rect.minX, y: rect.minY, width: cap, height: cap)
        )
        drawSlice(
            cgImage,
            CGRect(x: sourceSize.width - sourceCap, y: 0, width: sourceCap, height: sourceCap),
            into: CGRect(x: rect.maxX - cap, y: rect.minY, width: cap, height: cap)
        )
        drawSlice(
            cgImage,
            CGRect(x: 0, y: sourceSize.height - sourceCap, width: sourceCap, height: sourceCap),
            into: CGRect(x: rect.minX, y: rect.maxY - cap, width: cap, height: cap)
        )
        drawSlice(
            cgImage,
            CGRect(x: sourceSize.width - sourceCap, y: sourceSize.height - sourceCap, width: sourceCap, height: sourceCap),
            into: CGRect(x: rect.maxX - cap, y: rect.maxY - cap, width: cap, height: cap)
        )

        tileSlice(
            cgImage,
            CGRect(x: sourceCap, y: 0, width: sourceMidWidth, height: sourceCap),
            into: CGRect(x: rect.minX + cap, y: rect.minY, width: midWidth, height: cap),
            scale: metrics.scale
        )
        tileSlice(
            cgImage,
            CGRect(x: sourceCap, y: sourceSize.height - sourceCap, width: sourceMidWidth, height: sourceCap),
            into: CGRect(x: rect.minX + cap, y: rect.maxY - cap, width: midWidth, height: cap),
            scale: metrics.scale
        )
        tileSlice(
            cgImage,
            CGRect(x: 0, y: sourceCap, width: sourceCap, height: sourceMidHeight),
            into: CGRect(x: rect.minX, y: rect.minY + cap, width: cap, height: midHeight),
            scale: metrics.scale
        )
        tileSlice(
            cgImage,
            CGRect(x: sourceSize.width - sourceCap, y: sourceCap, width: sourceCap, height: sourceMidHeight),
            into: CGRect(x: rect.maxX - cap, y: rect.minY + cap, width: cap, height: midHeight),
            scale: metrics.scale
        )
    }

    static func image(for style: FrameStyle, size: CGSize) -> UIImage? {
        guard style.assetName != nil, size.width > 0, size.height > 0 else { return nil }

        let key = "\(style.rawValue)-\(Int(size.width))x\(Int(size.height))" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(style, in: CGRect(origin: .zero, size: size))
        }
        cache.setObject(rendered, forKey: key)
        return rendered
    }

    private static func drawSlice(_ image: CGImage, _ source: CGRect, into target: CGRect) {
        guard source.width >= 1, source.height >= 1, target.width > 0, target.height > 0,
              let slice = image.cropping(to: source.integral) else { return }
        UIImage(cgImage: slice, scale: 1, orientation: .up).draw(in: target)
    }

    private static func tileSlice(_ image: CGImage, _ source: CGRect, into target: CGRect, scale: CGFloat) {
        guard source.width >= 1, source.height >= 1, target.width > 0, target.height > 0,
              let cropped = image.cropping(to: source.integral),
              let context = UIGraphicsGetCurrentContext() else { return }

        let slice = UIImage(cgImage: cropped, scale: 1, orientation: .up)
        let unit = CGSize(width: max(1, source.width * scale), height: max(1, source.height * scale))

        context.saveGState()
        context.clip(to: target)
        var y = target.minY
        while y < target.maxY {
            var x = target.minX
            while x < target.maxX {
                slice.draw(in: CGRect(x: x, y: y, width: unit.width, height: unit.height))
                x += unit.width
            }
            y += unit.height
        }
        context.restoreGState()
    }
}
