import Foundation

@main
struct AppPreferencesTests {
    static func main() {
        let suite = "AppExposeRestoreTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("test defaults unavailable") }
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = AppPreferences(defaults: defaults)
        precondition(preferences.automaticDisplay)
        precondition(preferences.showMenuBarIcon)
        precondition(preferences.showPreviews)

        preferences.automaticDisplay = false
        preferences.showMenuBarIcon = false
        preferences.showPreviews = false
        let reloaded = AppPreferences(defaults: defaults)
        precondition(!reloaded.automaticDisplay)
        precondition(!reloaded.showMenuBarIcon)
        precondition(!reloaded.showPreviews)
        print("AppPreferencesTests passed")
    }
}
