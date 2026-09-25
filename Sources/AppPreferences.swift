import Foundation

final class AppPreferences {
    private enum Key {
        static let automatic = "automaticDisplay"
        static let menuBarIcon = "showMenuBarIcon"
        static let previews = "showWindowPreviews"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.automatic: true,
            Key.menuBarIcon: true,
            Key.previews: true
        ])
    }

    var automaticDisplay: Bool {
        get { defaults.bool(forKey: Key.automatic) }
        set { defaults.set(newValue, forKey: Key.automatic) }
    }

    var showMenuBarIcon: Bool {
        get { defaults.bool(forKey: Key.menuBarIcon) }
        set { defaults.set(newValue, forKey: Key.menuBarIcon) }
    }

    var showPreviews: Bool {
        get { defaults.bool(forKey: Key.previews) }
        set { defaults.set(newValue, forKey: Key.previews) }
    }
}
