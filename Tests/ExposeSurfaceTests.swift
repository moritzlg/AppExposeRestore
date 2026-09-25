import AppKit

@main
struct ExposeSurfaceTests {
    static func main() {
        let pidKey = kCGWindowOwnerPID as String
        let layerKey = kCGWindowLayer as String
        let dock: pid_t = 100
        let manager: pid_t = 200
        let normal = [[pidKey: 200, layerKey: -2147483624]]
        let macOS27 = [[pidKey: 200, layerKey: 19]]
        let older = [[pidKey: 100, layerKey: 18]]
        let unrelated = [[pidKey: 300, layerKey: 19], [pidKey: 200, layerKey: 18]]
        let appExpose = [[pidKey: 100, layerKey: 20],
                         [pidKey: 200, layerKey: 19]]
        let earlyDockSurface = [[pidKey: 100, layerKey: 20]]
        let missionControl = [[pidKey: 100, layerKey: 20], [pidKey: 200, layerKey: 19],
                              [pidKey: 200, layerKey: 14]]
        let olderAppExpose = [[pidKey: 100, layerKey: 18], [pidKey: 100, layerKey: 20]]
        precondition(!ExposeSurface.containsSurface(in: normal, dockPID: dock, windowManagerPID: manager))
        precondition(ExposeSurface.containsSurface(in: macOS27, dockPID: dock, windowManagerPID: manager))
        precondition(ExposeSurface.containsSurface(in: older, dockPID: dock, windowManagerPID: manager))
        precondition(!ExposeSurface.containsSurface(in: unrelated, dockPID: dock, windowManagerPID: manager))
        precondition(!ExposeSurface.containsSurface(in: macOS27, dockPID: dock, windowManagerPID: nil))
        precondition(ExposeSurface.isApplicationExpose(in: appExpose, dockPID: dock, windowManagerPID: manager))
        precondition(!ExposeSurface.isApplicationExpose(in: earlyDockSurface, dockPID: dock, windowManagerPID: manager))
        precondition(!ExposeSurface.isApplicationExpose(in: missionControl, dockPID: dock, windowManagerPID: manager))
        precondition(ExposeSurface.isApplicationExpose(in: olderAppExpose, dockPID: dock, windowManagerPID: manager))
        precondition(!ExposeSurface.isApplicationExpose(in: macOS27, dockPID: dock, windowManagerPID: manager))
        precondition(!ExposeSurface.isApplicationExpose(in: appExpose, dockPID: nil, windowManagerPID: manager))
        print("ExposeSurfaceTests passed")
    }
}
