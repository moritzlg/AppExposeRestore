import AppKit
import ApplicationServices

struct MinimizedWindow {
    let element: AXUIElement
    let title: String
    let application: NSRunningApplication
    let frame: CGRect?
}

struct WindowLookup {
    let windows: [MinimizedWindow]
    let error: AXError?
}

enum AccessibilityWindows {
    static func minimizedWindows(of application: NSRunningApplication) -> WindowLookup {
        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        var rawWindows: CFTypeRef?
        let windowsResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &rawWindows)
        var rawChildren: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(appElement, kAXChildrenAttribute as CFString, &rawChildren)
        let primary = rawWindows as? [AXUIElement] ?? []
        let childWindows = (rawChildren as? [AXUIElement] ?? []).filter { child in
            var rawRole: CFTypeRef?
            return AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &rawRole) == .success &&
                (rawRole as? String) == (kAXWindowRole as String)
        }
        if windowsResult != .success && childWindows.isEmpty {
            return WindowLookup(windows: [], error: windowsResult)
        }
        let candidates = uniqueElements(primary + childWindows)
        let minimized = candidates.enumerated().compactMap { index, element -> MinimizedWindow? in
            var rawMinimized: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXMinimizedAttribute as CFString, &rawMinimized) == .success,
                  (rawMinimized as? Bool) == true else { return nil }

            var rawTitle: CFTypeRef?
            _ = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &rawTitle)
            let title = (rawTitle as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayTitle = title?.isEmpty == false ? title! : "Fenster \(index + 1)"
            return MinimizedWindow(element: element, title: displayTitle,
                                   application: application, frame: frame(of: element))
        }
        return WindowLookup(windows: minimized, error: nil)
    }

    static func uniqueElements(_ elements: [AXUIElement]) -> [AXUIElement] {
        var unique: [AXUIElement] = []
        for element in elements where !unique.contains(where: { CFEqual($0, element) }) {
            unique.append(element)
        }
        return unique
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        var rawPosition: CFTypeRef?
        var rawSize: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &rawPosition) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &rawSize) == .success,
              let rawPosition, let rawSize,
              CFGetTypeID(rawPosition) == AXValueGetTypeID(),
              CFGetTypeID(rawSize) == AXValueGetTypeID() else { return nil }
        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(rawPosition as! AXValue, .cgPoint, &position),
              AXValueGetValue(rawSize as! AXValue, .cgSize, &size),
              size.width > 0, size.height > 0 else { return nil }
        return CGRect(origin: position, size: size)
    }

    @discardableResult
    static func restore(_ window: MinimizedWindow, raise: Bool) -> Bool {
        RestoreTrace.mark("unminimize started")
        let unminimize = AXUIElementSetAttributeValue(window.element, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        RestoreTrace.mark("unminimize returned \(unminimize.rawValue)")
        guard unminimize == .success else {
            return false
        }
        RestoreTrace.mark("activate started")
        _ = window.application.activate()
        RestoreTrace.mark("activate returned")
        guard raise else {
            RestoreTrace.mark("raise deferred until Exposé closes")
            return true
        }
        _ = self.raise(window)
        return true
    }

    @discardableResult
    static func raise(_ window: MinimizedWindow, timeout: Float? = nil) -> AXError {
        RestoreTrace.mark("raise started")
        if let timeout { AXUIElementSetMessagingTimeout(window.element, timeout) }
        let raise = AXUIElementPerformAction(window.element, kAXRaiseAction as CFString)
        RestoreTrace.mark("raise returned \(raise.rawValue)")
        return raise
    }
}
