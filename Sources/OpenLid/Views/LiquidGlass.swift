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

/// Minimal monochrome icon button whose label pops smoothly in a crisp white pill on hover.
public struct GlassIconHoverButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(systemImage: String, label: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.label = label
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isHovered ? .white : Color.white.opacity(0.55))
                .frame(width: 36, height: 28)
                .background(
                    Capsule()
                        .fill(isHovered ? Color.white.opacity(0.14) : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isHovered ? Color.white.opacity(0.24) : Color.clear, lineWidth: 0.75)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
                isHovered = hovering
            }
        }
        .overlay(alignment: .top) {
            if isHovered {
                Text(label)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(.black)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 2)
                    .offset(y: -28)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.88, anchor: .bottom)))
            }
        }
        .zIndex(isHovered ? 20 : 0)
    }
}

