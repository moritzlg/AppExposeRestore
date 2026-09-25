import AppKit
import CoreGraphics
import ScreenCaptureKit

enum WindowPreviewCapture {
    static var isAuthorized: Bool { CGPreflightScreenCaptureAccess() }

    /// Captures only the matched minimized windows. Images remain in memory.
    static func start(requests: [WindowPreviewRequest],
                      onImage: @escaping (Int, CGImage) -> Void,
                      onFinished: @escaping @Sendable () -> Void) -> Task<Void, Never>? {
        guard isAuthorized, !requests.isEmpty else { return nil }
        return Task {
            defer { DispatchQueue.main.async(execute: onFinished) }
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
                guard !Task.isCancelled else { return }
                let candidates = content.windows.map {
                    WindowPreviewCandidate(windowID: $0.windowID,
                                           processID: $0.owningApplication?.processID ?? -1,
                                           frame: $0.frame,
                                           title: $0.title,
                                           isOnScreen: $0.isOnScreen)
                }
                let matches = WindowPreviewMatcher.match(requests, to: candidates)
                RestoreTrace.mark("preview matches \(matches.count)/\(requests.count)")
                for request in requests {
                    guard !Task.isCancelled else { return }
                    guard let id = matches[request.index],
                          let window = content.windows.first(where: { $0.windowID == id }) else { continue }
                    let filter = SCContentFilter(desktopIndependentWindow: window)
                    let configuration = SCStreamConfiguration()
                    let scale = min(480 / max(window.frame.width, 1),
                                    300 / max(window.frame.height, 1))
                    configuration.width = max(1, Int((window.frame.width * scale).rounded()))
                    configuration.height = max(1, Int((window.frame.height * scale).rounded()))
                    configuration.showsCursor = false
                    do {
                        let image = try await SCScreenshotManager.captureImage(
                            contentFilter: filter, configuration: configuration)
                        guard !Task.isCancelled else { return }
                        RestoreTrace.mark("preview captured \(image.width)x\(image.height)")
                        DispatchQueue.main.async { onImage(request.index, image) }
                    } catch {
                        RestoreTrace.mark("preview image unavailable")
                    }
                }
            } catch {
                RestoreTrace.mark("preview window list unavailable")
            }
        }
    }
}
