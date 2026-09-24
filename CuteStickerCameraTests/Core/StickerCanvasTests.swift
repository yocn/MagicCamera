import XCTest
import UIKit
#if canImport(CuteStickerCamera)
@testable import CuteStickerCamera
#else
@testable import CuteStickerCore
#endif

final class StickerCanvasTests: XCTestCase {
    func testAppDelegateLocksTheCameraToPortrait() {
        let appDelegate = CameraAppDelegate()

        XCTAssertEqual(
            appDelegate.application(
                UIApplication.shared,
                supportedInterfaceOrientationsFor: nil
            ),
            .portrait
        )
    }

    func testRearCameraSelectionPrefersVirtualTripleCameraBeforePhysicalWideCamera() {
        XCTAssertEqual(
            RearCameraSelection.preferred(from: [.wide, .dual, .triple]),
            .triple
        )
        XCTAssertEqual(
            RearCameraSelection.preferred(from: [.wide, .dualWide]),
            .dualWide
        )
        XCTAssertEqual(RearCameraSelection.preferred(from: [.wide]), .wide)
    }
    func testDualCameraSettingIsOnlyExposedOnSupportedDevices() {
        XCTAssertFalse(CameraControlGrouping.settingsActions(supportsPictureInPicture: false).contains(.pictureInPicture))
        XCTAssertTrue(CameraControlGrouping.settingsActions(supportsPictureInPicture: true).contains(.pictureInPicture))
    }
    func testCameraControlsKeepStickersFramesAndCollageAsQuickActions() {
        XCTAssertEqual(CameraControlGrouping.quickActions, [.stickers, .frames, .collage, .doodle, .filter])
        XCTAssertEqual(
            CameraControlGrouping.settingsActions,
            [.aspectRatio, .sound, .timer]
        )
        XCTAssertEqual(
            CameraControlGrouping.expandedSettingsActions,
            [.pictureInPicture, .sound, .timer, .aspectRatio]
        )
        XCTAssertEqual(CameraControlGrouping.bottomTrailingAction, .switchCamera)
    }

    func testCameraScreenDoesNotDisplayAnAppTitle() {
        XCTAssertFalse(CameraScreenChrome.showsAppTitle)
    }

    func testShutterUsesSystemCameraWhiteRingMetrics() {
        XCTAssertEqual(SystemCameraShutter.outerDiameter, 84)
        XCTAssertEqual(SystemCameraShutter.innerDiameter, 66)
        XCTAssertEqual(SystemCameraShutter.ringLineWidth, 2)
    }

    func testTopCameraChromeSitsBelowTheStatusBarWithExtraClearance() {
        XCTAssertEqual(
            CameraScreenChrome.topPadding(safeAreaTop: 59),
            115,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            CameraScreenChrome.topPadding(safeAreaTop: 0),
            56,
            accuracy: 0.0001
        )
    }

    func testStickerCatalogSeparatesCuteStickersIntoSixCategories() {
        XCTAssertEqual(
            StickerCatalog.categories.map(\.title),
            ["发型", "皇冠", "动物", "甜点", "配饰", "魔法"]
        )
        XCTAssertTrue(
            StickerCatalog.categories.allSatisfy { $0.assetNames.count >= 16 },
            "每个分类至少应显示四排贴纸"
        )
        XCTAssertEqual(StickerCatalog.assetNames.count, 116)
    }

    func testMagicOutfitsContainMultipleCatalogStickersWithDistinctPlacements() {
        XCTAssertFalse(MagicStickerOutfits.all.isEmpty)
        for outfit in MagicStickerOutfits.all {
            XCTAssertGreaterThanOrEqual(outfit.placements.count, 3)
            XCTAssertTrue(outfit.placements.allSatisfy { StickerCatalog.assetNames.contains($0.assetName) })
            let positions = Set(outfit.placements.map { "\($0.center.x),\($0.center.y)" })
            XCTAssertGreaterThan(positions.count, 1)
        }
    }

    func testStickerCategoryPagerUsesEveryCatalogCategoryInOrder() {
        XCTAssertEqual(
            StickerCategoryPager.categoryIDs,
            ["hair", "crowns", "animals", "sweets", "accessories", "magic"]
        )
    }

    func testStickerPagerUsesFullTrayWidthWhileGridKeepsContentPadding() {
        XCTAssertEqual(StickerTrayLayout.pagerHorizontalPadding, 0)
        XCTAssertEqual(StickerTrayLayout.gridHorizontalPadding, 20)
    }

    func testStickerTrayHeaderCentersTitleWithinComfortableInsets() {
        XCTAssertEqual(StickerTrayLayout.headerHorizontalPadding, 20)
        XCTAssertEqual(StickerTrayLayout.headerTopPadding, 18)
        XCTAssertEqual(StickerTrayLayout.headerBottomPadding, 8)
    }

    func testCategoryStripUsesFullWidthScrollerWithInsetContent() {
        XCTAssertEqual(StickerTrayLayout.categoryStripViewportPadding, 0)
        XCTAssertEqual(StickerTrayLayout.categoryStripContentPadding, 20)
    }

    func testStickerSheetAssetResolvesToOneQuarterSizedTile() throws {
        let sheet = try XCTUnwrap(UIImage(named: "hair_sticker_sheet"))
        let tile = try XCTUnwrap(StickerImageProvider.image(named: "hair_sheet_0"))

        XCTAssertEqual(tile.size.width * 4, sheet.size.width, accuracy: 4)
        XCTAssertEqual(tile.size.height * 4, sheet.size.height, accuracy: 4)
    }

    func testCameraSoundPreferenceDefaultsToEnabledAndPersistsSelection() {
        let suiteName = "CameraSoundPreferenceTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var preference = CameraSoundPreference(defaults: defaults)
        XCTAssertTrue(preference.isEnabled)

        preference.isEnabled = false
        XCTAssertFalse(CameraSoundPreference(defaults: defaults).isEnabled)
    }

    func testCameraTimerPreferenceDefaultsToOffAndPersistsSelection() {
        let suiteName = "CameraTimerPreferenceTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var preference = CameraTimerPreference(defaults: defaults)
        XCTAssertFalse(preference.isEnabled)

        preference.isEnabled = true
        XCTAssertTrue(CameraTimerPreference(defaults: defaults).isEnabled)
    }

    func testTimerCountdownAnimationShrinksEachDigitDuringItsSecond() {
        XCTAssertGreaterThan(TimerCountdownAnimation.initialScale, TimerCountdownAnimation.finalScale)
        XCTAssertEqual(TimerCountdownAnimation.duration, 0.82, accuracy: 0.0001)
    }

    func testCameraSwitchAnimationUsesSubtleDimmingWithoutDelayingTheInputSwap() {
        XCTAssertEqual(CameraSwitchAnimation.inputSwapDelay, 0, accuracy: 0.0001)
        XCTAssertEqual(CameraSwitchAnimation.dimmingOpacity, 0.22, accuracy: 0.0001)
        XCTAssertEqual(CameraSwitchAnimation.dimmingDuration, 0.18, accuracy: 0.0001)
        XCTAssertEqual(CameraSwitchAnimation.controlLockDuration, 0.32, accuracy: 0.0001)
        XCTAssertEqual(CameraSwitchAnimation.indicatorDiameter, 76, accuracy: 0.0001)
        XCTAssertGreaterThan(CameraSwitchAnimation.indicatorStartScale, 1)
        XCTAssertEqual(CameraSwitchAnimation.indicatorFadeDuration, 0.18, accuracy: 0.0001)
    }

    func testRecentPhotoStoreKeepsOnlyTheNewestEightPhotos() throws {
        let directory = try makeTemporaryDirectory(named: "RecentPhotoStoreTests")
        var store = RecentPhotoStore(directory: directory, maximumCount: 8)

        for value in 0..<9 {
            try store.store(data: Data([UInt8(value)]))
        }

        XCTAssertEqual(store.items.count, 8)
        XCTAssertEqual(try store.data(for: store.items.first!), Data([8]))
        let storedValues = try store.items.map { try store.data(for: $0) }
        XCTAssertFalse(storedValues.contains(Data([0])))
    }

    func testRecentPhotoStoreReloadsPersistedItems() throws {
        let directory = try makeTemporaryDirectory(named: "RecentPhotoStoreReloadTests")
        var store = RecentPhotoStore(directory: directory, maximumCount: 8)
        let saved = try store.store(data: Data([1, 2, 3]))

        let reloaded = RecentPhotoStore(directory: directory, maximumCount: 8)
        XCTAssertEqual(reloaded.items.map(\.id), [saved.id])
        XCTAssertEqual(try reloaded.data(for: saved), Data([1, 2, 3]))
    }

    func testRecoveredCameraSessionClearsOnlyItsInterruptionNotice() {
        XCTAssertNil(CameraMessage.sessionInterrupted.clearedWhenSessionRecovers())
        XCTAssertEqual(
            CameraMessage.transient("拍照失败，请再试一次。").clearedWhenSessionRecovers(),
            .transient("拍照失败，请再试一次。")
        )
    }

    private func makeTemporaryDirectory(named name: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(name)
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func testPhotoSaveTrackerKeepsMultipleCaptureSavesIndependent() {
        var tracker = PhotoSaveTracker()

        tracker.beginSave()
        tracker.beginSave()
        XCTAssertEqual(tracker.activeSaveCount, 2)

        tracker.finishSave()
        XCTAssertEqual(tracker.activeSaveCount, 1)

        tracker.finishSave()
        XCTAssertEqual(tracker.activeSaveCount, 0)
    }

    func testFrameSelectionCyclesThroughAllCuteFramesAndBackToNone() {
        var selection = FrameStyle.none

        // 按 allCases 顺序走一圈，加新边框不用再改这个用例。
        for expected in FrameStyle.allCases.dropFirst() {
            selection = selection.next
            XCTAssertEqual(selection, expected)
        }

        XCTAssertEqual(selection.next, .none)
    }

    func testNewSlimFramesUseNineSliceStretchingAndKeepTheirCornerArtwork() {
        let newFrames: [FrameStyle] = [
            .iceCrystal,
            .coralReef,
            .rainbowCloud,
            .magicRibbon,
            .strawberryPicnic,
            .spaceRocket
        ]

        XCTAssertEqual(newFrames.compactMap(\.assetName), [
            "ice_crystal_frame",
            "coral_reef_frame",
            "rainbow_cloud_frame",
            "magic_ribbon_frame",
            "strawberry_picnic_frame",
            "space_rocket_frame"
        ])
        XCTAssertTrue(newFrames.allSatisfy { $0.capInsets.sourceRatio > 0 && $0.capInsets.destinationRatio > 0 })
    }

    func testFrameTabsGroupEveryBorderIntoSevenPlayfulStyles() {
        XCTAssertEqual(
            FrameCategory.allCases.map(\.title),
            ["甜心", "梦幻", "自然", "探索", "手账", "派对", "奇趣"]
        )
        XCTAssertEqual(
            Set(FrameCategory.allCases.flatMap(\.styles)),
            Set(FrameStyle.allCases)
        )
        XCTAssertTrue(FrameCategory.nature.styles.contains(.mushroomForest))
        XCTAssertTrue(FrameCategory.whimsy.styles.contains(.dinosaurAdventure))
        XCTAssertTrue(FrameCategory.adventure.styles.contains(.pirateTreasure))
        XCTAssertTrue(FrameCategory.journal.styles.contains(.scrapbookBinder))
        XCTAssertTrue(FrameCategory.party.styles.contains(.candyParty))
    }

    func testEveryFrameTabOffersAtLeastTenDecorativeChoices() {
        for category in FrameCategory.allCases {
            let decorativeStyles = category.styles.filter { $0 != .none }
            XCTAssertGreaterThanOrEqual(
                decorativeStyles.count,
                10,
                "\(category.title) should offer a rich set of frames"
            )
        }
    }

    func testFrameTabsIncludeJournalPartyAndWhimsyCategories() {
        XCTAssertEqual(
            Set(FrameCategory.allCases.map(\.rawValue)),
            Set(["sweet", "dreamy", "nature", "adventure", "journal", "party", "whimsy"])
        )
    }

    func testStructuralFrameCatalogIncludesTheNewMaterialStyles() {
        let structuralFrames: [FrameStyle] = [
            .quiltPatchwork,
            .postageStamp,
            .tornPaperCollage
        ]

        XCTAssertEqual(
            structuralFrames.compactMap(\.assetName),
            [
                "quilt_patchwork_frame",
                "postage_stamp_frame",
                "torn_paper_collage_frame"
            ]
        )
        XCTAssertTrue(structuralFrames.allSatisfy { $0.capInsets == .standard })
    }

    func testFrameCornersScaleWithTheCanvasSoPreviewMatchesThePhoto() {
        let source = CGSize(width: 1024, height: 1536)
        let insets = FrameCapInsets.standard

        let preview = FrameDrawMetrics(
            sourceSize: source,
            destinationSize: CGSize(width: 440, height: 956),
            capInsets: insets
        )
        let photo = FrameDrawMetrics(
            sourceSize: source,
            destinationSize: CGSize(width: 1396, height: 3024),
            capInsets: insets
        )

        // 两种画幅下角落都应占短边的同一比例，否则预览和成片对不上。
        XCTAssertEqual(preview.cap / 440, insets.destinationRatio, accuracy: 0.0001)
        XCTAssertEqual(photo.cap / 1396, insets.destinationRatio, accuracy: 0.0001)

        // 横纵共用一个倍率，插画才不会被拉扁。
        XCTAssertEqual(preview.cap / preview.sourceCap, preview.scale, accuracy: 0.0001)
        XCTAssertEqual(photo.cap / photo.sourceCap, photo.scale, accuracy: 0.0001)
        XCTAssertEqual(preview.sourceCap, photo.sourceCap, accuracy: 0.0001)

        // 四角不能把中缝挤没。
        XCTAssertLessThan(preview.cap * 2, 440)
    }

    func testStickerEditingRemainsAvailableWhenCameraIsUnavailable() {
        XCTAssertTrue(CameraPermissionState.unavailable.allowsStickerEditing)
        XCTAssertFalse(CameraPermissionState.unavailable.allowsPermissionOverlayInteraction)
    }

    func testAddingTwoStickersKeepsBothLayers() {
        var canvas = StickerCanvas()

        canvas.add(assetName: "bunny")
        canvas.add(assetName: "rainbow")

        XCTAssertEqual(canvas.layers.map(\.assetName), ["bunny", "rainbow"])
    }

    func testDraggedLayerPersistsItsEndPosition() {
        let layer = StickerLayer(
            assetName: "bunny",
            center: CGPoint(x: 0.5, y: 0.5)
        )

        let moved = layer.moved(
            by: CGSize(width: 80, height: -100),
            in: CGSize(width: 400, height: 800)
        )

        XCTAssertEqual(moved.center.x, 0.7, accuracy: 0.0001)
        XCTAssertEqual(moved.center.y, 0.375, accuracy: 0.0001)
    }

    func testRotatedLayerAddsHandleAngleDelta() {
        let layer = StickerLayer(assetName: "bunny", rotation: .pi / 6)

        let rotated = layer.rotated(by: .pi / 3)

        XCTAssertEqual(rotated.rotation, .pi / 2, accuracy: 0.0001)
    }

    func testScaledLayerClampsHandleScaleFactor() {
        let layer = StickerLayer(assetName: "bunny", scale: 0.24)

        XCTAssertEqual(layer.scaled(by: 10).scale, 0.8, accuracy: 0.0001)
        XCTAssertEqual(layer.scaled(by: 0.01).scale, 0.08, accuracy: 0.0001)
    }

    func testSelectionCornersRotateWithStickerWhileKeepingControlSizeIndependent() {
        let layout = StickerHandleLayout(contentRect: CGRect(x: 16, y: 16, width: 100, height: 100))
        let positions = layout.positions(transform: CGAffineTransform(rotationAngle: .pi / 2))

        XCTAssertEqual(positions.close.x, 116, accuracy: 0.0001)
        XCTAssertEqual(positions.close.y, 116, accuracy: 0.0001)
        XCTAssertEqual(positions.rotate.x, 16, accuracy: 0.0001)
        XCTAssertEqual(positions.rotate.y, 16, accuracy: 0.0001)
        XCTAssertEqual(positions.scale.x, 16, accuracy: 0.0001)
        XCTAssertEqual(positions.scale.y, 116, accuracy: 0.0001)
    }

    func testUndoRestoresMostRecentlyRemovedSticker() {
        var canvas = StickerCanvas()
        canvas.add(assetName: "bunny")
        canvas.add(assetName: "rainbow")
        let rainbowID = try! XCTUnwrap(canvas.layers.last?.id)

        canvas.remove(id: rainbowID)
        canvas.undo()

        XCTAssertEqual(canvas.layers.map(\.assetName), ["bunny", "rainbow"])
    }

    func testDeselectingCanvasHidesActiveStickerControlsUntilStickerIsSelectedAgain() {
        let canvas = StickerCanvas()
        let layer = canvas.add(assetName: "bunny")

        canvas.select(id: layer.id)
        XCTAssertEqual(canvas.selectedLayerID, layer.id)

        canvas.deselect()
        XCTAssertNil(canvas.selectedLayerID)

        canvas.select(id: layer.id)
        XCTAssertEqual(canvas.selectedLayerID, layer.id)
    }
}
