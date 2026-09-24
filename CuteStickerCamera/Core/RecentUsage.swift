import Foundation

public struct RecentUsageList: Equatable, Sendable {
    public static let capacity = 16

    public private(set) var items: [String]

    public init(items: [String] = []) {
        self.items = Array(items.prefix(Self.capacity))
    }

    /// 刚用过的排最前；已经在列表里的提到最前，不产生重复。
    public mutating func use(_ id: String) {
        items.removeAll { $0 == id }
        items.insert(id, at: 0)
        if items.count > Self.capacity {
            items.removeLast(items.count - Self.capacity)
        }
    }
}

public struct RecentUsageStore {
    private let key: String
    private let defaults: UserDefaults
    private var list: RecentUsageList

    public init(key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
        self.list = RecentUsageList(items: defaults.stringArray(forKey: key) ?? [])
    }

    public var items: [String] { list.items }

    public mutating func use(_ id: String) {
        list.use(id)
        defaults.set(list.items, forKey: key)
    }
}

public enum RecentUsageKey {
    public static let stickers = "recentStickers"
    public static let frames = "recentFrames"
}
