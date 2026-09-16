import Foundation

struct PhotoSaveTracker {
    private(set) var activeSaveCount = 0

    mutating func beginSave() {
        activeSaveCount += 1
    }

    mutating func finishSave() {
        activeSaveCount = max(0, activeSaveCount - 1)
    }
}
