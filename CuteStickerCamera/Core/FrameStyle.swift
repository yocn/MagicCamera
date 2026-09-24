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
    case mushroomForest
    case butterflyGarden
    case dinosaurAdventure
    case pirateTreasure
    case cherryBallet
    case cupcakeSprinkle
    case peachSoda
    case cookieGarden
    case rainbowCake
    case jellyStar
    case candyCarousel
    case auroraCastle
    case cloudBalloon
    case moonBunny
    case crystalWish
    case sunflowerMeadow
    case ladybugPicnic
    case cloverGarden
    case autumnAcorn
    case submarineSea
    case safariJourney
    case campingAdventure
    case hotAirBalloon
    case rainbowTrain
    case robotLab
    case starExplorer
    case polaroidHeart
    case filmstrip
    case doubleMatBow
    case scallopedPostcard
    case scrapbookBinder
    case ticketStub
    case photoCornerAlbum
    case quiltPatchwork
    case postageStamp
    case tornPaperCollage
    case partyBalloon
    case partyGift
    case partyStreamer
    case partyCupcake
    case partyHat
    case partyBunting
    case journalSpiral
    case journalWashi
    case journalCorkboard
    case journalEnvelope
    case journalRuler
    case journalFlowerStickers
    case journalRibbonDiary
    case journalCraftLabel
    case whimsyToyBlocks
    case whimsyPuzzle
    case whimsyPotion
    case whimsyMonster
    case whimsyTrain
    case whimsySpace
    case whimsyGears

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
        case .mushroomForest: "蘑菇森林"
        case .butterflyGarden: "蝴蝶花园"
        case .dinosaurAdventure: "恐龙探险"
        case .pirateTreasure: "海盗宝藏"
        case .cherryBallet: "樱桃芭蕾"
        case .cupcakeSprinkle: "奶油糖针"
        case .peachSoda: "蜜桃汽水"
        case .cookieGarden: "饼干花园"
        case .rainbowCake: "彩虹蛋糕"
        case .jellyStar: "果冻星星"
        case .candyCarousel: "糖果木马"
        case .auroraCastle: "极光城堡"
        case .cloudBalloon: "云朵热气球"
        case .moonBunny: "月亮小兔"
        case .crystalWish: "水晶心愿"
        case .sunflowerMeadow: "向日葵花田"
        case .ladybugPicnic: "瓢虫野餐"
        case .cloverGarden: "幸运四叶草"
        case .autumnAcorn: "秋日松果"
        case .submarineSea: "深海潜艇"
        case .safariJourney: "草原探险"
        case .campingAdventure: "露营夜灯"
        case .hotAirBalloon: "彩虹热气球"
        case .rainbowTrain: "彩虹小火车"
        case .robotLab: "机器人实验室"
        case .starExplorer: "星际探索"
        case .polaroidHeart: "心心拍立得"
        case .filmstrip: "胶片齿孔"
        case .doubleMatBow: "双层蝴蝶结"
        case .scallopedPostcard: "花边明信片"
        case .scrapbookBinder: "活页手账"
        case .ticketStub: "甜心票根"
        case .photoCornerAlbum: "相册角贴"
        case .quiltPatchwork: "拼布被子"
        case .postageStamp: "花花邮票"
        case .tornPaperCollage: "撕纸拼贴"
        case .partyBalloon: "气球派对"
        case .partyGift: "礼物彩带"
        case .partyStreamer: "彩虹飘带"
        case .partyCupcake: "奶油杯蛋糕"
        case .partyHat: "星星派对帽"
        case .partyBunting: "缤纷三角旗"
        case .journalSpiral: "粉色线圈本"
        case .journalWashi: "胶带贴纸"
        case .journalCorkboard: "软木留言板"
        case .journalEnvelope: "信封收纳袋"
        case .journalRuler: "尺子涂鸦"
        case .journalFlowerStickers: "花花贴纸本"
        case .journalRibbonDiary: "丝带日记本"
        case .journalCraftLabel: "牛皮纸标签"
        case .whimsyToyBlocks: "积木乐园"
        case .whimsyPuzzle: "彩色拼图"
        case .whimsyPotion: "魔法泡泡瓶"
        case .whimsyMonster: "小怪兽涂鸦"
        case .whimsyTrain: "彩虹玩具火车"
        case .whimsySpace: "糖果太空"
        case .whimsyGears: "弹簧齿轮"
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
        case .mushroomForest: "tree.fill"
        case .butterflyGarden: "butterfly.fill"
        case .dinosaurAdventure: "leaf.fill"
        case .pirateTreasure: "sparkles"
        case .cherryBallet: "cherries"
        case .cupcakeSprinkle: "birthday.cake.fill"
        case .peachSoda: "cup.and.saucer.fill"
        case .cookieGarden: "heart.fill"
        case .rainbowCake: "birthday.cake.fill"
        case .jellyStar: "star.fill"
        case .candyCarousel: "sparkles"
        case .auroraCastle: "sparkles"
        case .cloudBalloon: "balloon.2.fill"
        case .moonBunny: "moon.stars.fill"
        case .crystalWish: "wand.and.stars"
        case .sunflowerMeadow: "sun.max.fill"
        case .ladybugPicnic: "leaf.fill"
        case .cloverGarden: "leaf.fill"
        case .autumnAcorn: "leaf.fill"
        case .submarineSea: "water.waves"
        case .safariJourney: "binoculars.fill"
        case .campingAdventure: "tent.fill"
        case .hotAirBalloon: "balloon.2.fill"
        case .rainbowTrain: "tram.fill"
        case .robotLab: "cpu"
        case .starExplorer: "rocket.fill"
        case .polaroidHeart: "photo.fill"
        case .filmstrip: "film"
        case .doubleMatBow: "rectangle.on.rectangle"
        case .scallopedPostcard: "envelope.fill"
        case .scrapbookBinder: "book.closed.fill"
        case .ticketStub: "ticket.fill"
        case .photoCornerAlbum: "photo.on.rectangle"
        case .quiltPatchwork: "square.grid.3x3.fill"
        case .postageStamp: "seal.fill"
        case .tornPaperCollage: "scissors"
        case .partyBalloon: "balloon.2.fill"
        case .partyGift: "gift.fill"
        case .partyStreamer: "rainbow"
        case .partyCupcake: "birthday.cake.fill"
        case .partyHat: "party.popper.fill"
        case .partyBunting: "flag.fill"
        case .journalSpiral: "book.closed.fill"
        case .journalWashi: "star.square.on.square.fill"
        case .journalCorkboard: "pin.fill"
        case .journalEnvelope: "envelope.fill"
        case .journalRuler: "ruler.fill"
        case .journalFlowerStickers: "camera.macro"
        case .journalRibbonDiary: "book.fill"
        case .journalCraftLabel: "tag.fill"
        case .whimsyToyBlocks: "square.grid.3x3.fill"
        case .whimsyPuzzle: "puzzlepiece.fill"
        case .whimsyPotion: "flask.fill"
        case .whimsyMonster: "eye.fill"
        case .whimsyTrain: "tram.fill"
        case .whimsySpace: "rocket.fill"
        case .whimsyGears: "gearshape.2.fill"
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
        case .mushroomForest: "mushroom_forest_frame"
        case .butterflyGarden: "butterfly_garden_frame"
        case .dinosaurAdventure: "dinosaur_adventure_frame"
        case .pirateTreasure: "pirate_treasure_frame"
        case .cherryBallet: "cherry_ballet_frame"
        case .cupcakeSprinkle: "cupcake_sprinkle_frame"
        case .peachSoda: "peach_soda_frame"
        case .cookieGarden: "cookie_garden_frame"
        case .rainbowCake: "rainbow_cake_frame"
        case .jellyStar: "jelly_star_frame"
        case .candyCarousel: "candy_carousel_frame"
        case .auroraCastle: "aurora_castle_frame"
        case .cloudBalloon: "cloud_balloon_frame"
        case .moonBunny: "moon_bunny_frame"
        case .crystalWish: "crystal_wish_frame"
        case .sunflowerMeadow: "sunflower_meadow_frame"
        case .ladybugPicnic: "ladybug_picnic_frame"
        case .cloverGarden: "clover_garden_frame"
        case .autumnAcorn: "autumn_acorn_frame"
        case .submarineSea: "submarine_sea_frame"
        case .safariJourney: "safari_journey_frame"
        case .campingAdventure: "camping_adventure_frame"
        case .hotAirBalloon: "hot_air_balloon_frame"
        case .rainbowTrain: "rainbow_train_frame"
        case .robotLab: "robot_lab_frame"
        case .starExplorer: "star_explorer_frame"
        case .polaroidHeart: "polaroid_heart_frame"
        case .filmstrip: "filmstrip_frame"
        case .doubleMatBow: "double_mat_bow_frame"
        case .scallopedPostcard: "scalloped_postcard_frame"
        case .scrapbookBinder: "scrapbook_binder_frame"
        case .ticketStub: "ticket_stub_frame"
        case .photoCornerAlbum: "photo_corner_album_frame"
        case .quiltPatchwork: "quilt_patchwork_frame"
        case .postageStamp: "postage_stamp_frame"
        case .tornPaperCollage: "torn_paper_collage_frame"
        case .partyBalloon: "party_balloon_frame"
        case .partyGift: "party_gift_frame"
        case .partyStreamer: "party_streamer_frame"
        case .partyCupcake: "party_cupcake_frame"
        case .partyHat: "party_hat_frame"
        case .partyBunting: "party_bunting_frame"
        case .journalSpiral: "journal_spiral_frame"
        case .journalWashi: "journal_washi_frame"
        case .journalCorkboard: "journal_corkboard_frame"
        case .journalEnvelope: "journal_envelope_frame"
        case .journalRuler: "journal_ruler_frame"
        case .journalFlowerStickers: "journal_flower_stickers_frame"
        case .journalRibbonDiary: "journal_ribbon_diary_frame"
        case .journalCraftLabel: "journal_craft_label_frame"
        case .whimsyToyBlocks: "whimsy_toy_blocks_frame"
        case .whimsyPuzzle: "whimsy_puzzle_frame"
        case .whimsyPotion: "whimsy_potion_frame"
        case .whimsyMonster: "whimsy_monster_frame"
        case .whimsyTrain: "whimsy_train_frame"
        case .whimsySpace: "whimsy_space_frame"
        case .whimsyGears: "whimsy_gears_frame"
        }
    }

    var category: FrameCategory {
        switch self {
        case .none, .strawberryBow, .strawberryPicnic, .cherryBallet,
                .peachSoda, .cookieGarden, .jellyStar, .polaroidHeart,
                .doubleMatBow, .scallopedPostcard, .quiltPatchwork, .postageStamp:
            .sweet
        case .skyCloud, .starryMoon, .fairyGarden, .iceCrystal, .rainbowCloud, .magicRibbon,
                .auroraCastle, .cloudBalloon, .moonBunny, .crystalWish:
            .dreamy
        case .teddyPicnic, .oceanShell, .coralReef, .mushroomForest, .butterflyGarden,
                .sunflowerMeadow, .ladybugPicnic, .cloverGarden, .autumnAcorn,
                .tornPaperCollage:
            .nature
        case .spaceRocket, .pirateTreasure, .submarineSea, .safariJourney,
                .campingAdventure, .hotAirBalloon, .rainbowTrain, .starExplorer,
                .filmstrip, .ticketStub:
            .adventure
        case .scrapbookBinder, .photoCornerAlbum, .journalSpiral, .journalWashi, .journalCorkboard,
                .journalEnvelope, .journalRuler, .journalFlowerStickers, .journalRibbonDiary,
                .journalCraftLabel:
            .journal
        case .candyParty, .cupcakeSprinkle, .rainbowCake, .candyCarousel, .partyBalloon, .partyGift,
                .partyStreamer, .partyCupcake, .partyHat, .partyBunting:
            .party
        case .crayonDoodle, .dinosaurAdventure, .robotLab, .whimsyToyBlocks, .whimsyPuzzle,
                .whimsyPotion, .whimsyMonster, .whimsyTrain, .whimsySpace, .whimsyGears:
            .whimsy
        }
    }

    /// 九宫格拉伸：保留角落插画，只有边缘和中央随画幅变化。
    var capInsets: FrameCapInsets {
        assetName == nil ? .zero : .standard
    }
}

enum FrameCategory: String, CaseIterable, Identifiable {
    case sweet
    case dreamy
    case nature
    case adventure
    case journal
    case party
    case whimsy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sweet: "甜心"
        case .dreamy: "梦幻"
        case .nature: "自然"
        case .adventure: "探索"
        case .journal: "手账"
        case .party: "派对"
        case .whimsy: "奇趣"
        }
    }

    var icon: String {
        switch self {
        case .sweet: "heart.fill"
        case .dreamy: "sparkles"
        case .nature: "leaf.fill"
        case .adventure: "paperplane.fill"
        case .journal: "book.closed.fill"
        case .party: "party.popper.fill"
        case .whimsy: "sparkles"
        }
    }

    var styles: [FrameStyle] { FrameStyle.allCases.filter { $0.category == self } }
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
