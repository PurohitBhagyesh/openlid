import AppKit

func drawMonochromeEyeIcon(in ctx: CGContext, size: CGFloat) {
    let scale = size / 1024.0
    ctx.saveGState()
    ctx.scaleBy(x: scale, y: scale)
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // Apple standard squircle bounds
    let rect = CGRect(x: 80, y: 80, width: 864, height: 864)
    let clipPath = CGPath(roundedRect: rect, cornerWidth: 204, cornerHeight: 204, transform: nil)
    
    ctx.saveGState()
    ctx.addPath(clipPath)
    ctx.clip()
    
    // Deep obsidian Liquid Glass background
    let bgColors = [
        NSColor(white: 0.11, alpha: 1.0).cgColor,
        NSColor(white: 0.045, alpha: 1.0).cgColor,
        NSColor(white: 0.02, alpha: 1.0).cgColor
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 0.55, 1.0])!
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 944), end: CGPoint(x: 512, y: 80), options: [])
    
    // Soft top-edge glass sheen highlight
    let sheenColors = [
        NSColor(white: 1.0, alpha: 0.14).cgColor,
        NSColor(white: 1.0, alpha: 0.0).cgColor
    ] as CFArray
    let sheenGrad = CGGradient(colorsSpace: colorSpace, colors: sheenColors, locations: [0.0, 1.0])!
    ctx.drawRadialGradient(
        sheenGrad,
        startCenter: CGPoint(x: 512, y: 940),
        startRadius: 20,
        endCenter: CGPoint(x: 512, y: 860),
        endRadius: 540,
        options: []
    )
    
    // Subtle neutral white luminance behind the eye
    let glowColors = [
        NSColor(white: 1.0, alpha: 0.16).cgColor,
        NSColor(white: 1.0, alpha: 0.04).cgColor,
        NSColor(white: 1.0, alpha: 0.0).cgColor
    ] as CFArray
    let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 0.45, 1.0])!
    ctx.drawRadialGradient(
        glowGrad,
        startCenter: CGPoint(x: 512, y: 512),
        startRadius: 0,
        endCenter: CGPoint(x: 512, y: 512),
        endRadius: 340,
        options: []
    )
    
    // Outer Eye Almond Path
    let eyePath = CGMutablePath()
    eyePath.move(to: CGPoint(x: 224, y: 512))
    eyePath.addCurve(to: CGPoint(x: 800, y: 512), control1: CGPoint(x: 404, y: 716), control2: CGPoint(x: 620, y: 716))
    eyePath.addCurve(to: CGPoint(x: 224, y: 512), control1: CGPoint(x: 620, y: 308), control2: CGPoint(x: 404, y: 308))
    eyePath.closeSubpath()
    
    ctx.saveGState()
    ctx.addPath(eyePath)
    ctx.clip()
    
    // Crisp luminous white-silver sclera
    let scleraColors = [
        NSColor(white: 1.0, alpha: 1.0).cgColor,
        NSColor(white: 0.90, alpha: 1.0).cgColor,
        NSColor(white: 0.78, alpha: 1.0).cgColor
    ] as CFArray
    let scleraGrad = CGGradient(colorsSpace: colorSpace, colors: scleraColors, locations: [0.0, 0.65, 1.0])!
    ctx.drawLinearGradient(scleraGrad, start: CGPoint(x: 512, y: 690), end: CGPoint(x: 512, y: 334), options: [])
    
    // Deep obsidian iris
    let irisRect = CGRect(x: 382, y: 382, width: 260, height: 260)
    let irisColors = [
        NSColor(white: 0.16, alpha: 1.0).cgColor,
        NSColor(white: 0.05, alpha: 1.0).cgColor,
        NSColor(white: 0.02, alpha: 1.0).cgColor
    ] as CFArray
    let irisGrad = CGGradient(colorsSpace: colorSpace, colors: irisColors, locations: [0.0, 0.65, 1.0])!
    ctx.saveGState()
    ctx.addEllipse(in: irisRect)
    ctx.clip()
    ctx.drawRadialGradient(irisGrad, startCenter: CGPoint(x: 512, y: 512), startRadius: 10, endCenter: CGPoint(x: 512, y: 512), endRadius: 130, options: [])
    ctx.restoreGState()
    
    // Fine monochrome inner glass ring
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.22).cgColor)
    ctx.setLineWidth(6)
    ctx.strokeEllipse(in: CGRect(x: 404, y: 404, width: 216, height: 216))
    
    // Jet-black pupil
    let pupilRect = CGRect(x: 454, y: 454, width: 116, height: 116)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillEllipse(in: pupilRect)
    
    // Crisp specular glass glints
    ctx.setFillColor(NSColor(white: 1.0, alpha: 0.94).cgColor)
    ctx.fillEllipse(in: CGRect(x: 468, y: 536, width: 38, height: 38))
    ctx.setFillColor(NSColor(white: 1.0, alpha: 0.48).cgColor)
    ctx.fillEllipse(in: CGRect(x: 526, y: 480, width: 16, height: 16))
    
    ctx.restoreGState()
    
    // Crisp white eye contour stroke
    ctx.addPath(eyePath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.92).cgColor)
    ctx.setLineWidth(12)
    ctx.strokePath()
    
    ctx.restoreGState()
    
    // Specular Liquid Glass squircle rim
    ctx.addPath(clipPath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.22).cgColor)
    ctx.setLineWidth(7)
    ctx.strokePath()
    
    ctx.restoreGState()
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG for \(path)")
        exit(1)
    }
    try! pngData.write(to: URL(fileURLWithPath: path))
}

func saveJPEG(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let jpgData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
        print("Failed to encode JPEG for \(path)")
        exit(1)
    }
    try! jpgData.write(to: URL(fileURLWithPath: path))
}

func generateIcon() {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: 1024,
        pixelsHigh: 1024,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    drawMonochromeEyeIcon(in: NSGraphicsContext.current!.cgContext, size: 1024)
    NSGraphicsContext.restoreGraphicsState()
    
    let pngData = rep.representation(using: .png, properties: [:])!
    try! pngData.write(to: URL(fileURLWithPath: "Resources/icon_1024.png"))
    try! pngData.write(to: URL(fileURLWithPath: "assets/app-icon.png"))
    try! pngData.write(to: URL(fileURLWithPath: "website/assets/app-icon.png"))
    print("✅ Generated 1024x1024 monochrome Liquid Glass icon")
    
    // Generate 1200x630 monochrome Open Graph social preview image (v2.0)
    let ogRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: 1200,
        pixelsHigh: 630,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: ogRep)
    let ctx = NSGraphicsContext.current!.cgContext
    let cs = CGColorSpaceCreateDeviceRGB()
    
    let bgGrad = CGGradient(
        colorsSpace: cs,
        colors: [
            NSColor(white: 0.08, alpha: 1.0).cgColor,
            NSColor(white: 0.03, alpha: 1.0).cgColor
        ] as CFArray,
        locations: [0.0, 1.0]
    )!
    ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 600, y: 630), end: CGPoint(x: 600, y: 0), options: [])
    
    // Subtle center top white radial bloom
    let topGlow = CGGradient(
        colorsSpace: cs,
        colors: [NSColor(white: 1.0, alpha: 0.10).cgColor, NSColor.clear.cgColor] as CFArray,
        locations: [0.0, 1.0]
    )!
    ctx.drawRadialGradient(topGlow, startCenter: CGPoint(x: 600, y: 450), startRadius: 0, endCenter: CGPoint(x: 600, y: 450), endRadius: 480, options: [])
    
    // Draw monochrome icon centered above text
    ctx.saveGState()
    ctx.translateBy(x: 500, y: 340)
    drawMonochromeEyeIcon(in: ctx, size: 200)
    ctx.restoreGState()
    
    // Typography
    let titleAttr: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 64, weight: .bold),
        .foregroundColor: NSColor.white
    ]
    let titleStr = NSAttributedString(string: "OpenLid 2.0", attributes: titleAttr)
    let titleSize = titleStr.size()
    titleStr.draw(at: CGPoint(x: (1200 - titleSize.width) / 2, y: 235))
    
    let subAttr: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 26, weight: .regular),
        .foregroundColor: NSColor(white: 0.65, alpha: 1.0)
    ]
    let subStr = NSAttributedString(string: "Keep your laptop running with the lid closed • macOS & Windows", attributes: subAttr)
    let subSize = subStr.size()
    subStr.draw(at: CGPoint(x: (1200 - subSize.width) / 2, y: 180))
    
    let urlAttr: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .medium),
        .foregroundColor: NSColor(white: 0.42, alpha: 1.0)
    ]
    let urlStr = NSAttributedString(string: "openlid.devs.li", attributes: urlAttr)
    let urlSize = urlStr.size()
    urlStr.draw(at: CGPoint(x: (1200 - urlSize.width) / 2, y: 92))
    
    NSGraphicsContext.restoreGraphicsState()
    
    let ogPng = ogRep.representation(using: .png, properties: [:])!
    let ogJpg = ogRep.representation(using: .jpeg, properties: [.compressionFactor: 0.92])!
    try! ogPng.write(to: URL(fileURLWithPath: "assets/og-image.png"))
    try! ogPng.write(to: URL(fileURLWithPath: "website/assets/og-image.png"))
    try! ogJpg.write(to: URL(fileURLWithPath: "assets/og-image.jpg"))
    try! ogJpg.write(to: URL(fileURLWithPath: "website/assets/og-image.jpg"))
    print("✅ Generated monochrome OG images")
}

generateIcon()
