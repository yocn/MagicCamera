import CoreGraphics
import Foundation

/// 通道乘数走逐通道乘法，与 SwiftUI 的 colorMultiply 和 CIColorMatrix 都是同一个运算，
/// 预览和成片才能对得上；色温类算子两边对不齐，不用。
public struct PhotoFilterParameters: Equatable, Sendable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let saturation: CGFloat
    public let contrast: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, saturation: CGFloat, contrast: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.saturation = saturation
        self.contrast = contrast
    }

    public var isIdentity: Bool {
        red == 1 && green == 1 && blue == 1 && saturation == 1 && contrast == 1
    }
}

public enum PhotoFilter: String, CaseIterable, Identifiable, Sendable {
    case original
    case warm
    case cool
    case mono
    case comic

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .original: "原图"
        case .warm: "暖阳"
        case .cool: "清凉"
        case .mono: "黑白"
        case .comic: "漫画"
        }
    }

    public var iconName: String {
        switch self {
        case .original: "circle"
        case .warm: "sun.max.fill"
        case .cool: "snowflake"
        case .mono: "circle.lefthalf.filled"
        case .comic: "sparkles"
        }
    }

    public var parameters: PhotoFilterParameters {
        switch self {
        case .original:
            PhotoFilterParameters(red: 1.00, green: 1.00, blue: 1.00, saturation: 1.00, contrast: 1.00)
        case .warm:
            PhotoFilterParameters(red: 1.00, green: 0.94, blue: 0.84, saturation: 1.05, contrast: 1.02)
        case .cool:
            PhotoFilterParameters(red: 0.88, green: 0.95, blue: 1.00, saturation: 1.00, contrast: 1.02)
        case .mono:
            PhotoFilterParameters(red: 1.00, green: 1.00, blue: 1.00, saturation: 0.00, contrast: 1.08)
        case .comic:
            PhotoFilterParameters(red: 1.00, green: 0.98, blue: 0.96, saturation: 1.55, contrast: 1.35)
        }
    }
}
