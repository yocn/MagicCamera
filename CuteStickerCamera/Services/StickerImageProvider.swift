import UIKit

enum StickerImageProvider {
    private static let sheetTileCache = NSCache<NSString, UIImage>()

    static func image(named assetName: String) -> UIImage? {
        guard let tile = StickerCatalog.sheetTile(for: assetName) else {
            return UIImage(named: assetName)
        }

        let cacheKey = assetName as NSString
        if let cached = sheetTileCache.object(forKey: cacheKey) {
            return cached
        }
        guard let sheet = UIImage(named: tile.sourceImageName), let cropped = crop(tile, from: sheet) else {
            return nil
        }
        sheetTileCache.setObject(cropped, forKey: cacheKey)
        return cropped
    }

    private static func crop(_ tile: StickerSheetTile, from sheet: UIImage) -> UIImage? {
        guard let image = sheet.cgImage else { return nil }

        let width = image.width
        let height = image.height
        let left = width * tile.column / 4
        let right = width * (tile.column + 1) / 4
        let top = height * tile.row / 4
        let bottom = height * (tile.row + 1) / 4
        let rect = CGRect(
            x: CGFloat(left),
            y: CGFloat(top),
            width: CGFloat(right - left),
            height: CGFloat(bottom - top)
        )

        guard let cropped = image.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped, scale: sheet.scale, orientation: .up)
    }
}
