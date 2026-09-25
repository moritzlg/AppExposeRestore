import CoreGraphics

@main
struct PreviewViewportTests {
    static func main() {
        precondition(PreviewViewport.indices(total: 0, pitch: 216, leftInset: 0,
                                            visible: CGRect(x: 0, y: 0, width: 430, height: 150)).isEmpty)
        precondition(PreviewViewport.indices(total: 100, pitch: 216, leftInset: 0,
                                            visible: CGRect(x: 0, y: 0, width: 430, height: 150)) == [0, 1, 2])
        precondition(PreviewViewport.indices(total: 100, pitch: 216, leftInset: 0,
                                            visible: CGRect(x: 1000, y: 0, width: 430, height: 150)) == [3, 4, 5, 6, 7])
        precondition(PreviewViewport.indices(total: 2, pitch: 216, leftInset: 100,
                                            visible: CGRect(x: 0, y: 0, width: 500, height: 150)) == [0, 1])
        print("PreviewViewportTests passed")
    }
}
