import SwiftUI
import AppKit

/// Authentic native macOS translucent Liquid Glass window backdrop.
public struct LiquidGlassBackdrop: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    
    public init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
    }
}

/// Full-window Liquid Glass canvas: real behind-window blur + subtle obsidian veil + top specular edge.
public struct LiquidGlassCanvas: View {
    public var body: some View {
        ZStack {
            LiquidGlassBackdrop(material: .hudWindow, blendingMode: .behindWindow)
            Color.black.opacity(0.42)
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }
}

/// Specular Liquid Glass surface modifier for cards and containers.
public struct LiquidGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let elevated: Bool
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.55)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(elevated ? 0.11 : 0.065),
                                    Color.white.opacity(elevated ? 0.04 : 0.025)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(elevated ? 0.30 : 0.18),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 14, elevated: Bool = false) -> some View {
        modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, elevated: elevated))
    }
}

