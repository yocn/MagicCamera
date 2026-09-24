import XCTest
#if canImport(CuteStickerCamera)
@testable import CuteStickerCamera
#else
@testable import CuteStickerCore
#endif

final class RecentUsageTests: XCTestCase {
    func testNewItemGoesToTheFront() {
        var list = RecentUsageList()

        list.use("a")
        list.use("b")

        XCTAssertEqual(list.items, ["b", "a"])
    }

    func testReusingAnItemMovesItToTheFrontWithoutDuplicating() {
        var list = RecentUsageList()
        list.use("a")
        list.use("b")
        list.use("c")

        list.use("a")

        XCTAssertEqual(list.items, ["a", "c", "b"], "重复使用应该提到最前而不是新增一条")
    }

    func testListStopsAtSixteenAndDropsTheOldest() {
        var list = RecentUsageList()
        for index in 0..<16 {
            list.use("item\(index)")
        }

        XCTAssertEqual(list.items.count, 16)
        XCTAssertEqual(list.items.last, "item0", "满 16 条时最旧的应该还在队尾")

        list.use("newcomer")

        XCTAssertEqual(list.items.count, 16)
        XCTAssertEqual(list.items.first, "newcomer")
        XCTAssertFalse(list.items.contains("item0"), "超出容量后最旧的那条应被挤掉")
    }

    func testStorePersistsOrderAcrossInstances() {
        let suiteName = "RecentUsageStoreTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var store = RecentUsageStore(key: "recentTest", defaults: defaults)
        store.use("a")
        store.use("b")

        let reloaded = RecentUsageStore(key: "recentTest", defaults: defaults)
        XCTAssertEqual(reloaded.items, ["b", "a"])
    }
}
