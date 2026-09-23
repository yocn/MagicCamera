import UIKit

extension UIImage {
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

extension CGPoint {
    var negated: CGPoint { CGPoint(x: -x, y: -y) }
}
