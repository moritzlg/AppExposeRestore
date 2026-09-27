import AppKit

enum AppArtwork {
    static func menuBarImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()

            let rear = NSBezierPath()
            rear.move(to: NSPoint(x: 5, y: 6))
            rear.line(to: NSPoint(x: 3.7, y: 6))
            rear.curve(to: NSPoint(x: 2, y: 7.7),
                       controlPoint1: NSPoint(x: 2.7, y: 6),
                       controlPoint2: NSPoint(x: 2, y: 6.7))
            rear.line(to: NSPoint(x: 2, y: 13.3))
            rear.curve(to: NSPoint(x: 3.7, y: 15),
                       controlPoint1: NSPoint(x: 2, y: 14.3),
                       controlPoint2: NSPoint(x: 2.7, y: 15))
            rear.line(to: NSPoint(x: 11.3, y: 15))
            rear.curve(to: NSPoint(x: 13, y: 13.3),
                       controlPoint1: NSPoint(x: 12.3, y: 15),
                       controlPoint2: NSPoint(x: 13, y: 14.3))
            rear.line(to: NSPoint(x: 13, y: 12))
            rear.lineWidth = 1.45
            rear.stroke()

            let front = NSBezierPath(roundedRect: NSRect(x: 5, y: 3, width: 11, height: 9),
                                     xRadius: 1.7, yRadius: 1.7)
            front.lineWidth = 1.45
            front.stroke()

            let preview = NSBezierPath()
            preview.move(to: NSPoint(x: 7.2, y: 5.6))
            preview.line(to: NSPoint(x: 13.8, y: 5.6))
            preview.lineWidth = 1.3
            preview.lineCapStyle = .round
            preview.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "App Exposé Restore"
        return image
    }
}
