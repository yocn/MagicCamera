import CoreGraphics
import Foundation

public enum CollageDecoration: String, Equatable, Sendable {
    case none
    case wave
    case rainbow
    case stars
}

/// Core target 不依赖 UIKit，颜色以分量形式传递。
public struct CollageBackground: Equatable, Sendable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let clear = CollageBackground(red: 0, green: 0, blue: 0, alpha: 0)
    public static let white = CollageBackground(red: 1, green: 1, blue: 1, alpha: 1)
    public static let cream = CollageBackground(red: 1, green: 0.965, blue: 0.914, alpha: 1)
    public static let blush = CollageBackground(red: 1, green: 0.914, blue: 0.949, alpha: 1)
}

public struct CollageStyleMetrics: Equatable, Sendable {
    /// 画布宽度比例。
    public let outerMargin: CGFloat
    /// 画布宽度比例。
    public let gutter: CGFloat
    /// 格子短边比例。
    public let cornerRadius: CGFloat
    public let background: CollageBackground
    public let decoration: CollageDecoration

    public init(
        outerMargin: CGFloat,
        gutter: CGFloat,
        cornerRadius: CGFloat,
        background: CollageBackground,
        decoration: CollageDecoration
    ) {
        self.outerMargin = outerMargin
        self.gutter = gutter
        self.cornerRadius = cornerRadius
        self.background = background
        self.decoration = decoration
    }
}

public enum CollageStyle: String, CaseIterable, Identifiable, Sendable {
    case plain
    case classicWhite
    case cream
    case wave
    case rainbow
    case stars

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .plain: "无边"
        case .classicWhite: "经典白边"
        case .cream: "奶油圆角"
        case .wave: "波浪花边"
        case .rainbow: "彩虹条"
        case .stars: "星星点点"
        }
    }

    public var iconName: String {
        switch self {
        case .plain: "square"
        case .classicWhite: "square.inset.filled"
        case .cream: "square.on.square"
        case .wave: "water.waves"
        case .rainbow: "rainbow"
        case .stars: "sparkles"
        }
    }

    public var metrics: CollageStyleMetrics {
        switch self {
        case .plain:
            CollageStyleMetrics(outerMargin: 0, gutter: 0, cornerRadius: 0, background: .clear, decoration: .none)
        case .classicWhite:
            CollageStyleMetrics(outerMargin: 0.035, gutter: 0.025, cornerRadius: 0, background: .white, decoration: .none)
        case .cream:
            CollageStyleMetrics(outerMargin: 0.04, gutter: 0.03, cornerRadius: 0.08, background: .cream, decoration: .none)
        case .wave:
            CollageStyleMetrics(outerMargin: 0.05, gutter: 0.03, cornerRadius: 0.06, background: .white, decoration: .wave)
        case .rainbow:
            CollageStyleMetrics(outerMargin: 0.045, gutter: 0.028, cornerRadius: 0.05, background: .white, decoration: .rainbow)
        case .stars:
            CollageStyleMetrics(outerMargin: 0.045, gutter: 0.03, cornerRadius: 0.07, background: .blush, decoration: .stars)
        }
    }
}
