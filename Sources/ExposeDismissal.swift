import CoreGraphics

enum ExposeDismissal {
    /// A click on our own overlay does not select a native Exposé thumbnail.
    /// Send Escape so Dock leaves App Exposé before we focus the restored window.
    static func request() {
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: false) else {
            RestoreTrace.mark("Exposé dismissal event unavailable")
            return
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        RestoreTrace.mark("Exposé dismissal requested")
    }
}
