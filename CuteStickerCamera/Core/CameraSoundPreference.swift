import Foundation

struct CameraSoundPreference {
    static let storageKey = "cameraSoundEnabled"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isEnabled: Bool {
        get {
            guard defaults.object(forKey: Self.storageKey) != nil else { return true }
            return defaults.bool(forKey: Self.storageKey)
        }
        nonmutating set {
            defaults.set(newValue, forKey: Self.storageKey)
        }
    }
}
