import SwiftUI

extension View {
    /// 预览侧的滤镜：与 PhotoFilterRenderer 用同一组参数和同构的运算。
    func photoFilter(_ filter: PhotoFilter) -> some View {
        let parameters = filter.parameters
        return self
            .colorMultiply(Color(red: parameters.red, green: parameters.green, blue: parameters.blue))
            .saturation(parameters.saturation)
            .contrast(parameters.contrast)
    }
}
