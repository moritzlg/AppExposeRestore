import AppKit
import ApplicationServices
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let detector = ExposeSurface()
    private let strip = MinimizedStrip()
    private let preferences = AppPreferences()
    private var settingsWindow: SettingsWindowController?
    private var statusItem: NSStatusItem?
    private var menu: NSMenu!
    private var showItem: NSMenuItem!
    private var permissionItem: NSMenuItem!
    private var previewPermissionItem: NSMenuItem!
    private var diagnosticItem: NSMenuItem!
    private var automaticItem: NSMenuItem!
    private var lastApplication: NSRunningApplication?
    private var wasExposing = false
    private var attemptedThisSession = false
    private var manualDisplay = false
    private var lastLookupAllowed: Bool?
    private var previewGrantPendingRestart = false
    private var timer: Timer?
    private var pollingInterval: TimeInterval = 0.25
    private var pendingRaise: MinimizedWindow?
    private var nextRaiseTime: TimeInterval = 0
    private var pendingRaiseDeadline: TimeInterval = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        strip.onRestore = { [weak self] succeeded in
            self?.manualDisplay = false
            if !succeeded { NSSound.beep() }
        }
        strip.onClose = { [weak self] in self?.manualDisplay = false }
        strip.onBeforeAutomaticRestore = { [weak self] in
            if self?.detector.isVisible() == true { ExposeDismissal.request() }
        }
        strip.onDeferredRaise = { [weak self] window in
            self?.pendingRaise = window
            self?.nextRaiseTime = ProcessInfo.processInfo.systemUptime + 0.15
            self?.pendingRaiseDeadline = ProcessInfo.processInfo.systemUptime + 2
            RestoreTrace.mark("raise queued for Exposé exit")
        }
        lastApplication = eligible(NSWorkspace.shared.frontmostApplication)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(applicationActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification, object: nil
        )
        configureMenu()
        applyPresentation()
        schedulePolling(every: 0.25)
        tick()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        strip.hide()
        pendingRaise = nil
    }

    private func configureMenu() {
        menu = NSMenu()
        menu.delegate = self
        showItem = NSMenuItem(title: L10n.text("menu.showMinimized"), action: #selector(showManually), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)
        automaticItem = NSMenuItem(title: L10n.text("menu.automatic"), action: #selector(toggleAutomatic), keyEquivalent: "")
        automaticItem.target = self
        automaticItem.state = preferences.automaticDisplay ? .on : .off
        menu.addItem(automaticItem)
        menu.addItem(.separator())
        permissionItem = NSMenuItem(title: L10n.text("permission.accessibility.check"), action: #selector(openAccessibilitySettings), keyEquivalent: "")
        permissionItem.target = self
        menu.addItem(permissionItem)
        previewPermissionItem = NSMenuItem(title: L10n.text("permission.preview.check"), action: #selector(requestPreviewPermission), keyEquivalent: "")
        previewPermissionItem.target = self
        menu.addItem(previewPermissionItem)
        diagnosticItem = NSMenuItem(title: L10n.text("diagnostic.notChecked"), action: nil, keyEquivalent: "")
        diagnosticItem.isEnabled = false
        menu.addItem(diagnosticItem)
        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: L10n.text("menu.settings"), action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        let quitItem = NSMenuItem(title: L10n.text("menu.quit"), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        updatePermissionItem()
    }

    private func showStatusItem() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: "App Exposé Restore")
        item.button?.toolTip = "App Exposé Restore"
        item.menu = menu
        statusItem = item
    }

    private func applyPresentation() {
        if preferences.showMenuBarIcon {
            showStatusItem()
            _ = NSApp.setActivationPolicy(.accessory)
        } else if NSApp.setActivationPolicy(.regular) {
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
                self.statusItem = nil
            }
        } else {
            preferences.showMenuBarIcon = true
            showStatusItem()
            settingsWindow?.syncControls()
        }
    }

    private func preferencesChanged() {
        automaticItem.state = preferences.automaticDisplay ? .on : .off
        if !preferences.automaticDisplay, !manualDisplay { strip.hide() }
        applyPresentation()
    }

    private func eligible(_ app: NSRunningApplication?) -> NSRunningApplication? {
        guard let app, app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              app.bundleIdentifier != "com.apple.dock",
              app.bundleIdentifier != "com.apple.WindowManager" else { return nil }
        return app
    }

    @objc private func applicationActivated(_ notification: Notification) {
        if let app = eligible(notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication) {
            lastApplication = app
            if manualDisplay { strip.hide(); manualDisplay = false }
        }
    }

    @objc private func tick() {
        let surface = detector.snapshot()
        let exposing = surface.applicationExpose
        schedulePolling(every: exposing ? 0.05 : 0.25)
        if !exposing, let frontmost = eligible(NSWorkspace.shared.frontmostApplication) {
            lastApplication = frontmost
        }
        if exposing != wasExposing {
            wasExposing = exposing
            attemptedThisSession = false
            if !exposing, !manualDisplay { strip.hide() }
        }
        if exposing, preferences.automaticDisplay, !attemptedThisSession {
            attemptedThisSession = true
            _ = showForLastApplication()
        }
        if !surface.overview { completePendingRaise() }
        if pendingRaise != nil, ProcessInfo.processInfo.systemUptime > pendingRaiseDeadline {
            pendingRaise = nil
            RestoreTrace.mark("deferred raise expired")
        }
    }

    private func schedulePolling(every interval: TimeInterval) {
        guard timer == nil || pollingInterval != interval else { return }
        timer?.invalidate()
        pollingInterval = interval
        let next = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.tick() }
        next.tolerance = min(interval * 0.2, 0.02)
        RunLoop.main.add(next, forMode: .common)
        timer = next
    }

    func menuWillOpen(_ menu: NSMenu) { updatePermissionItem() }

    private func completePendingRaise() {
        guard let window = pendingRaise,
              ProcessInfo.processInfo.systemUptime >= nextRaiseTime else { return }
        pendingRaise = nil
        guard !window.application.isTerminated else { return }

        RestoreTrace.mark("deferred activate started")
        _ = window.application.activate()
        RestoreTrace.mark("deferred activate returned")
        _ = AccessibilityWindows.raise(window, timeout: 0.9)
    }

    @discardableResult
    private func showForLastApplication() -> Bool {
        guard let app = lastApplication, !app.isTerminated else {
            diagnosticItem.title = L10n.text("diagnostic.noActiveApp")
            return false
        }
        let lookup = AccessibilityWindows.minimizedWindows(of: app)
        lastLookupAllowed = lookup.error == nil
        updatePermissionItem()
        if let error = lookup.error {
            diagnosticItem.title = L10n.format("diagnostic.axError", error.rawValue)
            return false
        }
        diagnosticItem.title = L10n.format(
            lookup.windows.count == 1 ? "diagnostic.oneWindow" : "diagnostic.manyWindows",
            app.localizedName ?? L10n.text("generic.app"), lookup.windows.count
        )
        guard !lookup.windows.isEmpty else { return false }
        strip.show(lookup.windows, appName: app.localizedName ?? L10n.text("generic.app"), raiseOnRestore: !wasExposing,
                   showsPreviews: preferences.showPreviews)
        return true
    }

    private func updatePermissionItem() {
        permissionItem?.title = (AXIsProcessTrusted() && (lastLookupAllowed ?? true))
            ? L10n.text("permission.accessibility.allowed")
            : L10n.text("permission.accessibility.allow")
        let previewAuthorized = WindowPreviewCapture.isAuthorized
        if !preferences.showPreviews {
            previewPermissionItem?.title = L10n.text("permission.preview.disabled")
        } else if previewAuthorized {
            previewPermissionItem?.title = L10n.text("permission.preview.active")
        } else if previewGrantPendingRestart {
            previewPermissionItem?.title = L10n.text("permission.preview.restart")
        } else {
            previewPermissionItem?.title = L10n.text("permission.preview.allow")
        }
        previewPermissionItem?.isEnabled = preferences.showPreviews && !previewAuthorized && !previewGrantPendingRestart
        showItem?.isEnabled = lastApplication != nil
    }

    @objc private func showManually() {
        manualDisplay = showForLastApplication()
    }

    @objc private func toggleAutomatic() {
        preferences.automaticDisplay.toggle()
        automaticItem.state = preferences.automaticDisplay ? .on : .off
        settingsWindow?.syncControls()
        if !preferences.automaticDisplay, !manualDisplay { strip.hide() }
        if preferences.automaticDisplay, wasExposing {
            attemptedThisSession = true
            _ = showForLastApplication()
        }
    }

    @objc private func showSettings() {
        strip.hide()
        manualDisplay = false
        if settingsWindow == nil {
            let controller = SettingsWindowController(preferences: preferences)
            controller.onChange = { [weak self] in self?.preferencesChanged() }
            settingsWindow = controller
        }
        settingsWindow?.present()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let dockMenu = NSMenu()
        let show = NSMenuItem(title: L10n.text("menu.showMinimized"), action: #selector(showManually), keyEquivalent: "")
        show.target = self
        dockMenu.addItem(show)
        let settings = NSMenuItem(title: L10n.text("menu.settings"), action: #selector(showSettings), keyEquivalent: "")
        settings.target = self
        dockMenu.addItem(settings)
        return dockMenu
    }

    @objc private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func requestPreviewPermission() {
        let granted = CGRequestScreenCaptureAccess()
        previewGrantPendingRestart = granted && !WindowPreviewCapture.isAuthorized
        updatePermissionItem()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
