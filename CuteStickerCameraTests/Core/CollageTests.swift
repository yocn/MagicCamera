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

final class CollageTests: XCTestCase {
    func testEveryCollageLayoutTilesTheWholeCanvasWithoutOverlap() {
        for layout in CollageLayout.allCases {
            let cells = layout.cells
            XCTAssertEqual(cells.count, layout.shotCount, "\(layout.title) 的格数与 shotCount 不一致")

            let area = cells.reduce(CGFloat.zero) { $0 + $1.width * $1.height }
            XCTAssertEqual(area, 1, accuracy: 0.0001, "\(layout.title) 没有铺满画布")

            let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
            for cell in cells {
                XCTAssertTrue(unit.contains(cell), "\(layout.title) 的格子越界")
            }

            for (index, cell) in cells.enumerated() {
                for other in cells.dropFirst(index + 1) {
                    XCTAssertFalse(cell.intersects(other), "\(layout.title) 的格子重叠")
                }
            }
        }
    }

    func testVerticalFourProducesTallCanvasWithFourThreeCells() {
        let layout = CollageLayout.verticalFour
        let canvas = layout.canvasSize(width: 1440)

        XCTAssertEqual(canvas.width, 1440, accuracy: 0.5)
        XCTAssertEqual(canvas.height, 4320, accuracy: 0.5)

        for cell in layout.cells {
            let ratio = (cell.width * canvas.width) / (cell.height * canvas.height)
            XCTAssertEqual(ratio, 4.0 / 3.0, accuracy: 0.001)
        }
    }

    func testSquareLayoutsKeepSquareCanvasAndFourGridIsDefault() {
        for layout in [CollageLayout.fourGrid, .twoOverOne, .oneOverTwo, .bigLeft, .nineGrid] {
            XCTAssertEqual(layout.aspectRatio, 1, accuracy: 0.0001, "\(layout.title) 画布不是正方形")
        }

        XCTAssertEqual(CollageLayout.fourGrid.shotCount, 4)
        XCTAssertEqual(CollageLayout.nineGrid.shotCount, 9)
        XCTAssertEqual(CollageLayout.twoRows.shotCount, 2)
    }

    func testCollageStyleMetricsStayWithinSafeRanges() {
        for style in CollageStyle.allCases {
            let metrics = style.metrics
            XCTAssertTrue((0...0.1).contains(metrics.outerMargin), "\(style.title) 外边距超范围")
            XCTAssertTrue((0...0.05).contains(metrics.gutter), "\(style.title) 格缝超范围")
            XCTAssertTrue((0...0.2).contains(metrics.cornerRadius), "\(style.title) 圆角超范围")
        }
    }

    func testPlainCollageStyleDrawsNothingExtra() {
        let metrics = CollageStyle.plain.metrics

        XCTAssertEqual(metrics.outerMargin, 0, accuracy: 0.0001)
        XCTAssertEqual(metrics.gutter, 0, accuracy: 0.0001)
        XCTAssertEqual(metrics.cornerRadius, 0, accuracy: 0.0001)
        XCTAssertEqual(metrics.decoration, .none)
        XCTAssertEqual(metrics.background.alpha, 0, accuracy: 0.0001)
    }

    func testDecoratedCollageStylesReserveMarginForTheirOrnament() {
        for style in [CollageStyle.wave, .rainbow, .stars] {
            XCTAssertNotEqual(style.metrics.decoration, .none, "\(style.title) 缺少装饰")
            XCTAssertGreaterThan(style.metrics.outerMargin, 0, "\(style.title) 没有给装饰留出外边距")
        }
    }

    func testCollageSessionAdvancesUntilTheLayoutIsFull() {
        var session = CollageSession(layout: .fourGrid, style: .classicWhite, mode: .burstThree)

        XCTAssertEqual(session.remaining, 4)
        XCTAssertEqual(session.currentIndex, 0)
        XCTAssertFalse(session.isComplete)

        session.advance()
        XCTAssertEqual(session.currentIndex, 1)
        XCTAssertEqual(session.remaining, 3)

        for _ in 0..<3 { session.advance() }
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.remaining, 0)
    }

    func testCompletedCollageSessionIgnoresExtraShots() {
        var session = CollageSession(layout: .twoRows, style: .plain, mode: .manual)

        session.advance()
        session.advance()
        session.advance()

        XCTAssertEqual(session.capturedCount, 2)
        XCTAssertTrue(session.isComplete)
    }

    func testBurstModesCarryCountdownAndManualDoesNot() {
        XCTAssertEqual(CollageCaptureMode.burstThree.countdownSeconds, 3)
        XCTAssertEqual(CollageCaptureMode.burstFive.countdownSeconds, 5)
        XCTAssertNil(CollageCaptureMode.manual.countdownSeconds)

        XCTAssertTrue(CollageCaptureMode.burstThree.isBurst)
        XCTAssertTrue(CollageCaptureMode.burstFive.isBurst)
        XCTAssertFalse(CollageCaptureMode.manual.isBurst)

        XCTAssertEqual(CollageCaptureTiming.shotInterval, 0.8, accuracy: 0.0001)
    }

    func testCollageOverlayKeepsItsLayoutAspectRatioAndStaysInBounds() {
        let overlay = CollageOverlayLayout()
        let canvas = CGSize(width: 400, height: 800)

        let square = overlay.rect(in: canvas, aspectRatio: CollageLayout.fourGrid.aspectRatio)
        XCTAssertEqual(square.width, 112, accuracy: 0.0001)
        XCTAssertEqual(square.height, 112, accuracy: 0.0001)

        let tall = overlay.rect(in: canvas, aspectRatio: CollageLayout.verticalFour.aspectRatio)
        XCTAssertEqual(tall.width, 112, accuracy: 0.0001)
        XCTAssertEqual(tall.height, 336, accuracy: 0.0001)

        let dragged = overlay.normalizedCenter(
            afterDragging: CGSize(width: 1000, height: 1000),
            in: canvas,
            aspectRatio: CollageLayout.fourGrid.aspectRatio
        )
        let moved = CollageOverlayLayout(center: dragged)
            .rect(in: canvas, aspectRatio: CollageLayout.fourGrid.aspectRatio)
        XCTAssertEqual(moved.maxX, canvas.width, accuracy: 0.0001)
        XCTAssertEqual(moved.maxY, canvas.height, accuracy: 0.0001)
    }

    func testCollageOverlayDefaultsToTheTopLeadingCorner() {
        let rect = CollageOverlayLayout().rect(in: CGSize(width: 400, height: 800), aspectRatio: 1)

        XCTAssertEqual(rect.minX, 16, accuracy: 0.0001)
        XCTAssertEqual(rect.minY, 96, accuracy: 0.0001)
        XCTAssertEqual(CollageOverlayLayout().rect(in: .zero, aspectRatio: 1), .zero)
    }

#if canImport(UIKit)
    func testCollageComposerFillsEveryCellWithItsOwnShot() throws {
        let colors: [UIColor] = [.red, .green, .blue, .yellow]
        let shots = colors.map { solidImage($0, CGSize(width: 300, height: 300)) }

        let result = try CollageComposer().compose(shots: shots, layout: .fourGrid, style: .plain)

        let canvas = CollageLayout.fourGrid.canvasSize()
        XCTAssertEqual(result.size.width, canvas.width, accuracy: 1)
        XCTAssertEqual(result.size.height, canvas.height, accuracy: 1)

        let expected: [[UInt8]] = [[255, 0, 0], [0, 255, 0], [0, 0, 255], [255, 255, 0]]
        for (index, cell) in CollageLayout.fourGrid.cells.enumerated() {
            let x = cell.midX * result.size.width
            let y = cell.midY * result.size.height
            XCTAssertEqual(rgb(of: result, x: x, y: y), expected[index], "第 \(index + 1) 格取到的颜色不对")
        }
    }

    func testCollageComposerRejectsWrongShotCount() {
        let shots = [solidImage(.red, CGSize(width: 100, height: 100))]

        XCTAssertThrowsError(try CollageComposer().compose(shots: shots, layout: .fourGrid, style: .plain))
    }

    func testClassicWhiteStyleLeavesWhiteMarginAroundTheGrid() throws {
        let shots = (0..<4).map { _ in solidImage(.black, CGSize(width: 300, height: 300)) }

        let result = try CollageComposer().compose(shots: shots, layout: .fourGrid, style: .classicWhite)

        XCTAssertEqual(rgb(of: result, x: 4, y: 4), [255, 255, 255], "外边距没有留白")
        let center = CGPoint(x: result.size.width / 2, y: result.size.height / 2)
        XCTAssertEqual(rgb(of: result, x: center.x, y: center.y), [255, 255, 255], "格缝没有留白")
    }

    private func solidImage(_ color: UIColor, _ size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func rgb(of image: UIImage, x: CGFloat, y: CGFloat) -> [UInt8] {
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
            image.draw(at: CGPoint(x: -x, y: -y))
            UIGraphicsPopContext()
        }
        return Array(bytes.prefix(3))
    }
#endif
}
