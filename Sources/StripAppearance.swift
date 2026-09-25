import AppKit

enum StripAppearance {
    static func stripBackground(size: NSSize) -> (root: NSView, content: NSView) {
        let frame = NSRect(origin: .zero, size: size)
        let content = NSView(frame: frame)
        content.autoresizingMask = [.width, .height]
        let background = NSVisualEffectView(frame: frame)
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        // A layer corner radius clips subviews, but not the window's material and
        // shadow. AppKit applies maskImage to both when this is the content view.
        background.maskImage = NSImage(size: size, flipped: false) { bounds in
            NSColor.white.setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 17, yRadius: 17).fill()
            return true
        }
        background.addSubview(content)
        return (background, content)
    }

    static func cardBackground(size: NSSize) -> (root: NSView, content: NSView) {
        let frame = NSRect(origin: .zero, size: size)
        let content = NSView(frame: frame)
        content.autoresizingMask = [.width, .height]

        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView(frame: frame)
            glass.cornerRadius = 9
            glass.style = .clear
            if #available(macOS 27.0, *) { glass.effectIsInteractive = true }
            glass.contentView = content
            return (glass, content)
        }

        let background = NSVisualEffectView(frame: frame)
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 9
        background.layer?.masksToBounds = true
        background.addSubview(content)
        return (background, content)
    }
}
