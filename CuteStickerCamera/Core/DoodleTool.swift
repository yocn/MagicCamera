import CoreGraphics
import Foundation

public struct DoodleColor: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat

    public init(id: String, title: String, red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.id = id
        self.title = title
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public enum DoodlePalette {
    public static let all: [DoodleColor] = [
        DoodleColor(id: "strawberry", title: "草莓红", red: 0.95, green: 0.30, blue: 0.36),
        DoodleColor(id: "tangerine", title: "蜜橘橙", red: 1.00, green: 0.60, blue: 0.25),
        DoodleColor(id: "lemon", title: "柠檬黄", red: 1.00, green: 0.85, blue: 0.30),
        DoodleColor(id: "grass", title: "青草绿", red: 0.45, green: 0.80, blue: 0.45),
        DoodleColor(id: "sky", title: "天空蓝", red: 0.35, green: 0.68, blue: 0.95),
        DoodleColor(id: "grape", title: "葡萄紫", red: 0.66, green: 0.50, blue: 0.90),
        DoodleColor(id: "bubble", title: "泡泡粉", red: 1.00, green: 0.62, blue: 0.78),
        DoodleColor(id: "cream", title: "奶油白", red: 1.00, green: 1.00, blue: 1.00)
    ]

    public static let defaultColor = all[6]
}

public enum DoodleBrushWidth: String, CaseIterable, Identifiable, Sendable {
    case thin
    case medium
    case thick

    public var id: String { rawValue }

    public var pointSize: CGFloat {
        switch self {
        case .thin: 6
        case .medium: 14
        case .thick: 26
        }
    }

    public var title: String {
        switch self {
        case .thin: "细"
        case .medium: "中"
        case .thick: "粗"
        }
    }
}

public struct DoodleToolState: Equatable, Sendable {
    public var color: DoodleColor
    public var width: DoodleBrushWidth
    /// 橡皮只是临时切换，颜色和粗细要留着，切回来还是原来那支笔。
    public var isErasing: Bool

    public init(
        color: DoodleColor = DoodlePalette.defaultColor,
        width: DoodleBrushWidth = .medium,
        isErasing: Bool = false
    ) {
        self.color = color
        self.width = width
        self.isErasing = isErasing
    }
}
