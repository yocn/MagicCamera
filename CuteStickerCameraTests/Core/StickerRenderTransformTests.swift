import CoreGraphics
import XCTest
#if canImport(CuteStickerCamera)
@testable import CuteStickerCamera
#else
@testable import CuteStickerCore
#endif

final class StickerRenderTransformTests: XCTestCase {
    func testMapsNormalizedCenterToPixelCanvas() {
        let layer = StickerLayer(
            assetName: "bunny",
            center: CGPoint(x: 0.25, y: 0.75),
            scale: 0.2,
            rotation: .pi / 4
        )

        let placement = StickerRenderTransform.placement(for: layer, in: CGSize(width: 1_000, height: 2_000))

        XCTAssertEqual(placement.center, CGPoint(x: 250, y: 1_500))
        XCTAssertEqual(placement.sideLength, 200)
        XCTAssertEqual(placement.rotation, .pi / 4, accuracy: 0.0001)
    }
}
