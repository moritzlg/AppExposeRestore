import AppKit
import CoreGraphics
import Foundation

// Usage: swift Tools/GenerateAppIcon.swift /path/to/AppIcon.iconset
// Then: iconutil -c icns /path/to/AppIcon.iconset -o Resources/AppIcon.icns
guard CommandLine.arguments.count == 2 else {
    fputs("Usage: GenerateAppIcon <output.iconset>\n", stderr)
    exit(2)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red, green: green, blue: blue, alpha: alpha)
}

func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func fill(_ context: CGContext, rect: CGRect, radius: CGFloat) {
    context.addPath(rounded(rect, radius))
    context.fillPath()
}

func panel(_ context: CGContext, rect: CGRect, radius: CGFloat, fill: CGColor, border: CGColor) {
    let path = rounded(rect, radius)
    context.addPath(path)
    context.setFillColor(fill)
    context.fillPath()
    context.addPath(path)
    context.setStrokeColor(border)
    context.setLineWidth(8)
    context.strokePath()
}

func render(_ pixels: Int) throws -> Data {
    let space = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(data: nil, width: pixels, height: pixels,
                                  bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        throw CocoaError(.fileWriteUnknown)
    }
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)

    let base = rounded(CGRect(x: 72, y: 72, width: 880, height: 880), 200)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -13), blur: 35,
                      color: color(0.06, 0.08, 0.25, 0.35))
    context.addPath(base)
    context.setFillColor(color(0.15, 0.18, 0.40))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(base)
    context.clip()
    let gradient = CGGradient(colorsSpace: space,
                              colors: [color(0.16, 0.18, 0.45), color(0.32, 0.31, 0.75),
                                       color(0.36, 0.65, 0.91)] as CFArray,
                              locations: [0, 0.55, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 120, y: 80),
                               end: CGPoint(x: 900, y: 960), options: [])
    context.restoreGState()

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -20), blur: 27,
                      color: color(0.07, 0.08, 0.25, 0.30))
    panel(context, rect: CGRect(x: 185, y: 356, width: 536, height: 409), radius: 58,
          fill: color(0.77, 0.81, 0.99), border: color(0.91, 0.94, 1, 0.65))
    context.restoreGState()

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -22), blur: 31,
                      color: color(0.04, 0.08, 0.22, 0.36))
    panel(context, rect: CGRect(x: 299, y: 266, width: 541, height: 410), radius: 61,
          fill: color(0.96, 0.97, 1), border: color(0.86, 0.90, 1))
    context.restoreGState()

    // A miniature window preview is tucked under the main window.
    panel(context, rect: CGRect(x: 425, y: 202, width: 336, height: 148), radius: 35,
          fill: color(0.27, 0.80, 0.75), border: color(0.79, 1, 0.96))
    context.setFillColor(color(0.10, 0.42, 0.50))
    fill(context, rect: CGRect(x: 458, y: 244, width: 270, height: 71), radius: 15)
    context.setFillColor(color(0.87, 1, 0.97))
    fill(context, rect: CGRect(x: 482, y: 264, width: 137, height: 12), radius: 6)

    context.setFillColor(color(0.62, 0.67, 0.89))
    fill(context, rect: CGRect(x: 340, y: 582, width: 269, height: 13), radius: 7)
    fill(context, rect: CGRect(x: 340, y: 542, width: 383, height: 13), radius: 7)
    fill(context, rect: CGRect(x: 340, y: 502, width: 317, height: 13), radius: 7)
    context.setFillColor(color(0.21, 0.24, 0.56))
    fill(context, rect: CGRect(x: 340, y: 617, width: 150, height: 16), radius: 8)

    guard let image = context.makeImage(),
          let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return png
}

for (name, pixels) in [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
] {
    try render(pixels).write(to: output.appendingPathComponent(name))
}
