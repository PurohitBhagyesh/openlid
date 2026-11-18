import SwiftUI
import OpenLidCore

public struct OnboardingView: View {
    @ObservedObject var preferences = AppPreferences.shared
    @State private var step: Int = 1
    @State private var isMovingForward: Bool = true
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var isInstallingHelper: Bool = false
    @State private var installError: String? = nil
    @State private var hoveredMode: AppPresentationMode? = nil
    
    @Namespace private var modeSelectionNamespace
    
    public var onComplete: () -> Void
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: isMovingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isMovingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }
    
    public var body: some View {
        ZStack {
            LiquidGlassCanvas()
            
            VStack(spacing: 0) {
                // Single translucent titlebar directly on the traffic-light row (ZERO extra forehead)
                ZStack {
                    HStack(spacing: 6) {
                        ForEach(1...3, id: \.self) { i in
                            Button(action: { goToStep(i) }) {
                                Capsule()
                                    .fill(step == i ? Color.white : Color.white.opacity(0.22))
                                    .frame(width: step == i ? 22 : 6, height: 5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .animation(.spring(response: 0.34, dampingFraction: 0.80), value: step)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
                
                // Directional smooth sliding step container
                ZStack {
                    if step == 1 {
                        welcomeStep
                            .transition(stepTransition)
                    } else if step == 2 {
                        permissionsStep
                            .transition(stepTransition)
                    } else {
                        modeStep
                            .transition(stepTransition)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .animation(.spring(response: 0.36, dampingFraction: 0.84), value: step)
                
                // Fixed-height bottom navigation bar (zero vertical shift across all 3 steps)
                HStack {
                    if step > 1 {
                        Button(action: { goToStep(step - 1) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 10.5, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 12.5, weight: .medium))
                            }
                            .foregroundColor(Color.white.opacity(0.65))
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(Color.white.opacity(0.07))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.75))
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    }
                    
                    Spacer()
                    
                    Button(action: handlePrimaryAction) {
                        HStack(spacing: 5) {
                            Text(primaryButtonTitle)
                                .font(.system(size: 12.5, weight: .semibold))
                            if step < 3 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10.5, weight: .semibold))
                            }
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 18)
                        .frame(height: 34)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
                .frame(height: 50)
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: step)
                .animation(.easeInOut(duration: 0.2), value: helperInstalled)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
        }
    }
    
    private var primaryButtonTitle: String {
        switch step {
        case 1: return "Continue"
        case 2: return helperInstalled ? "Continue" : "Skip"
        default: return "Get Started"
        }
    }
    
    // MARK: - Step 1: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            
            AnimatedEyeView(size: 62, isAwake: true, isScanning: true)
            
            VStack(spacing: 5) {
                Text("OpenLid")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Keep your Mac running with the lid closed, cleanly and without external displays.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.54))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            VStack(spacing: 0) {
                featureRow(icon: "laptopcomputer", text: "Runs uninterrupted with lid closed")
                hairline
                featureRow(icon: "thermometer.medium", text: "Automatic thermal safety protection")
                hairline
                featureRow(icon: "display", text: "No external monitor or dongle needed")
            }
            .liquidGlassCard(cornerRadius: 12, elevated: false)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
    }
    
    // MARK: - Step 2: Instant Toggle Helper
    private var permissionsStep: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            
            ZStack {
                Image(systemName: helperInstalled ? "checkmark" : "lock.open")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .contentTransition(.interpolate)
            }
            .frame(width: 52, height: 52)
            .liquidGlassCard(cornerRadius: 14, elevated: helperInstalled)
            .animation(.spring(response: 0.34, dampingFraction: 0.80), value: helperInstalled)
            
            VStack(spacing: 5) {
                Text("Instant Toggle")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Authorize once so OpenLid toggles sleep prevention instantly without password prompts.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.54))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            VStack(spacing: 12) {
                Text(helperInstalled ? "Helper active — passwordless toggling ready." : "Optional. You can also authorize per toggle.")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.white.opacity(helperInstalled ? 0.86 : 0.48))
                    .multilineTextAlignment(.center)
                
                if let err = installError {
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                Button(action: installHelper) {
                    HStack(spacing: 6) {
                        if isInstallingHelper {
                            ProgressView()
                                .scaleEffect(0.55)
                            Text("Authorizing...")
                        } else if helperInstalled {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Authorized")
                        } else {
                            Text("Authorize Helper")
                        }
                    }
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(helperInstalled ? Color.white.opacity(0.72) : .black)
                    .frame(width: 184, height: 34)
                    .background(helperInstalled ? Color.white.opacity(0.10) : Color.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(helperInstalled ? Color.white.opacity(0.18) : Color.clear, lineWidth: 0.75)
                    )
                }
                .buttonStyle(.plain)
                .disabled(helperInstalled || isInstallingHelper)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .liquidGlassCard(cornerRadius: 12, elevated: false)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
    }
    
    // MARK: - Step 3: Display Mode (Exclusive home for Menu Bar / Window / Both)
    private var modeStep: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            
            VStack(spacing: 5) {
                Text("Display Mode")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Choose how OpenLid appears on your Mac.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.54))
            }
            
            VStack(spacing: 4) {
                modeRow(
                    .both,
                    icon: "macwindow.on.rectangle",
                    title: "Menu Bar & Window",
                    subtitle: "Quick toggle in menu bar plus desktop window"
                )
                modeRow(
                    .menuBarOnly,
                    icon: "menubar.rectangle",
                    title: "Menu Bar Only",
                    subtitle: "Discreet icon in the top menu bar"
                )
                modeRow(
                    .windowedApp,
                    icon: "macwindow",
                    title: "Window Only",
                    subtitle: "Standard Dock application window"
                )
            }
            .padding(5)
            .liquidGlassCard(cornerRadius: 14, elevated: false)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
    }
    
    // MARK: - Subcomponents
    private var hairline: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 37)
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.54))
                .frame(width: 16, alignment: .center)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.84))
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }
    
    private func modeRow(_ mode: AppPresentationMode, icon: String, title: String, subtitle: String) -> some View {
        let selected = preferences.presentationMode == mode
        let hovered = hoveredMode == mode
        return Button(action: {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                preferences.presentationMode = mode
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selected ? .white : Color.white.opacity(0.50))
                    .frame(width: 20, alignment: .center)
                
                VStack(alignment: .leading, spacing: 1.5) {
                    Text(title)
                        .font(.system(size: 12.5, weight: selected ? .semibold : .medium))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 10.5))
                        .foregroundColor(Color.white.opacity(selected ? 0.62 : 0.44))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(selected ? Color.white : Color.white.opacity(0.24), lineWidth: 1.25)
                        .frame(width: 15, height: 15)
                    if selected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 7.5, height: 7.5)
                            .matchedGeometryEffect(id: "modeDot", in: modeSelectionNamespace)
                    }
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 50)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.11))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.24), lineWidth: 0.75)
                        )
                        .matchedGeometryEffect(id: "modeRowBg", in: modeSelectionNamespace)
                } else if hovered {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) {
                hoveredMode = hovering ? mode : (hoveredMode == mode ? nil : hoveredMode)
            }
        }
    }
    
    // MARK: - Navigation & Actions
    private func goToStep(_ target: Int) {
        guard target != step, (1...3).contains(target) else { return }
        isMovingForward = target > step
        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
            step = target
        }
    }
    
    private func handlePrimaryAction() {
        if step < 3 {
            goToStep(step + 1)
        } else {
            onComplete()
        }
    }
    
    private func installHelper() {
        isInstallingHelper = true
        installError = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try PrivilegeManager.shared.installHelper()
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.80)) {
                        self.helperInstalled = true
                        self.isInstallingHelper = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.installError = error.localizedDescription
                    self.isInstallingHelper = false
                }
            }
        }
    }
}
