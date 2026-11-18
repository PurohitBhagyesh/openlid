import SwiftUI
import ServiceManagement
import OpenLidCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)? = nil
    
    @ObservedObject var powerManager = PowerManager.shared
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var toastMessage: String? = nil
    @State private var isProcessingHelper: Bool = false
    
    var body: some View {
        ZStack {
            LiquidGlassCanvas()
            
            VStack(spacing: 0) {
                // Titlebar sitting directly on the traffic-light row (ZERO extra forehead)
                ZStack {
                    Text("Settings")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.88))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
                
                VStack(spacing: 10) {
                    // Toggles Glass Card
                    VStack(spacing: 0) {
                        toggleRow(
                            icon: "arrow.up.right.circle",
                            title: "Launch at Login",
                            isOn: Binding(
                                get: { LaunchAtLoginManager.shared.isLaunchAtLoginEnabled },
                                set: { try? LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: $0) }
                            )
                        )
                        rowHairline
                        toggleRow(
                            icon: "bolt",
                            title: "Auto-Awake on Login",
                            isOn: Binding(
                                get: { LaunchAtLoginManager.shared.awakeOnLogin },
                                set: { LaunchAtLoginManager.shared.awakeOnLogin = $0 }
                            )
                        )
                        rowHairline
                        toggleRow(
                            icon: "thermometer.medium",
                            title: "Thermal Protection",
                            isOn: Binding(
                                get: { powerManager.thermal.thermalProtectionEnabled },
                                set: { powerManager.thermal.thermalProtectionEnabled = $0 }
                            )
                        )
                    }
                    .liquidGlassCard(cornerRadius: 12, elevated: false)
                    
                    // System Actions Glass Card
                    VStack(spacing: 0) {
                        HStack(spacing: 9) {
                            rowIcon("lock.open")
                            Text("Instant Toggle Helper")
                                .font(.system(size: 12.5))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: toggleHelper) {
                                Text(isProcessingHelper ? "Working..." : (helperInstalled ? "Remove" : "Enable"))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(helperInstalled ? Color.white.opacity(0.82) : .black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 3.5)
                                    .background(helperInstalled ? Color.white.opacity(0.10) : Color.white)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(helperInstalled ? Color.white.opacity(0.16) : Color.clear, lineWidth: 0.75)
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(isProcessingHelper)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        
                        rowHairline
                        
                        HStack(spacing: 9) {
                            rowIcon("folder")
                            Text("Applications")
                                .font(.system(size: 12.5))
                                .foregroundColor(.white)
                            Spacer()
                            if ApplicationMover.isInstalledInApplications() {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9.5, weight: .semibold))
                                    Text("Installed")
                                        .font(.system(size: 11))
                                }
                                .foregroundColor(Color.white.opacity(0.48))
                            } else {
                                Button("Move") {
                                    MoveToApplicationsWindowManager.shared.showPrompt(force: true)
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3.5)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        
                        rowHairline
                        
                        HStack(spacing: 9) {
                            rowIcon("sparkles")
                            Text("Welcome Guide")
                                .font(.system(size: 12.5))
                                .foregroundColor(.white)
                            Spacer()
                            Button("Show") {
                                AppPreferences.shared.resetOnboarding()
                                MainWindowManager.shared.showMainWindow()
                                if let onDismiss = onDismiss {
                                    onDismiss()
                                } else {
                                    dismiss()
                                    SettingsWindowManager.shared.closeSettings()
                                }
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.84))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3.5)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 0.75))
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                    }
                    .liquidGlassCard(cornerRadius: 12, elevated: false)
                    
                    // Quiet Footer Row
                    HStack(spacing: 12) {
                        Text("v1.0.0")
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.32))
                        Spacer()
                        Link("Website", destination: URL(string: "https://openlid.devs.li")!)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.54))
                        Link("GitHub", destination: URL(string: "https://github.com/PurohitBhagyesh/openlid")!)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.54))
                        Link("Support", destination: URL(string: "mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Support%20(macOS)")!)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.86))
                    }
                    .frame(height: 18)
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 14)
            }
            .ignoresSafeArea(.container, edges: .top)
            
            // Non-shifting floating toast if needed
            if let msg = toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .liquidGlassCard(cornerRadius: 8, elevated: true)
                        .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(width: 360, height: 318)
        .preferredColorScheme(.dark)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
        }
    }
    
    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(Color.white.opacity(0.52))
            .frame(width: 16, alignment: .center)
    }
    
    private var rowHairline: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 37)
    }
    
    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 9) {
            rowIcon(icon)
            Text(title)
                .font(.system(size: 12.5))
                .foregroundColor(.white)
            Spacer()
            LiquidToggle(isOn: isOn)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }
    
    private func toggleHelper() {
        isProcessingHelper = true
        toastMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if helperInstalled {
                    try PrivilegeManager.shared.uninstallHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = false
                        self.showToast("Helper removed")
                        self.isProcessingHelper = false
                    }
                } else {
                    try PrivilegeManager.shared.installHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = true
                        self.showToast("Instant toggle enabled")
                        self.isProcessingHelper = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showToast(error.localizedDescription)
                    self.isProcessingHelper = false
                }
            }
        }
    }
    
    private func showToast(_ msg: String) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            toastMessage = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                if toastMessage == msg { toastMessage = nil }
            }
        }
    }
}
