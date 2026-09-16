import AppKit

guard CommandLine.arguments.count == 2 else { fatalError("Expected an output .iconset directory") }
let destination = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let size = CGFloat(pixels)
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                            isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap) else { fatalError("Could not create icon bitmap") }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        let inset = size * 0.06
        let base = NSBezierPath(roundedRect: NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2),
                                xRadius: size * 0.21, yRadius: size * 0.21)
        NSGradient(starting: NSColor(calibratedWhite: 0.17, alpha: 1),
                   ending: NSColor(calibratedWhite: 0.045, alpha: 1))?.draw(in: base, angle: -75)
        let notch = NSBezierPath(roundedRect: NSRect(x: size * 0.27, y: size * 0.44, width: size * 0.46, height: size * 0.31),
                                 xRadius: size * 0.09, yRadius: size * 0.09)
        NSColor.black.setFill()
        notch.fill()
        NSColor(calibratedRed: 0.78, green: 0.93, blue: 0.62, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: size * 0.34, y: size * 0.29, width: size * 0.32, height: size * 0.055),
                     xRadius: size * 0.0275, yRadius: size * 0.0275).fill()
        NSBezierPath(ovalIn: NSRect(x: size * 0.45, y: size * 0.53, width: size * 0.10, height: size * 0.10)).fill()
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode icon") }
        try png.write(to: destination.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
    }
}
