import CoreGraphics

struct WindowPreviewRequest {
    let index: Int
    let processID: pid_t
    let frame: CGRect
    let title: String
}

struct WindowPreviewCandidate {
    let windowID: CGWindowID
    let processID: pid_t
    let frame: CGRect
    let title: String?
    let isOnScreen: Bool
}

enum WindowPreviewMatcher {
    /// Never guess when two minimized windows have indistinguishable metadata.
    static func match(_ requests: [WindowPreviewRequest],
                      to candidates: [WindowPreviewCandidate]) -> [Int: CGWindowID] {
        var proposed: [Int: CGWindowID] = [:]
        for request in requests {
            let matches = candidates.filter {
                $0.processID == request.processID && !$0.isOnScreen &&
                $0.frame.width >= 120 && $0.frame.height >= 100 &&
                approximatelyEqual($0.frame, request.frame) &&
                titleMatches(request.title, $0.title)
            }
            if matches.count == 1 { proposed[request.index] = matches[0].windowID }
        }
        let useCounts = Dictionary(grouping: proposed.values, by: { $0 }).mapValues(\.count)
        return proposed.filter { useCounts[$0.value] == 1 }
    }

    private static func approximatelyEqual(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) <= 2 && abs(a.minY - b.minY) <= 2 &&
        abs(a.width - b.width) <= 2 && abs(a.height - b.height) <= 2
    }

    private static func titleMatches(_ accessibilityTitle: String, _ screenshotTitle: String?) -> Bool {
        guard let screenshotTitle, !screenshotTitle.isEmpty else { return false }
        return accessibilityTitle == screenshotTitle ||
            [" - ", " — ", " – "].contains { accessibilityTitle.hasPrefix(screenshotTitle + $0) }
    }
}
