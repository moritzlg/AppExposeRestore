import CoreGraphics

enum PreviewViewport {
    /// Only request images near the visible cards; a long window list should
    /// not capture every off-screen thumbnail when Exposé opens.
    static func indices(total: Int, pitch: CGFloat, leftInset: CGFloat, visible: CGRect) -> [Int] {
        guard total > 0, pitch > 0 else { return [] }
        let first = max(0, Int(floor((visible.minX - leftInset) / pitch)) - 1)
        let last = min(total - 1, Int(ceil((visible.maxX - leftInset) / pitch)))
        guard first <= last else { return [] }
        return Array(first...last)
    }
}
