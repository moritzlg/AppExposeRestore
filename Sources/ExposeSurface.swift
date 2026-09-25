import AppKit
import CoreGraphics

/// Classifies Dock's overview surfaces. These layers are undocumented and
/// must be kept separate from the rest of the app.
final class ExposeSurface {
    struct Snapshot {
        let applicationExpose: Bool
        let overview: Bool
    }

    private var dockPID: pid_t?
    private var windowManagerPID: pid_t?

    init() { refreshProcesses() }

    func isVisible() -> Bool { snapshot().applicationExpose }

    func snapshot() -> Snapshot {
        Self.classify(currentWindows(), dockPID: dockPID, windowManagerPID: windowManagerPID)
    }

    private func currentWindows() -> [[String: Any]] {
        if dockPID == nil || windowManagerPID == nil { refreshProcesses() }
        return (CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]]) ?? []
    }

    static func isApplicationExpose(in windows: [[String: Any]], dockPID: pid_t?, windowManagerPID: pid_t?) -> Bool {
        classify(windows, dockPID: dockPID, windowManagerPID: windowManagerPID).applicationExpose
    }

    static func containsSurface(in windows: [[String: Any]], dockPID: pid_t?, windowManagerPID: pid_t?) -> Bool {
        classify(windows, dockPID: dockPID, windowManagerPID: windowManagerPID).overview
    }

    private static func classify(_ windows: [[String: Any]], dockPID: pid_t?, windowManagerPID: pid_t?) -> Snapshot {
        var layer18 = 0
        var layer20 = 0
        var managerLayer14 = false
        var managerLayer19 = false
        for info in windows {
            guard let owner = info[kCGWindowOwnerPID as String] as? Int,
                  let layer = info[kCGWindowLayer as String] as? Int else { continue }
            if let windowManagerPID, owner == Int(windowManagerPID) {
                if layer == 14 { managerLayer14 = true }
                if layer == 19 { managerLayer19 = true }
            }
            if let dockPID, owner == Int(dockPID) {
                if layer == 18 { layer18 += 1 }
                if layer == 20 { layer20 += 1 }
            }
        }
        let overview = managerLayer14 || managerLayer19 || layer18 > 0
        // Measured on macOS 27: both modes have WindowManager layer 19 and
        // Dock layer 20, while only Mission Control adds layer 14.
        if managerLayer14 { return Snapshot(applicationExpose: false, overview: overview) }
        if managerLayer19 { return Snapshot(applicationExpose: layer20 > 0, overview: overview) }
        // Older systems expose Dock layer 18 instead of WindowManager 19.
        return Snapshot(applicationExpose: layer18 > 0 && layer20 > 0 && layer20 <= layer18,
                        overview: overview)
    }

    private func refreshProcesses() {
        dockPID = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first?.processIdentifier
        windowManagerPID = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.WindowManager").first?.processIdentifier
    }
}
