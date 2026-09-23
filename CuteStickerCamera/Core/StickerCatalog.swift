import CoreGraphics
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

struct MagicStickerOutfit: Identifiable {
    let id: String
    let title: String
    let placements: [MagicStickerPlacement]
}

struct MagicStickerPlacement {
    let assetName: String
    let center: CGPoint
    let scale: CGFloat
    let rotation: CGFloat

    var layer: StickerLayer {
        StickerLayer(assetName: assetName, center: center, scale: scale, rotation: rotation)
    }
}

enum MagicStickerOutfits {
    static let all: [MagicStickerOutfit] = [
        MagicStickerOutfit(
            id: "fairy-princess", title: "小仙女",
            placements: [
                MagicStickerPlacement(assetName: "fairy_wings", center: CGPoint(x: 0.5, y: 0.58), scale: 0.52, rotation: 0),
                MagicStickerPlacement(assetName: "princess_hair", center: CGPoint(x: 0.5, y: 0.32), scale: 0.36, rotation: 0),
                MagicStickerPlacement(assetName: "heart_gem_tiara", center: CGPoint(x: 0.5, y: 0.23), scale: 0.30, rotation: 0),
                MagicStickerPlacement(assetName: "star_wand", center: CGPoint(x: 0.74, y: 0.67), scale: 0.20, rotation: -0.30)
            ]
        ),
        MagicStickerOutfit(
            id: "berry-party", title: "莓果派对",
            placements: [
                MagicStickerPlacement(assetName: "star_twin_tails", center: CGPoint(x: 0.5, y: 0.31), scale: 0.35, rotation: 0),
                MagicStickerPlacement(assetName: "bow_hairclip", center: CGPoint(x: 0.69, y: 0.30), scale: 0.19, rotation: 0.12),
                MagicStickerPlacement(assetName: "strawberry", center: CGPoint(x: 0.27, y: 0.71), scale: 0.19, rotation: -0.24),
                MagicStickerPlacement(assetName: "cupcake", center: CGPoint(x: 0.73, y: 0.72), scale: 0.20, rotation: 0.16)
            ]
        ),
        MagicStickerOutfit(
            id: "royal-cloud", title: "云朵小国王",
            placements: [
                MagicStickerPlacement(assetName: "fairy_wings", center: CGPoint(x: 0.5, y: 0.60), scale: 0.46, rotation: 0),
                MagicStickerPlacement(assetName: "king_crown", center: CGPoint(x: 0.5, y: 0.24), scale: 0.33, rotation: 0),
                MagicStickerPlacement(assetName: "magic_glasses", center: CGPoint(x: 0.5, y: 0.48), scale: 0.30, rotation: 0),
                MagicStickerPlacement(assetName: "cloud", center: CGPoint(x: 0.76, y: 0.37), scale: 0.20, rotation: 0.08)
            ]
        )
    ]

    static func random() -> MagicStickerOutfit {
        all.randomElement() ?? all[0]
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
