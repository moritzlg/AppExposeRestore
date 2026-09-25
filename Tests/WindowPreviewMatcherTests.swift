import CoreGraphics

@main
struct WindowPreviewMatcherTests {
    static func main() {
        let pid: pid_t = 42
        let first = CGRect(x: 10, y: 20, width: 900, height: 700)
        let second = CGRect(x: 90, y: 120, width: 900, height: 700)
        let requests = [
            WindowPreviewRequest(index: 0, processID: pid, frame: first, title: "New Tab - Chrome"),
            WindowPreviewRequest(index: 1, processID: pid, frame: second, title: "New Tab - Chrome")
        ]
        let candidates = [
            WindowPreviewCandidate(windowID: 100, processID: pid, frame: first,
                                   title: "New Tab", isOnScreen: false),
            WindowPreviewCandidate(windowID: 101, processID: pid, frame: second,
                                   title: "New Tab", isOnScreen: false),
            WindowPreviewCandidate(windowID: 102, processID: pid, frame: first,
                                   title: "New Tab", isOnScreen: true)
        ]
        let matched = WindowPreviewMatcher.match(requests, to: candidates)
        precondition(matched[0] == 100 && matched[1] == 101)

        let ambiguous = WindowPreviewMatcher.match([requests[0]], to: [candidates[0],
            WindowPreviewCandidate(windowID: 103, processID: pid, frame: first,
                                   title: "New Tab", isOnScreen: false)])
        precondition(ambiguous.isEmpty)

        let reused = WindowPreviewMatcher.match([requests[0],
            WindowPreviewRequest(index: 2, processID: pid, frame: first, title: "New Tab - Chrome")],
            to: [candidates[0]])
        precondition(reused.isEmpty)
        print("WindowPreviewMatcherTests passed")
    }
}
