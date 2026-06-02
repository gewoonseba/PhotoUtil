import AppKit
import Foundation
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetCatalog = root
    .appendingPathComponent("Sources", isDirectory: true)
    .appendingPathComponent("PhotoUtil", isDirectory: true)
    .appendingPathComponent("Assets.xcassets", isDirectory: true)
let appIconSet = assetCatalog.appendingPathComponent("AppIcon.appiconset", isDirectory: true)

try FileManager.default.createDirectory(at: appIconSet, withIntermediateDirectories: true)

let variants: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func drawIcon(size: Int) -> NSImage {
    let scale = CGFloat(size) / 1024
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let baseRect = rect.insetBy(dx: 54 * scale, dy: 54 * scale)
    let basePath = NSBezierPath(roundedRect: baseRect, xRadius: 220 * scale, yRadius: 220 * scale)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.07, green: 0.11, blue: 0.16, alpha: 1),
        NSColor(calibratedRed: 0.08, green: 0.29, blue: 0.32, alpha: 1),
        NSColor(calibratedRed: 0.03, green: 0.55, blue: 0.49, alpha: 1),
    ])!
    gradient.draw(in: basePath, angle: 315)

    NSColor(calibratedWhite: 1, alpha: 0.18).setStroke()
    basePath.lineWidth = 10 * scale
    basePath.stroke()

    let photoRect = NSRect(x: 210 * scale, y: 244 * scale, width: 520 * scale, height: 472 * scale)
    let photoPath = NSBezierPath(roundedRect: photoRect, xRadius: 64 * scale, yRadius: 64 * scale)
    NSColor(calibratedRed: 0.96, green: 0.98, blue: 0.96, alpha: 1).setFill()
    photoPath.fill()

    NSColor(calibratedRed: 0.12, green: 0.16, blue: 0.20, alpha: 0.16).setStroke()
    photoPath.lineWidth = 8 * scale
    photoPath.stroke()

    let skyRect = photoRect.insetBy(dx: 40 * scale, dy: 44 * scale)
    let skyPath = NSBezierPath(roundedRect: skyRect, xRadius: 34 * scale, yRadius: 34 * scale)
    NSColor(calibratedRed: 0.77, green: 0.91, blue: 0.91, alpha: 1).setFill()
    skyPath.fill()

    let sunRect = NSRect(x: 564 * scale, y: 570 * scale, width: 86 * scale, height: 86 * scale)
    NSColor(calibratedRed: 0.98, green: 0.72, blue: 0.22, alpha: 1).setFill()
    NSBezierPath(ovalIn: sunRect).fill()

    let mountain = NSBezierPath()
    mountain.move(to: NSPoint(x: 258 * scale, y: 296 * scale))
    mountain.line(to: NSPoint(x: 420 * scale, y: 484 * scale))
    mountain.line(to: NSPoint(x: 542 * scale, y: 354 * scale))
    mountain.line(to: NSPoint(x: 638 * scale, y: 462 * scale))
    mountain.line(to: NSPoint(x: 692 * scale, y: 296 * scale))
    mountain.close()
    NSColor(calibratedRed: 0.13, green: 0.47, blue: 0.41, alpha: 1).setFill()
    mountain.fill()

    let cardRect = NSRect(x: 558 * scale, y: 188 * scale, width: 260 * scale, height: 340 * scale)
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 44 * scale, yRadius: 44 * scale)
    NSColor(calibratedRed: 0.98, green: 0.99, blue: 0.98, alpha: 1).setFill()
    cardPath.fill()
    NSColor(calibratedRed: 0.04, green: 0.08, blue: 0.11, alpha: 0.26).setStroke()
    cardPath.lineWidth = 8 * scale
    cardPath.stroke()

    let notch = NSBezierPath()
    notch.move(to: NSPoint(x: 704 * scale, y: 528 * scale))
    notch.line(to: NSPoint(x: 818 * scale, y: 528 * scale))
    notch.line(to: NSPoint(x: 818 * scale, y: 412 * scale))
    notch.close()
    NSColor(calibratedRed: 0.10, green: 0.54, blue: 0.49, alpha: 1).setFill()
    notch.fill()

    NSColor(calibratedRed: 0.11, green: 0.15, blue: 0.18, alpha: 0.82).setFill()
    for x in stride(from: 608, through: 744, by: 34) {
        NSRect(x: CGFloat(x) * scale, y: 434 * scale, width: 14 * scale, height: 64 * scale).fill()
    }

    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 500 * scale, y: 604 * scale))
    arrow.line(to: NSPoint(x: 500 * scale, y: 788 * scale))
    arrow.line(to: NSPoint(x: 426 * scale, y: 720 * scale))
    arrow.line(to: NSPoint(x: 404 * scale, y: 742 * scale))
    arrow.line(to: NSPoint(x: 516 * scale, y: 854 * scale))
    arrow.line(to: NSPoint(x: 628 * scale, y: 742 * scale))
    arrow.line(to: NSPoint(x: 606 * scale, y: 720 * scale))
    arrow.line(to: NSPoint(x: 532 * scale, y: 788 * scale))
    arrow.line(to: NSPoint(x: 532 * scale, y: 604 * scale))
    arrow.close()
    NSColor(calibratedRed: 0.98, green: 0.99, blue: 0.94, alpha: 1).setFill()
    arrow.fill()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let cgImage = bitmap.cgImage,
          let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "PhotoUtilIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not render icon PNG"])
    }

    CGImageDestinationAddImage(destination, cgImage, nil)
    if !CGImageDestinationFinalize(destination) {
        throw NSError(domain: "PhotoUtilIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not write icon PNG"])
    }
}

for variant in variants {
    try writePNG(drawIcon(size: variant.size), to: appIconSet.appendingPathComponent(variant.name))
}

let contents = """
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

try contents.write(to: appIconSet.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)

print(appIconSet.path)
