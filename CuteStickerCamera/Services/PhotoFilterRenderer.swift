import CoreImage
import UIKit

enum PhotoFilterRenderer {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// 成片侧的滤镜：CIColorMatrix 做逐通道乘法，CIColorControls 调饱和度与对比度，
    /// 与预览那边的 SwiftUI modifier 是同一组运算。
    static func apply(_ filter: PhotoFilter, to image: UIImage) -> UIImage? {
        let parameters = filter.parameters
        guard !parameters.isIdentity else { return image }
        guard let input = CIImage(image: image) else { return image }

        guard let matrix = CIFilter(name: "CIColorMatrix") else { return image }
        matrix.setValue(input, forKey: kCIInputImageKey)
        matrix.setValue(CIVector(x: parameters.red, y: 0, z: 0, w: 0), forKey: "inputRVector")
        matrix.setValue(CIVector(x: 0, y: parameters.green, z: 0, w: 0), forKey: "inputGVector")
        matrix.setValue(CIVector(x: 0, y: 0, z: parameters.blue, w: 0), forKey: "inputBVector")

        guard let tinted = matrix.outputImage,
              let controls = CIFilter(name: "CIColorControls") else { return image }
        controls.setValue(tinted, forKey: kCIInputImageKey)
        controls.setValue(parameters.saturation, forKey: kCIInputSaturationKey)
        controls.setValue(parameters.contrast, forKey: kCIInputContrastKey)

        guard let output = controls.outputImage,
              let cgImage = context.createCGImage(output, from: input.extent) else { return image }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
