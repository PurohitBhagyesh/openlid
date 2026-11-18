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

/// Full-window Liquid Glass canvas: real behind-window blur + crisp translucent veil + specular rim.
public struct LiquidGlassCanvas: View {
    public var body: some View {
        ZStack {
            LiquidGlassBackdrop(material: .hudWindow, blendingMode: .behindWindow)
            Color.black.opacity(0.22)
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.clear, Color.black.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
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
                        .opacity(0.45)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(elevated ? 0.12 : 0.07),
                                    Color.white.opacity(elevated ? 0.04 : 0.02)
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
                                Color.white.opacity(elevated ? 0.34 : 0.22),
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .animation(.easeInOut(duration: 0.26), value: elevated)
    }
}

public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 12, elevated: Bool = false) -> some View {
        modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, elevated: elevated))
    }
    
    /// Smoothly morphs numeric digits (e.g., timer ticks and battery percentage) across macOS 13+.
    @ViewBuilder
    func smoothNumericTransition(countsDown: Bool = false) -> some View {
        if #available(macOS 14.0, *) {
            self.contentTransition(.numericText(countsDown: countsDown))
        } else {
            self.contentTransition(.numericText())
        }
    }
}

/// Refined monochrome Black & White Liquid Glass switch pill.
public struct LiquidToggle: View {
    @Binding var isOn: Bool
    
    public init(isOn: Binding<Bool>) {
        self._isOn = isOn
    }
    
    public var body: some View {
        ZStack {
            Capsule()
                .fill(isOn ? Color.white : Color.white.opacity(0.12))
                .frame(width: 34, height: 19)
                .overlay(
                    Capsule()
                        .stroke(isOn ? Color.clear : Color.white.opacity(0.18), lineWidth: 0.75)
                )
            Circle()
                .fill(isOn ? Color.black : Color.white.opacity(0.75))
                .frame(width: 13.5, height: 13.5)
                .offset(x: isOn ? 7.5 : -7.5)
        }
        .contentShape(Capsule())
        .onTapGesture {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                isOn.toggle()
            }
        }
    }
}

/// Smooth Liquid Glass segmented capsule where the active white pill glides fluidly via matchedGeometryEffect.
public struct LiquidSegmentedControl<Option: Identifiable & Hashable>: View {
    let options: [Option]
    let selection: Option
    let label: (Option) -> String
    let height: CGFloat
    let fontSize: CGFloat
    let onSelect: (Option) -> Void
    
    @Namespace private var pillNamespace
    @State private var hoveredOption: Option? = nil
    
    public init(
        options: [Option],
        selection: Option,
        height: CGFloat = 34,
        fontSize: CGFloat = 11.5,
        label: @escaping (Option) -> String,
        onSelect: @escaping (Option) -> Void
    ) {
        self.options = options
        self.selection = selection
        self.height = height
        self.fontSize = fontSize
        self.label = label
        self.onSelect = onSelect
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { option in
                let isSelected = option == selection
                let isHovered = hoveredOption == option
                Button(action: {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                        onSelect(option)
                    }
                }) {
                    Text(label(option))
                        .font(.system(size: fontSize, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(
                            isSelected
                                ? .black
                                : (isHovered ? Color.white.opacity(0.92) : Color.white.opacity(0.58))
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.white.opacity(0.16), radius: 5, x: 0, y: 1)
                                    .matchedGeometryEffect(id: "liquidActivePill", in: pillNamespace)
                            } else if isHovered {
                                Capsule()
                                    .fill(Color.white.opacity(0.07))
                                    .transition(.opacity)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.16)) {
                        hoveredOption = hovering ? option : (hoveredOption == option ? nil : hoveredOption)
                    }
                }
            }
        }
        .padding(3)
        .frame(height: height)
        .liquidGlassCard(cornerRadius: height / 2, elevated: false)
    }
}

/// Interactive monochrome icon bar where both the frosted highlight and floating label glide smoothly across icons on hover.
public struct LiquidFooterAction: Identifiable, Hashable {
    public let id: String
    public let systemImage: String
    public let label: String
    
    public init(id: String, systemImage: String, label: String) {
        self.id = id
        self.systemImage = systemImage
        self.label = label
    }
}

public struct LiquidIconDock: View {
    let actions: [LiquidFooterAction]
    let onTrigger: (LiquidFooterAction) -> Void
    
    @State private var hoveredID: String? = nil
    @Namespace private var dockNamespace
    
    public init(actions: [LiquidFooterAction], onTrigger: @escaping (LiquidFooterAction) -> Void) {
        self.actions = actions
        self.onTrigger = onTrigger
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(actions) { item in
                let isHovered = hoveredID == item.id
                Button(action: { onTrigger(item) }) {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isHovered ? .white : Color.white.opacity(0.56))
                        .scaleEffect(isHovered ? 1.08 : 1.0)
                        .frame(width: 38, height: 28)
                        .background {
                            if isHovered {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        Capsule().stroke(Color.white.opacity(0.26), lineWidth: 0.75)
                                    )
                                    .matchedGeometryEffect(id: "dockHighlight", in: dockNamespace)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                        if hovering {
                            hoveredID = item.id
                        } else if hoveredID == item.id {
                            hoveredID = nil
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if isHovered {
                        Text(item.label)
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(.black)
                            .fixedSize()
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 3)
                            .offset(y: -28)
                            .allowsHitTesting(false)
                            .matchedGeometryEffect(id: "dockTooltip", in: dockNamespace)
                            .transition(.opacity.combined(with: .scale(scale: 0.88, anchor: .bottom)))
                    }
                }
                .zIndex(isHovered ? 20 : 0)
            }
        }
        .frame(height: 28)
        .zIndex(20)
    }
}
