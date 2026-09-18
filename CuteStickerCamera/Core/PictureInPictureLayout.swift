import Foundation

struct PictureInPictureLayout: Equatable {
    var center: CGPoint?

    init(center: CGPoint? = nil) { self.center = center }

    func rect(in canvas: CGSize) -> CGRect {
        guard canvas.width > 0, canvas.height > 0 else { return .zero }
        let shortSide = min(canvas.width, canvas.height)
        let side = shortSide * 0.30
        let initial = center ?? CGPoint(
            x: (canvas.width - side / 2 - shortSide * 0.03) / canvas.width,
            y: (side / 2 + shortSide * 0.06) / canvas.height
        )
        let x = min(canvas.width - side / 2, max(side / 2, initial.x * canvas.width))
        let y = min(canvas.height - side / 2, max(side / 2, initial.y * canvas.height))
        return CGRect(x: x - side / 2, y: y - side / 2, width: side, height: side)
    }

    func normalizedCenter(afterDragging translation: CGSize, in canvas: CGSize) -> CGPoint {
        guard canvas.width > 0, canvas.height > 0 else { return CGPoint(x: 0.5, y: 0.5) }
        let current = rect(in: canvas)
        let next = PictureInPictureLayout(center: CGPoint(
            x: (current.midX + translation.width) / canvas.width,
            y: (current.midY + translation.height) / canvas.height
        )).rect(in: canvas)
        return CGPoint(x: next.midX / canvas.width, y: next.midY / canvas.height)
    }
}

enum MultiCameraPolicy {
    static func canRun(hardwareCost: Float, pressureCost: Float) -> Bool {
        hardwareCost.isFinite && pressureCost.isFinite &&
        (0...1).contains(hardwareCost) && (0...1).contains(pressureCost)
    }
}
