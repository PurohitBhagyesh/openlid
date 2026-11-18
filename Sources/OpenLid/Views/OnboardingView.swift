import SwiftUI
import OpenLidCore

public struct OnboardingView: View {
    @ObservedObject var preferences = AppPreferences.shared
    @State private var step: Int = 1
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var isInstallingHelper: Bool = false
    @State private var installError: String? = nil
    
    public var onComplete: () -> Void
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            LiquidGlassCanvas()
            
            VStack(spacing: 0) {
                // Step indicators
                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { i in
                        Capsule()
                            .fill(step == i ? Color.white : Color.white.opacity(0.20))
                            .frame(width: step == i ? 20 : 6, height: 5)
                            .animation(.easeInOut(duration: 0.2), value: step)
                    }
                }
                .padding(.top, 26)
                
                Spacer(minLength: 0)
                
                Group {
                    switch step {
                    case 1: welcomeStep
                    case 2: permissionsStep
                    default: modeStep
                    }
                }
                .padding(.horizontal, 26)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 18) {
            AnimatedEyeView(size: 70, isAwake: true, isScanning: true)
            
            VStack(spacing: 6) {
                Text("OpenLid")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Keep your Mac running with the lid closed, cleanly and without external displays.")
                    .font(.system(size: 12.5))
                    .foregroundColor(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            
            VStack(spacing: 0) {
                featureLine("Runs uninterrupted with lid closed")
                hairline
                featureLine("Automatic thermal safety protection")
                hairline
                featureLine("No external monitor or dongle needed")
            }
            .liquidGlassCard(cornerRadius: 13, elevated: false)
            
            Button("Continue") {
                withAnimation(.easeInOut(duration: 0.2)) { step = 2 }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.black)
            .frame(width: 196, height: 38)
            .background(Color.white)
            .clipShape(Capsule())
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }
    
    private var permissionsStep: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Instant Toggle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Authorize once so OpenLid can toggle sleep prevention without password prompts.")
                    .font(.system(size: 12.5))
                    .foregroundColor(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            
            VStack(spacing: 12) {
                Text(helperInstalled ? "Instant Toggle Helper is active." : "Optional — you can also authorize per toggle.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(helperInstalled ? 0.88 : 0.50))
                
                if let err = installError {
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
                
                Button(action: installHelper) {
                    HStack(spacing: 6) {
                        if isInstallingHelper {
                            ProgressView().scaleEffect(0.55)
                            Text("Authorizing...")
                        } else {
                            Text(helperInstalled ? "Authorized" : "Authorize Helper")
                        }
                    }
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(helperInstalled ? Color.white.opacity(0.6) : .black)
                    .frame(width: 196, height: 36)
                    .background(helperInstalled ? Color.white.opacity(0.10) : Color.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(helperInstalled || isInstallingHelper)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .liquidGlassCard(cornerRadius: 14, elevated: false)
            
            HStack(spacing: 16) {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) { step = 1 }
                }
                .font(.system(size: 12.5))
                .foregroundColor(Color.white.opacity(0.55))
                .buttonStyle(.plain)
                
                Button(helperInstalled ? "Continue" : "Skip") {
                    withAnimation(.easeInOut(duration: 0.2)) { step = 3 }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 150, height: 36)
                .background(Color.white)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }
    
    private var modeStep: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Display Mode")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Choose how OpenLid appears on your Mac.")
                    .font(.system(size: 12.5))
                    .foregroundColor(Color.white.opacity(0.55))
            }
            
            VStack(spacing: 0) {
                modeRow(.both, title: "Menu Bar & Window", subtitle: "Quick toggle in menu bar plus full window")
                hairline
                modeRow(.menuBarOnly, title: "Menu Bar Only", subtitle: "Minimal icon in the top menu bar")
                hairline
                modeRow(.windowedApp, title: "Window Only", subtitle: "Standard Dock application window")
            }
            .liquidGlassCard(cornerRadius: 14, elevated: false)
            
            HStack(spacing: 16) {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) { step = 2 }
                }
                .font(.system(size: 12.5))
                .foregroundColor(Color.white.opacity(0.55))
                .buttonStyle(.plain)
                
                Button("Get Started") {
                    onComplete()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 170, height: 38)
                .background(Color.white)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }
    
    private var hairline: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 14)
    }
    
    private func featureLine(_ text: String) -> some View {
        HStack {
            Circle()
                .fill(Color.white.opacity(0.75))
                .frame(width: 4, height: 4)
            Text(text)
                .font(.system(size: 12.5))
                .foregroundColor(Color.white.opacity(0.82))
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
    }
    
    private func modeRow(_ mode: AppPresentationMode, title: String, subtitle: String) -> some View {
        let selected = preferences.presentationMode == mode
        return Button(action: { preferences.presentationMode = mode }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(selected ? Color.white : Color.white.opacity(0.25), lineWidth: 1.25)
                        .frame(width: 16, height: 16)
                    if selected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func installHelper() {
        isInstallingHelper = true
        installError = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try PrivilegeManager.shared.installHelper()
                DispatchQueue.main.async {
                    self.helperInstalled = true
                    self.isInstallingHelper = false
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
