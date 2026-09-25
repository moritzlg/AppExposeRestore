import ApplicationServices

@main
struct AccessibilityWindowsTests {
    static func main() {
        let first = AXUIElementCreateApplication(42)
        let sameApplication = AXUIElementCreateApplication(42)
        let second = AXUIElementCreateApplication(43)
        let unique = AccessibilityWindows.uniqueElements([first, sameApplication, second, first])
        precondition(unique.count == 2)
        precondition(CFEqual(unique[0], first) && CFEqual(unique[1], second))
        print("AccessibilityWindowsTests passed")
    }
}
