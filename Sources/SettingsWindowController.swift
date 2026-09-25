import AppKit

final class SettingsWindowController: NSWindowController {
    private let preferences: AppPreferences
    private let automaticToggle = NSButton(checkboxWithTitle: L10n.text("settings.automatic"),
                                           target: nil, action: nil)
    private let menuBarToggle = NSButton(checkboxWithTitle: L10n.text("settings.menuBar"),
                                         target: nil, action: nil)
    private let previewToggle = NSButton(checkboxWithTitle: L10n.text("settings.previews"),
                                         target: nil, action: nil)
    var onChange: (() -> Void)?

    init(preferences: AppPreferences) {
        self.preferences = preferences
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 160),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = L10n.text("settings.windowTitle")
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
        configure(window)
        syncControls()
    }

    required init?(coder: NSCoder) { nil }

    func present() {
        syncControls()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func syncControls() {
        automaticToggle.state = preferences.automaticDisplay ? .on : .off
        menuBarToggle.state = preferences.showMenuBarIcon ? .on : .off
        previewToggle.state = preferences.showPreviews ? .on : .off
    }

    private func configure(_ window: NSWindow) {
        guard let content = window.contentView else { return }
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 13
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 26),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -26),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 24)
        ])

        let heading = NSTextField(labelWithString: L10n.text("settings.heading"))
        heading.font = .systemFont(ofSize: 17, weight: .semibold)
        stack.addArrangedSubview(heading)

        for (control, action) in [
            (automaticToggle, #selector(automaticChanged(_:))),
            (menuBarToggle, #selector(menuBarChanged(_:))),
            (previewToggle, #selector(previewChanged(_:)))
        ] {
            control.target = self
            control.action = action
            stack.addArrangedSubview(control)
        }
    }

    @objc private func automaticChanged(_ sender: NSButton) {
        preferences.automaticDisplay = sender.state == .on
        onChange?()
    }

    @objc private func menuBarChanged(_ sender: NSButton) {
        preferences.showMenuBarIcon = sender.state == .on
        onChange?()
    }

    @objc private func previewChanged(_ sender: NSButton) {
        preferences.showPreviews = sender.state == .on
        onChange?()
    }
}
