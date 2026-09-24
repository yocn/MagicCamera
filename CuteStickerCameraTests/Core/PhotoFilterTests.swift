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

final class PhotoFilterTests: XCTestCase {
    func testOriginalFilterIsIdentity() {
        let parameters = PhotoFilter.original.parameters

        XCTAssertEqual(parameters.red, 1, accuracy: 0.0001)
        XCTAssertEqual(parameters.green, 1, accuracy: 0.0001)
        XCTAssertEqual(parameters.blue, 1, accuracy: 0.0001)
        XCTAssertEqual(parameters.saturation, 1, accuracy: 0.0001)
        XCTAssertEqual(parameters.contrast, 1, accuracy: 0.0001)
        XCTAssertTrue(parameters.isIdentity)
    }

    func testMonoFilterRemovesAllSaturation() {
        XCTAssertEqual(PhotoFilter.mono.parameters.saturation, 0, accuracy: 0.0001)
        XCTAssertFalse(PhotoFilter.mono.parameters.isIdentity)
    }

    func testEveryFilterKeepsParametersInSaneRange() {
        for filter in PhotoFilter.allCases {
            let parameters = filter.parameters
            for channel in [parameters.red, parameters.green, parameters.blue] {
                XCTAssertTrue((0...1).contains(channel), "\(filter.title) 的通道乘数超出 0...1")
            }
            XCTAssertGreaterThanOrEqual(parameters.saturation, 0, "\(filter.title) 饱和度为负")
            XCTAssertGreaterThan(parameters.contrast, 0, "\(filter.title) 对比度必须为正")
        }
    }

    func testOnlyOriginalIsIdentity() {
        let identities = PhotoFilter.allCases.filter(\.parameters.isIdentity)

        XCTAssertEqual(identities, [.original], "除了原图，其它滤镜都该有实际效果")
    }

#if canImport(UIKit)
    func testMonoRendererFlattensColorChannels() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let source = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40), format: format).image { context in
            UIColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }

        let filtered = try XCTUnwrap(PhotoFilterRenderer.apply(.mono, to: source))
        let pixel = rgb(of: filtered, x: 20, y: 20)

        XCTAssertEqual(Int(pixel[0]), Int(pixel[1]), accuracy: 2, "黑白后红绿通道应当一致")
        XCTAssertEqual(Int(pixel[1]), Int(pixel[2]), accuracy: 2, "黑白后绿蓝通道应当一致")
    }

    func testOriginalRendererLeavesPixelsAlone() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let source = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40), format: format).image { context in
            UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }

        let filtered = try XCTUnwrap(PhotoFilterRenderer.apply(.original, to: source))

        let before = rgb(of: source, x: 20, y: 20)
        let after = rgb(of: filtered, x: 20, y: 20)
        for index in 0..<3 {
            XCTAssertEqual(Int(before[index]), Int(after[index]), accuracy: 2, "原图滤镜不该改变像素")
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
