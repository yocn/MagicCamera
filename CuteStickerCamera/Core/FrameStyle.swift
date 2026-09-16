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
        }
    }
}
