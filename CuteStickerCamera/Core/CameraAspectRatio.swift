import CoreGraphics

enum CameraAspectRatio: String, CaseIterable, Identifiable {
    case fullScreen
    case threeQuarter

    var id: Self { self }

    var title: String {
        switch self {
        case .fullScreen: "全屏"
        case .threeQuarter: "3:4"
        }
    }

    var iconName: String {
        switch self {
        case .fullScreen: "rectangle.expand.vertical"
        case .threeQuarter: "rectangle.portrait"
        }
    }

    func contentRect(in containerSize: CGSize) -> CGRect {
        guard self == .threeQuarter, containerSize.width > 0, containerSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }

        let width = min(containerSize.width, containerSize.height * 3 / 4)
        let height = width * 4 / 3
        return CGRect(
            x: (containerSize.width - width) / 2,
            y: (containerSize.height - height) / 2,
            width: width,
            height: height
        )
    }
}
