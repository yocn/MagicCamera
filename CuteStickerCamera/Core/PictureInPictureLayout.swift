import CoreGraphics

struct PictureInPictureLayout: Equatable {
    static let sideFraction: CGFloat = 0.30
    static let defaultCenter = CGPoint(x: 0.81, y: 0.18)

    var center: CGPoint

    init(center: CGPoint = Self.defaultCenter) {
        self.center = center
    }

    func rect(in canvas: CGSize) -> CGRect {
        let side = min(canvas.width, canvas.height) * Self.sideFraction
        return CGRect(
            x: center.x * canvas.width - side / 2,
            y: center.y * canvas.height - side / 2,
            width: side,
            height: side
        )
    }

    func normalizedCenter(afterDragging translation: CGSize, in canvas: CGSize) -> CGPoint {
        guard canvas.width > 0, canvas.height > 0 else { return center }
        let side = min(canvas.width, canvas.height) * Self.sideFraction
        let minimumX = side / canvas.width / 2
        let minimumY = side / canvas.height / 2
        return CGPoint(
            x: min(1 - minimumX, max(minimumX, center.x + translation.width / canvas.width)),
            y: min(1 - minimumY, max(minimumY, center.y + translation.height / canvas.height))
        )
    }
}
