import Foundation

public enum CollageCaptureMode: String, CaseIterable, Identifiable, Sendable {
    case burstThree
    case burstFive
    case manual

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .burstThree: "连拍 3 秒"
        case .burstFive: "连拍 5 秒"
        case .manual: "逐格手动"
        }
    }

    public var iconName: String {
        switch self {
        case .burstThree, .burstFive: "timer"
        case .manual: "hand.tap.fill"
        }
    }

    /// 浮层角标用的短文案。
    public var badgeTitle: String {
        switch self {
        case .burstThree: "3 秒"
        case .burstFive: "5 秒"
        case .manual: "手动"
        }
    }

    public var countdownSeconds: Int? {
        switch self {
        case .burstThree: 3
        case .burstFive: 5
        case .manual: nil
        }
    }

    public var isBurst: Bool { countdownSeconds != nil }
}

public enum CollageCaptureTiming {
    /// 两格之间的缓冲，留给上一格的快门效果播完。
    public static let shotInterval: TimeInterval = 0.8
}

public struct CollageSession: Equatable, Sendable {
    /// 换配置会重建 session，预览缓存靠它区分新旧。
    public let id: UUID
    public let layout: CollageLayout
    public let style: CollageStyle
    public let mode: CollageCaptureMode
    public private(set) var capturedCount: Int

    public init(layout: CollageLayout, style: CollageStyle, mode: CollageCaptureMode) {
        self.id = UUID()
        self.layout = layout
        self.style = style
        self.mode = mode
        self.capturedCount = 0
    }

    public var currentIndex: Int { min(capturedCount, layout.shotCount - 1) }

    public var remaining: Int { max(0, layout.shotCount - capturedCount) }

    public var isComplete: Bool { capturedCount >= layout.shotCount }

    public mutating func advance() {
        guard !isComplete else { return }
        capturedCount += 1
    }
}
