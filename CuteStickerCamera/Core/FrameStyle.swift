import Foundation

enum FrameStyle: String, CaseIterable, Equatable {
    case none
    case strawberryBow
    case skyCloud
    case crayonDoodle
    case starryMoon
    case teddyPicnic
    case oceanShell
    case fairyGarden
    case candyParty
    case iceCrystal
    case coralReef
    case rainbowCloud
    case magicRibbon
    case strawberryPicnic
    case spaceRocket

    var next: FrameStyle {
        let styles = Self.allCases
        guard let index = styles.firstIndex(of: self) else { return .none }
        return styles[(index + 1) % styles.count]
    }

    var title: String {
        switch self {
        case .none: "无边框"
        case .strawberryBow: "草莓蝴蝶结"
        case .skyCloud: "云朵泡泡"
        case .crayonDoodle: "蜡笔花园"
        case .starryMoon: "月亮星空"
        case .teddyPicnic: "小熊野餐"
        case .oceanShell: "海洋贝壳"
        case .fairyGarden: "精灵花园"
        case .candyParty: "糖果生日"
        case .iceCrystal: "冰晶雪花"
        case .coralReef: "珊瑚海底"
        case .rainbowCloud: "彩虹云朵"
        case .magicRibbon: "魔法丝带"
        case .strawberryPicnic: "草莓野餐"
        case .spaceRocket: "小小太空"
        }
    }

    var icon: String {
        switch self {
        case .none: "rectangle.dashed"
        case .strawberryBow: "gift.fill"
        case .skyCloud: "cloud.fill"
        case .crayonDoodle: "pencil"
        case .starryMoon: "moon.stars.fill"
        case .teddyPicnic: "teddybear.fill"
        case .oceanShell: "water.waves"
        case .fairyGarden: "leaf.fill"
        case .candyParty: "birthday.cake.fill"
        case .iceCrystal: "snowflake"
        case .coralReef: "water.waves"
        case .rainbowCloud: "rainbow"
        case .magicRibbon: "sparkles"
        case .strawberryPicnic: "strawberry"
        case .spaceRocket: "sparkles"
        }
    }

    var assetName: String? {
        switch self {
        case .none: nil
        case .strawberryBow: "strawberry_bow_frame"
        case .skyCloud: "sky_cloud_frame"
        case .crayonDoodle: "crayon_doodle_frame"
        case .starryMoon: "starry_moon_frame"
        case .teddyPicnic: "teddy_picnic_frame"
        case .oceanShell: "ocean_shell_frame"
        case .fairyGarden: "fairy_garden_frame"
        case .candyParty: "candy_party_frame"
        case .iceCrystal: "ice_crystal_frame"
        case .coralReef: "coral_reef_frame"
        case .rainbowCloud: "rainbow_cloud_frame"
        case .magicRibbon: "magic_ribbon_frame"
        case .strawberryPicnic: "strawberry_picnic_frame"
        case .spaceRocket: "space_rocket_frame"
        }
    }

    /// 九宫格拉伸：保留角落插画，只有边缘和中央随画幅变化。
    var capInsets: FrameCapInsets {
        assetName == nil ? .zero : .standard
    }
}

/// 角落尺寸用比例而非固定点数，否则同一套参数在预览和成片上粗细差好几倍。
struct FrameCapInsets: Equatable {
    /// 取源图短边这个比例的正方形作为四角。
    let sourceRatio: CGFloat
    /// 四角画到成图上的边长，取画面短边这个比例。
    let destinationRatio: CGFloat

    static let zero = FrameCapInsets(sourceRatio: 0, destinationRatio: 0)
    static let standard = FrameCapInsets(sourceRatio: 0.32, destinationRatio: 0.24)
}
