import SwiftUI
import ServiceManagement
import OpenLidCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)? = nil
    
    @ObservedObject var powerManager = PowerManager.shared
    @ObservedObject var preferences = AppPreferences.shared
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var toastMessage: String? = nil
    @State private var isProcessingHelper: Bool = false
    
    var body: some View {
        ZStack {
            LiquidGlassCanvas()
            
            VStack(spacing: 0) {
                // Single translucent header bar aligned with traffic lights
                HStack {
                    Spacer().frame(width: 64)
                    Text("Settings")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") {
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                            SettingsWindowManager.shared.closeSettings()
                        }
                    }
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 16)
                .frame(height: 48)
                
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Fluid Sliding Display Mode Capsule
                        LiquidSegmentedControl(
                            options: AppPresentationMode.allCases,
                            selection: preferences.presentationMode,
                            height: 36,
                            fontSize: 11.5,
                            label: shortModeTitle
                        ) { mode in
                            preferences.presentationMode = mode
                        }
                        
                        // Switches Card
                        VStack(spacing: 0) {
                            toggleRow("Launch at Login", isOn: Binding(
                                get: { LaunchAtLoginManager.shared.isLaunchAtLoginEnabled },
                                set: { try? LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: $0) }
                            ))
                            rowHairline
                            toggleRow("Auto-Awake on Login", isOn: Binding(
                                get: { LaunchAtLoginManager.shared.awakeOnLogin },
                                set: { LaunchAtLoginManager.shared.awakeOnLogin = $0 }
                            ))
                            rowHairline
                            toggleRow("Thermal Protection", isOn: Binding(
                                get: { powerManager.thermal.thermalProtectionEnabled },
                                set: { powerManager.thermal.thermalProtectionEnabled = $0 }
                            ))
                        }
                        .liquidGlassCard(cornerRadius: 14, elevated: false)
                        
                        // System Actions Card
                        VStack(spacing: 0) {
                            HStack {
                                Text("Instant Toggle Helper")
                                    .font(.system(size: 12.5))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: toggleHelper) {
                                    Text(isProcessingHelper ? "Working..." : (helperInstalled ? "Remove" : "Enable"))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(helperInstalled ? Color.white.opacity(0.82) : .black)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(helperInstalled ? Color.white.opacity(0.09) : Color.white)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(helperInstalled ? Color.white.opacity(0.14) : Color.clear, lineWidth: 0.75)
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(isProcessingHelper)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            
                            rowHairline
                            
                            HStack {
                                Text("Applications")
                                    .font(.system(size: 12.5))
                                    .foregroundColor(.white)
                                Spacer()
                                if ApplicationMover.isInstalledInApplications() {
                                    Text("Installed")
                                        .font(.system(size: 11.5))
                                        .foregroundColor(Color.white.opacity(0.45))
                                } else {
                                    Button("Move") {
                                        MoveToApplicationsWindowManager.shared.showPrompt(force: true)
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            
                            rowHairline
                            
                            HStack {
                                Text("Welcome Guide")
                                    .font(.system(size: 12.5))
                                    .foregroundColor(.white)
                                Spacer()
                                Button("Show") {
                                    AppPreferences.shared.resetOnboarding()
                                    MainWindowManager.shared.showMainWindow()
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.82))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.09))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.75))
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                        }
                        .liquidGlassCard(cornerRadius: 14, elevated: false)
                        
                        if let msg = toastMessage {
                            Text(msg)
                                .font(.system(size: 11.5))
                                .foregroundColor(Color.white.opacity(0.75))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }
                        
                        HStack(spacing: 14) {
                            Text("v1.0.0")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.32))
                            Spacer()
                            Link("Website", destination: URL(string: "https://openlid.devs.li")!)
                                .font(.system(size: 11.5))
                                .foregroundColor(Color.white.opacity(0.55))
                            Link("GitHub", destination: URL(string: "https://github.com/PurohitBhagyesh/openlid")!)
                                .font(.system(size: 11.5))
                                .foregroundColor(Color.white.opacity(0.55))
                            Link("Support", destination: URL(string: "mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Support%20(macOS)")!)
                                .font(.system(size: 11.5))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 420, height: 440)
        .preferredColorScheme(.dark)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
        }
    }
    
    private var rowHairline: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 14)
    }
    
    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12.5))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(.white)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
    }
    
    private func shortModeTitle(_ mode: AppPresentationMode) -> String {
        switch mode {
        case .menuBarOnly: return "Menu Bar"
        case .windowedApp: return "Window"
        case .both: return "Both"
        }
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
                        self.toastMessage = "Helper removed"
                        self.isProcessingHelper = false
                    }
                } else {
                    try PrivilegeManager.shared.installHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = true
                        self.toastMessage = "Instant toggle enabled"
                        self.isProcessingHelper = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.toastMessage = error.localizedDescription
                    self.isProcessingHelper = false
                }
            }
        }
    }
}
