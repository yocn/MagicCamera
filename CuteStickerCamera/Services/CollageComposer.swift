import UIKit

enum CollageComposerError: LocalizedError {
    case shotCountMismatch

    var errorDescription: String? { "大头贴合成失败，请再试一次。" }
}

struct CollageComposer {
    func compose(shots: [UIImage], layout: CollageLayout, style: CollageStyle) throws -> UIImage {
        guard shots.count == layout.shotCount else { throw CollageComposerError.shotCountMismatch }
        return render(
            shots: shots,
            layout: layout,
            style: style,
            width: CollageLayout.canvasWidth,
            highlightIndex: nil,
            fillsEmptyCells: false
        )
    }

    /// 未拍满时也能出图，空格子用半透明白占位，可标出当前要拍的格子。
    func preview(
        shots: [UIImage] = [],
        layout: CollageLayout,
        style: CollageStyle,
        width: CGFloat,
        highlightIndex: Int? = nil
    ) -> UIImage {
        render(
            shots: shots,
            layout: layout,
            style: style,
            width: width,
            highlightIndex: highlightIndex,
            fillsEmptyCells: true
        )
    }

    private func render(
        shots: [UIImage],
        layout: CollageLayout,
        style: CollageStyle,
        width: CGFloat,
        highlightIndex: Int?,
        fillsEmptyCells: Bool
    ) -> UIImage {
        let canvas = layout.canvasSize(width: width)
        let metrics = style.metrics
        let margin = canvas.width * metrics.outerMargin
        let gutter = canvas.width * metrics.gutter
        let content = CGRect(origin: .zero, size: canvas).insetBy(dx: margin, dy: margin)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)

        return renderer.image { context in
            if metrics.background.alpha > 0 {
                metrics.background.uiColor.setFill()
                context.fill(CGRect(origin: .zero, size: canvas))
            }

            for (index, cell) in layout.cells.enumerated() {
                let frame = CGRect(
                    x: content.minX + cell.minX * content.width + gutter / 2,
                    y: content.minY + cell.minY * content.height + gutter / 2,
                    width: cell.width * content.width - gutter,
                    height: cell.height * content.height - gutter
                )
                guard frame.width > 0, frame.height > 0 else { continue }

                let radius = min(frame.width, frame.height) * metrics.cornerRadius
                let clip = UIBezierPath(roundedRect: frame, cornerRadius: radius)

                context.cgContext.saveGState()
                clip.addClip()
                if index < shots.count {
                    shots[index]
                        .centerCropped(toAspect: frame.width / frame.height)
                        .draw(in: frame)
                } else if fillsEmptyCells {
                    // 花边底色多为白色，占位必须用灰色才看得出格子分隔。
                    UIColor(white: 0.75, alpha: 0.92).setFill()
                    UIBezierPath(rect: frame).fill()
                }
                context.cgContext.restoreGState()

                if index == highlightIndex {
                    UIColor.systemPink.setStroke()
                    clip.lineWidth = max(2, frame.width * 0.035)
                    clip.stroke()
                }
            }

            CollageDecorationRenderer.draw(
                metrics.decoration,
                in: CGRect(origin: .zero, size: canvas),
                margin: margin,
                context: context.cgContext
            )
        }
    }
}

extension CollageBackground {
    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: alpha) }
}
