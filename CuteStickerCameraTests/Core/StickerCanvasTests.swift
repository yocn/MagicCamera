import XCTest
#if canImport(CuteStickerCamera)
@testable import CuteStickerCamera
#else
@testable import CuteStickerCore
#endif

final class StickerCanvasTests: XCTestCase {
    func testCameraScreenDoesNotDisplayAnAppTitle() {
        XCTAssertFalse(CameraScreenChrome.showsAppTitle)
    }

    func testStickerCatalogPutsCuteAccessoriesBeforeCleanExistingStickers() {
        XCTAssertEqual(
            StickerCatalog.assetNames,
            [
                "princess_hair", "bow_hairclip", "pearl_hairpin", "king_crown",
                "ice_queen_crown", "magic_glasses", "fairy_wings",
                "kitten", "puppy", "panda", "strawberry", "cupcake", "dinosaur", "cloud"
            ]
        )
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

        selection = selection.next
        XCTAssertEqual(selection, .strawberryBow)

        selection = selection.next
        XCTAssertEqual(selection, .skyCloud)

        selection = selection.next
        XCTAssertEqual(selection, .crayonDoodle)

        selection = selection.next
        XCTAssertEqual(selection, .starryMoon)

        selection = selection.next
        XCTAssertEqual(selection, .teddyPicnic)

        selection = selection.next
        XCTAssertEqual(selection, .oceanShell)

        selection = selection.next
        XCTAssertEqual(selection, .fairyGarden)

        selection = selection.next
        XCTAssertEqual(selection, .candyParty)

        selection = selection.next
        XCTAssertEqual(selection, .none)
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
