import Foundation

enum FrameStyle: String, CaseIterable, Equatable {
    case none
    case heart
    case rainbow
    case flower
    case stars

    var next: FrameStyle {
        let styles = Self.allCases
        guard let index = styles.firstIndex(of: self) else { return .none }
        return styles[(index + 1) % styles.count]
    }

    var title: String {
        switch self {
        case .none: "无边框"
        case .heart: "爱心"
        case .rainbow: "彩虹"
        case .flower: "小花"
        case .stars: "星星"
        }
    }

    var icon: String {
        switch self {
        case .none: "rectangle.dashed"
        case .heart: "heart.fill"
        case .rainbow: "rainbow"
        case .flower: "camera.macro"
        case .stars: "sparkles"
        }
    }
}
