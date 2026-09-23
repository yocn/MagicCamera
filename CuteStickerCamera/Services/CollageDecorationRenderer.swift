import UIKit

enum CollageDecorationRenderer {
    static func draw(_ decoration: CollageDecoration, in rect: CGRect, margin: CGFloat, context: CGContext) {
        guard margin > 0 else { return }
        switch decoration {
        case .none: break
        case .wave: drawWave(in: rect, margin: margin, context: context)
        case .rainbow: drawRainbow(in: rect, margin: margin, context: context)
        case .stars: drawStars(in: rect, margin: margin, context: context)
        }
    }

    /// 半圆骑在内容边缘上，一半压住照片形成扇贝花边。
    private static func drawWave(in rect: CGRect, margin: CGFloat, context: CGContext) {
        let radius = margin * 0.7
        let content = rect.insetBy(dx: margin, dy: margin)
        let path = UIBezierPath()

        var x = content.minX
        while x < content.maxX {
            path.append(UIBezierPath(ovalIn: CGRect(x: x, y: content.minY - radius, width: radius * 2, height: radius * 2)))
            path.append(UIBezierPath(ovalIn: CGRect(x: x, y: content.maxY - radius, width: radius * 2, height: radius * 2)))
            x += radius * 2
        }

        var y = content.minY
        while y < content.maxY {
            path.append(UIBezierPath(ovalIn: CGRect(x: content.minX - radius, y: y, width: radius * 2, height: radius * 2)))
            path.append(UIBezierPath(ovalIn: CGRect(x: content.maxX - radius, y: y, width: radius * 2, height: radius * 2)))
            y += radius * 2
        }

        context.saveGState()
        UIColor.white.setFill()
        path.fill()
        context.restoreGState()
    }

    private static func drawRainbow(in rect: CGRect, margin: CGFloat, context: CGContext) {
        let colors: [UIColor] = [
            UIColor(red: 1, green: 0.42, blue: 0.42, alpha: 1),
            UIColor(red: 1, green: 0.72, blue: 0.35, alpha: 1),
            UIColor(red: 1, green: 0.91, blue: 0.42, alpha: 1),
            UIColor(red: 0.53, green: 0.85, blue: 0.60, alpha: 1),
            UIColor(red: 0.47, green: 0.71, blue: 0.96, alpha: 1)
        ]
        let band = margin / CGFloat(colors.count)

        context.saveGState()
        for (index, color) in colors.enumerated() {
            let inset = band * CGFloat(index) + band / 2
            color.setStroke()
            let path = UIBezierPath(rect: rect.insetBy(dx: inset, dy: inset))
            path.lineWidth = band
            path.stroke()
        }
        context.restoreGState()
    }

    /// 星星骑在照片四角上，避免贴着画布边被裁掉。
    private static func drawStars(in rect: CGRect, margin: CGFloat, context: CGContext) {
        let radius = margin * 0.8
        let content = rect.insetBy(dx: margin, dy: margin)
        let centers = [
            CGPoint(x: content.minX, y: content.minY),
            CGPoint(x: content.maxX, y: content.minY),
            CGPoint(x: content.minX, y: content.maxY),
            CGPoint(x: content.maxX, y: content.maxY)
        ]

        context.saveGState()
        UIColor.white.setFill()
        for center in centers {
            starPath(center: center, radius: radius).fill()
        }
        context.restoreGState()
    }

    private static func starPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        for index in 0..<10 {
            let angle = CGFloat(index) * .pi / 5 - .pi / 2
            let length = index.isMultiple(of: 2) ? radius : radius * 0.45
            let point = CGPoint(
                x: center.x + cos(angle) * length,
                y: center.y + sin(angle) * length
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        return path
    }
}
