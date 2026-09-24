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

final class DoodleTests: XCTestCase {
    func testPaletteOffersEightDistinctColors() {
        XCTAssertEqual(DoodlePalette.all.count, 8)

        let ids = Set(DoodlePalette.all.map(\.id))
        XCTAssertEqual(ids.count, 8, "调色板里有重复的颜色 id")

        let titles = Set(DoodlePalette.all.map(\.title))
        XCTAssertEqual(titles.count, 8, "调色板里有重复的颜色名")
    }

    func testBrushWidthsIncreaseStrictly() {
        let sizes = DoodleBrushWidth.allCases.map(\.pointSize)

        XCTAssertEqual(sizes, sizes.sorted(), "粗细档位没有按从细到粗排列")
        XCTAssertEqual(Set(sizes).count, sizes.count, "存在两档粗细一样")
        XCTAssertEqual(DoodleBrushWidth.thin.pointSize, 6, accuracy: 0.0001)
        XCTAssertEqual(DoodleBrushWidth.medium.pointSize, 14, accuracy: 0.0001)
        XCTAssertEqual(DoodleBrushWidth.thick.pointSize, 26, accuracy: 0.0001)
    }

    func testTogglingEraserKeepsPenSettings() {
        var state = DoodleToolState()
        state.color = DoodlePalette.all[4]
        state.width = .thick

        state.isErasing = true
        XCTAssertEqual(state.color, DoodlePalette.all[4], "切到橡皮时不该丢掉颜色")
        XCTAssertEqual(state.width, .thick, "切到橡皮时不该丢掉粗细")

        state.isErasing = false
        XCTAssertEqual(state.color, DoodlePalette.all[4])
        XCTAssertEqual(state.width, .thick)
    }

    func testDefaultToolIsMediumBubblePink() {
        let state = DoodleToolState()

        XCTAssertEqual(state.color.id, "bubble")
        XCTAssertEqual(state.width, .medium)
        XCTAssertFalse(state.isErasing)
    }

#if canImport(UIKit)
    func testComposerDrawsDoodleOverTheBasePhoto() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        func solid(_ color: UIColor, _ size: CGSize) -> UIImage {
            UIGraphicsImageRenderer(size: size, format: format).image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }

        let preview = CGSize(width: 400, height: 800)
        let result = try PhotoComposer().compose(
            image: solid(.blue, preview),
            previewSize: preview,
            layers: [],
            doodle: solid(.red, preview)
        )

        var bytes = [UInt8](repeating: 0, count: 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            UIGraphicsPushContext(context)
            result.draw(at: CGPoint(x: -200, y: -400))
            UIGraphicsPopContext()
        }

        XCTAssertEqual(Array(bytes.prefix(3)), [255, 0, 0], "涂鸦没有盖在底图上")
    }
#endif
}
