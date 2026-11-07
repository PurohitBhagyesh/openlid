import AppKit

func generateIcon() {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return
    }
    
    // Background squircle (Apple standard rounded rect)
    let rect = CGRect(x: 80, y: 80, width: 864, height: 864)
    let clipPath = CGPath(roundedRect: rect, cornerWidth: 200, cornerHeight: 200, transform: nil)
    ctx.addPath(clipPath)
    ctx.clip()
    
    // Dark space background gradient
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0).cgColor,
        NSColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0).cgColor
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 944), end: CGPoint(x: 512, y: 80), options: [])
    
    // Ambient radial glow behind the eye
    let glowColors = [
        NSColor(red: 0.06, green: 0.72, blue: 0.51, alpha: 0.35).cgColor,
        NSColor(red: 0.02, green: 0.71, blue: 0.83, alpha: 0.12).cgColor,
        NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor
    ] as CFArray
    let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 0.5, 1.0])!
    ctx.drawRadialGradient(glowGrad, startCenter: CGPoint(x: 512, y: 512), startRadius: 0, endCenter: CGPoint(x: 512, y: 512), endRadius: 360, options: [])
    
    // Outer Eye Almond Shape Path
    ctx.saveGState()
    let eyePath = CGMutablePath()
    eyePath.move(to: CGPoint(x: 230, y: 512))
    eyePath.addCurve(to: CGPoint(x: 794, y: 512), control1: CGPoint(x: 410, y: 720), control2: CGPoint(x: 614, y: 720))
    eyePath.addCurve(to: CGPoint(x: 230, y: 512), control1: CGPoint(x: 614, y: 304), control2: CGPoint(x: 410, y: 304))
    eyePath.closeSubpath()
    
    // Sclera / eye background (dark emerald vignette)
    ctx.addPath(eyePath)
    ctx.clip()
    
    let eyeBgColors = [
        NSColor(red: 0.08, green: 0.14, blue: 0.16, alpha: 1.0).cgColor,
        NSColor(red: 0.02, green: 0.04, blue: 0.06, alpha: 1.0).cgColor
    ] as CFArray
    let eyeBgGrad = CGGradient(colorsSpace: colorSpace, colors: eyeBgColors, locations: [0.0, 1.0])!
    ctx.drawRadialGradient(eyeBgGrad, startCenter: CGPoint(x: 512, y: 512), startRadius: 0, endCenter: CGPoint(x: 512, y: 512), endRadius: 280, options: [])
    
    // Iris (Glowing Radiant Emerald & Cyan)
    let irisRect = CGRect(x: 372, y: 372, width: 280, height: 280)
    let irisColors = [
        NSColor(red: 0.2, green: 0.95, blue: 0.65, alpha: 1.0).cgColor,
        NSColor(red: 0.06, green: 0.75, blue: 0.52, alpha: 1.0).cgColor,
        NSColor(red: 0.02, green: 0.45, blue: 0.55, alpha: 1.0).cgColor
    ] as CFArray
    let irisGrad = CGGradient(colorsSpace: colorSpace, colors: irisColors, locations: [0.0, 0.6, 1.0])!
    ctx.drawRadialGradient(irisGrad, startCenter: CGPoint(x: 512, y: 512), startRadius: 0, endCenter: CGPoint(x: 512, y: 512), endRadius: 140, options: [])
    
    // Pupil (Obsidian Black)
    let pupilRect = CGRect(x: 452, y: 452, width: 120, height: 120)
    ctx.setFillColor(NSColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0).cgColor)
    ctx.fillEllipse(in: pupilRect)
    
    // Specular Reflection (Gleam of wakefulness)
    ctx.setFillColor(NSColor(white: 1.0, alpha: 0.75).cgColor)
    ctx.fillEllipse(in: CGRect(x: 470, y: 535, width: 36, height: 36))
    ctx.setFillColor(NSColor(white: 1.0, alpha: 0.45).cgColor)
    ctx.fillEllipse(in: CGRect(x: 520, y: 485, width: 18, height: 18))
    
    ctx.restoreGState()
    
    // Outer Eye Contour stroke with luminous emerald accent
    ctx.addPath(eyePath)
    ctx.setStrokeColor(NSColor(red: 0.1, green: 0.85, blue: 0.55, alpha: 0.9).cgColor)
    ctx.setLineWidth(16)
    ctx.strokePath()
    
    // Border rim for the squircle icon
    ctx.addPath(clipPath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.12).cgColor)
    ctx.setLineWidth(8)
    ctx.strokePath()
    
    image.unlockFocus()
    
    // Export PNG
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG")
        exit(1)
    }
    
    let outUrl = URL(fileURLWithPath: "Resources/icon_1024.png")
    try? pngData.write(to: outUrl)
    print("Generated 1024x1024 icon at Resources/icon_1024.png")
}

generateIcon()

