import CoreGraphics
import XCTest
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CuteStickerCamera)
@testable import CuteStickerCamera
#else
@testable import CuteStickerCore
#endif

final class StickerRenderTransformTests: XCTestCase {
#if canImport(UIKit)
    func testPictureInPictureLetsEmptyTouchesPassButKeepsOverlappingStickersEditable() {
        let view = StickerCanvasUIKitView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        view.passthroughRect = CGRect(x: 250, y: 20, width: 120, height: 120)
        XCTAssertFalse(view.point(inside: CGPoint(x: 310, y: 80), with: nil))
        let layer = StickerLayer(assetName: "kitten", center: CGPoint(x: 0.775, y: 0.1), scale: 0.15, rotation: 0)
        view.sync(layers: [layer], selectedLayerID: layer.id)
        XCTAssertTrue(view.point(inside: CGPoint(x: 310, y: 80), with: nil))
        XCTAssertTrue(view.point(inside: CGPoint(x: 50, y: 400), with: nil))
    }

    func testPictureInPictureCompositionIncludesFrontImageAndRoundedCorners() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        func solid(_ color: UIColor, _ size: CGSize) -> UIImage {
            UIGraphicsImageRenderer(size: size, format: format).image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }
        let result = try PhotoComposer().compose(
            image: solid(.blue, CGSize(width: 400, height: 800)),
            previewSize: CGSize(width: 400, height: 800), layers: [],
            pictureInPicture: PictureInPicturePhoto(image: solid(.red, CGSize(width: 200, height: 100)), layout: PictureInPictureLayout())
        )
        func rgb(_ x: CGFloat, _ y: CGFloat) -> [UInt8] {
            var bytes = [UInt8](repeating: 0, count: 4)
            bytes.withUnsafeMutableBytes { buffer in
                let ctx = CGContext(data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                UIGraphicsPushContext(ctx)
                result.draw(at: CGPoint(x: -x, y: -y))
                UIGraphicsPopContext()
            }
            return Array(bytes.prefix(3))
        }
        XCTAssertEqual(rgb(328, 84), [255, 0, 0])
        XCTAssertEqual(rgb(100, 400), [0, 0, 255])
        XCTAssertEqual(rgb(268, 24), [0, 0, 255])
    }
#endif
    func testPictureInPictureKeepsSquareInBoundsAndScalesWithPhoto() {
        let layout = PictureInPictureLayout()
        XCTAssertEqual(layout.rect(in: CGSize(width: 400, height: 800)), CGRect(x: 268, y: 24, width: 120, height: 120))
        XCTAssertEqual(layout.rect(in: CGSize(width: 800, height: 1600)), CGRect(x: 536, y: 48, width: 240, height: 240))
        XCTAssertEqual(layout.normalizedCenter(afterDragging: CGSize(width: 1000, height: -1000), in: CGSize(width: 400, height: 800)), CGPoint(x: 0.85, y: 0.075))
        XCTAssertEqual(layout.rect(in: .zero), .zero)
    }

    func testDualCameraBudgetRejectsUnsustainableConfigurations() {
        XCTAssertTrue(MultiCameraPolicy.canRun(hardwareCost: 0.8, pressureCost: 0.7))
        XCTAssertFalse(MultiCameraPolicy.canRun(hardwareCost: 1.01, pressureCost: 0.7))
        XCTAssertFalse(MultiCameraPolicy.canRun(hardwareCost: 0.8, pressureCost: 1.01))
        XCTAssertFalse(MultiCameraPolicy.canRun(hardwareCost: .nan, pressureCost: 0.7))
    }

    func testThreeQuarterPreviewCentersAThreeByFourCanvasInsideTallScreen() {
        let rect = CameraAspectRatio.threeQuarter.contentRect(in: CGSize(width: 400, height: 800))

        XCTAssertEqual(rect.origin.x, 0, accuracy: 0.0001)
        XCTAssertEqual(rect.origin.y, 133.3333, accuracy: 0.0001)
        XCTAssertEqual(rect.width, 400, accuracy: 0.0001)
        XCTAssertEqual(rect.height, 533.3333, accuracy: 0.0001)
    }

    func testFullScreenPreviewUsesEveryPixelOfItsContainer() {
        XCTAssertEqual(
            CameraAspectRatio.fullScreen.contentRect(in: CGSize(width: 400, height: 800)),
            CGRect(x: 0, y: 0, width: 400, height: 800)
        )
    }

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
