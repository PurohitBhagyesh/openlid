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
            // Dark futuristic backdrop
            Color(red: 0.05, green: 0.06, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator dots
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { i in
                        Capsule()
                            .fill(step == i ? Color.green : Color.secondary.opacity(0.3))
                            .frame(width: step == i ? 24 : 8, height: 6)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.top, 24)
                
                Spacer()
                
                Group {
                    switch step {
                    case 1:
                        welcomeStepView
                    case 2:
                        permissionsStepView
                    default:
                        presentationModeStepView
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .frame(width: 580, height: 620)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
        }
    }
    
    // MARK: - Step 1: Welcome Screen
    private var welcomeStepView: some View {
        VStack(spacing: 20) {
            // 3D Animated Vigilant Eye with Eyeballs Scanning Left to Right
            AnimatedEyeView(size: 110, isAwake: true, isScanning: true)
                .padding(.bottom, 6)
            
            VStack(spacing: 8) {
                Text("Welcome to OpenLid")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Keep your laptop running with the lid closed — safely, smoothly, and without external monitors.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
            }
            
            // Feature Highlights
            VStack(alignment: .leading, spacing: 12) {
                featureBullet(
                    icon: "bolt.fill",
                    title: "Full Clamshell Execution",
                    desc: "Audio, rendering, long compiles, and downloads continue uninterrupted."
                )
                featureBullet(
                    icon: "shield.checkerboard",
                    title: "Automated Hardware Sentinels",
                    desc: "Guards against overheating and halts sleep prevention if battery drops below 15%."
                )
                featureBullet(
                    icon: "display",
                    title: "Zero Dongles or External Displays",
                    desc: "Operate your laptop headlessly anywhere without dummy HDMI plugs."
                )
            }
            .padding(18)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .frame(maxWidth: 480)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    step = 2
                }
            }) {
                HStack(spacing: 8) {
                    Text("Get Started")
                        .font(.system(size: 14, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: 240)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(10)
                .shadow(color: Color.green.opacity(0.4), radius: 10, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Step 2: Permissions Screen
    private var permissionsStepView: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .padding(.bottom, 2)
            
            VStack(spacing: 6) {
                Text("Required Permissions")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("OpenLid requires system-level authorization to modify macOS power management and prevent lid-close sleep.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }
            
            VStack(spacing: 10) {
                permissionRow(
                    icon: "terminal.fill",
                    title: "Privileged Sleep Override",
                    desc: "Installs a scoped sudoers rule (/etc/sudoers.d/openlid) to allow passwordless toggling.",
                    isGranted: helperInstalled
                )
                
                permissionRow(
                    icon: "bell.badge.fill",
                    title: "Safety Notifications",
                    desc: "Alerts you when thermal pressure is high or battery reaches cutoff floor.",
                    isGranted: true
                )
                
                permissionRow(
                    icon: "battery.100.bolt",
                    title: "IOPS Hardware Sentinel",
                    desc: "Monitors AppleClamshellState and power source changes continuously.",
                    isGranted: true
                )
            }
            .frame(maxWidth: 480)
            
            if let err = installError {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 14) {
                if !helperInstalled {
                    Button(action: installHelper) {
                        HStack(spacing: 6) {
                            if isInstallingHelper {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Image(systemName: "touchid")
                            }
                            Text("Authorize & Install Helper")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isInstallingHelper)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        step = 3
                    }
                }) {
                    Text(helperInstalled ? "Continue →" : "Continue Anyway →")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(helperInstalled ? .black : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(helperInstalled ? Color.green : Color.white.opacity(0.12))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
    }
    
    // MARK: - Step 3: Choose Mode
    private var presentationModeStepView: some View {
        VStack(spacing: 18) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 42))
                .foregroundColor(.green)
            
            VStack(spacing: 6) {
                Text("Choose Presentation Mode")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Select where you would like OpenLid to appear. You can adjust this anytime in Settings.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
            }
            
            VStack(spacing: 10) {
                ForEach(AppPresentationMode.allCases) { mode in
                    Button(action: {
                        preferences.presentationMode = mode
                    }) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(preferences.presentationMode == mode ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
                                    .frame(width: 38, height: 38)
                                Image(systemName: modeIcon(mode))
                                    .foregroundColor(preferences.presentationMode == mode ? .green : .secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text(mode.subtitle)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(white: 0.65))
                            }
                            
                            Spacer()
                            
                            Image(systemName: preferences.presentationMode == mode ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(preferences.presentationMode == mode ? .green : Color.white.opacity(0.25))
                        }
                        .padding(14)
                        .background(preferences.presentationMode == mode ? Color.green.opacity(0.08) : Color.white.opacity(0.03))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(preferences.presentationMode == mode ? Color.green.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 480)
            
            Button(action: {
                preferences.hasCompletedOnboarding = true
                onComplete()
            }) {
                HStack(spacing: 8) {
                    Text("Enter OpenLid")
                        .font(.system(size: 14, weight: .bold))
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                }
                .foregroundColor(.black)
                .frame(maxWidth: 240)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(10)
                .shadow(color: Color.green.opacity(0.4), radius: 10, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Helpers
    private func featureBullet(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 20)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.65))
            }
        }
    }
    
    private func permissionRow(icon: String, title: String, desc: String, isGranted: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isGranted ? .green : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.65))
            }
            
            Spacer()
            
            if isGranted {
                Text("Granted")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
            } else {
                Text("Needed")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
    
    private func modeIcon(_ mode: AppPresentationMode) -> String {
        switch mode {
        case .menuBarOnly: return "menubar.rectangle"
        case .windowedApp: return "macwindow"
        case .both: return "square.split.2x1"
        }
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

