import Foundation

struct StickerCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let iconName: String
    let assetNames: [String]
}

enum StickerCatalog {
    private static let sheetAssetPrefixes = [
        "hair_sheet": "hair_sticker_sheet",
        "crowns_sheet": "crown_sticker_sheet",
        "animals_sheet": "animal_sticker_sheet",
        "sweets_sheet": "sweet_sticker_sheet",
        "accessories_sheet": "accessory_sticker_sheet",
        "magic_sheet": "magic_sticker_sheet"
    ]

    static let categories: [StickerCategory] = [
        StickerCategory(
            id: "hair", title: "发型", iconName: "scissors",
            assetNames: ["princess_hair", "star_twin_tails", "bow_hairclip", "pearl_hairpin"] + sheetAssetNames(prefix: "hair_sheet")
        ),
        StickerCategory(
            id: "crowns", title: "皇冠", iconName: "crown.fill",
            assetNames: ["king_crown", "ice_queen_crown", "heart_gem_tiara"] + sheetAssetNames(prefix: "crowns_sheet")
        ),
        StickerCategory(
            id: "animals", title: "动物", iconName: "pawprint.fill",
            assetNames: ["kitten", "puppy", "panda", "dinosaur", "bunny_bow"] + sheetAssetNames(prefix: "animals_sheet")
        ),
        StickerCategory(
            id: "sweets", title: "甜点", iconName: "birthday.cake.fill",
            assetNames: ["strawberry", "cupcake", "strawberry_macaron"] + sheetAssetNames(prefix: "sweets_sheet")
        ),
        StickerCategory(
            id: "accessories", title: "配饰", iconName: "eyeglasses",
            assetNames: ["magic_glasses", "heart_sunglasses"] + sheetAssetNames(prefix: "accessories_sheet")
        ),
        StickerCategory(
            id: "magic", title: "魔法", iconName: "wand.and.stars",
            assetNames: ["fairy_wings", "cloud", "star_wand"] + sheetAssetNames(prefix: "magic_sheet")
        )
    ]

    static let assetNames = categories.flatMap(\.assetNames)

    static func sheetTile(for assetName: String) -> StickerSheetTile? {
        for (prefix, sourceImageName) in sheetAssetPrefixes {
            let marker = "\(prefix)_"
            guard assetName.hasPrefix(marker), let index = Int(assetName.dropFirst(marker.count)), (0..<16).contains(index) else {
                continue
            }
            return StickerSheetTile(sourceImageName: sourceImageName, index: index)
        }
        return nil
    }

    private static func sheetAssetNames(prefix: String) -> [String] {
        (0..<16).map { "\(prefix)_\($0)" }
    }
}

struct StickerSheetTile: Hashable {
    let sourceImageName: String
    let index: Int

    var row: Int { index / 4 }
    var column: Int { index % 4 }
}

enum StickerCategoryPager {
    static let categories = StickerCatalog.categories
    static let categoryIDs = categories.map(\.id)
}

enum StickerTrayLayout {
    static let pagerHorizontalPadding: CGFloat = 0
    static let gridHorizontalPadding: CGFloat = 20
    static let headerHorizontalPadding: CGFloat = 20
    static let headerTopPadding: CGFloat = 18
    static let headerBottomPadding: CGFloat = 8
    static let categoryStripViewportPadding: CGFloat = 0
    static let categoryStripContentPadding: CGFloat = 20
}
