// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CuteStickerCamera",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CuteStickerCore", targets: ["CuteStickerCore"])
    ],
    targets: [
        .target(name: "CuteStickerCore", path: "CuteStickerCamera/Core"),
        .testTarget(name: "CuteStickerCoreTests", dependencies: ["CuteStickerCore"], path: "CuteStickerCameraTests/Core")
    ]
)
