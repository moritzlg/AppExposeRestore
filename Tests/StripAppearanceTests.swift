import AppKit

@main
struct StripAppearanceTests {
    static func main() {
        _ = NSApplication.shared
        let strip = StripAppearance.stripBackground(size: NSSize(width: 330, height: 212))
        guard let stripMask = (strip.root as? NSVisualEffectView)?.maskImage,
              stripMask.size == strip.root.bounds.size,
              let maskData = stripMask.tiffRepresentation,
              let maskPixels = NSBitmapImageRep(data: maskData) else {
            fatalError("Strip needs a full-size material mask")
        }
        precondition(maskPixels.colorAt(x: 0, y: 0)?.alphaComponent == 0)
        precondition((maskPixels.colorAt(x: maskPixels.pixelsWide / 2,
                                         y: maskPixels.pixelsHigh / 2)?.alphaComponent ?? 0) > 0.99)
        let size = NSSize(width: 208, height: 144)
        let card = StripAppearance.cardBackground(size: size)

        if #available(macOS 26.0, *) {
            precondition((card.root as? NSGlassEffectView)?.style == .clear)
        } else {
            precondition(card.root is NSVisualEffectView)
        }

        let settings = SettingsWindowController(preferences: AppPreferences())
        guard let content = settings.window?.contentView else { fatalError("Settings content unavailable") }
        func descendants(of view: NSView) -> [NSView] {
            view.subviews.flatMap { [$0] + descendants(of: $0) }
        }
        let controls = descendants(of: content)
        precondition(controls.compactMap { $0 as? NSButton }.count == 3)
        precondition(!controls.contains { $0 is NSPopUpButton })
        print("StripAppearanceTests passed")
    }
}
