import SwiftUI
import ServiceManagement
import OpenLidCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)? = nil
    
    @ObservedObject var powerManager = PowerManager.shared
    @ObservedObject var preferences = AppPreferences.shared
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var statusBanner: String? = nil
    @State private var isProcessingHelper: Bool = false
    
    private let bgColor = Color(red: 0.047, green: 0.055, blue: 0.071)
    private let cardBg = Color.white.opacity(0.035)
    private let cardBorder = Color.white.opacity(0.075)
    private let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Single unified header aligned with traffic lights
                HStack {
                    Spacer().frame(width: 66)
                    Text("Settings")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                            SettingsWindowManager.shared.closeSettings()
                        }
                    }) {
                        Text("Done")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(emerald)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 12)
                
                Divider().background(Color.white.opacity(0.06))
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Mode
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("APPEARANCE")
                            HStack(spacing: 6) {
                                ForEach(AppPresentationMode.allCases) { mode in
                                    let active = preferences.presentationMode == mode
                                    Button(action: { preferences.presentationMode = mode }) {
                                        Text(shortModeTitle(mode))
                                            .font(.system(size: 12, weight: active ? .semibold : .medium))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(active ? emerald : Color.white.opacity(0.04))
                                            .foregroundColor(active ? .black : Color.white.opacity(0.75))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(active ? Color.clear : cardBorder, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Behavior
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("BEHAVIOR")
                            VStack(spacing: 0) {
                                toggleRow(
                                    title: "Launch at Login",
                                    subtitle: "Start OpenLid automatically when you sign in",
                                    isOn: Binding(
                                        get: { LaunchAtLoginManager.shared.isLaunchAtLoginEnabled },
                                        set: { try? LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: $0) }
                                    )
                                )
                                rowDivider
                                toggleRow(
                                    title: "Auto-Awake on Login",
                                    subtitle: "Enable closed-lid wake mode right at startup",
                                    isOn: Binding(
                                        get: { LaunchAtLoginManager.shared.awakeOnLogin },
                                        set: { LaunchAtLoginManager.shared.awakeOnLogin = $0 }
                                    )
                                )
                                rowDivider
                                toggleRow(
                                    title: "Thermal Protection",
                                    subtitle: "Restore sleep automatically on critical temperatures",
                                    isOn: Binding(
                                        get: { powerManager.thermal.thermalProtectionEnabled },
                                        set: { powerManager.thermal.thermalProtectionEnabled = $0 }
                                    )
                                )
                            }
                            .background(cardBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(cardBorder, lineWidth: 1))
                        }
                        
                        // System
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("SYSTEM")
                            VStack(spacing: 0) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Instant Toggle Helper")
                                            .font(.system(size: 12.5, weight: .medium))
                                            .foregroundColor(.white)
                                        Text(helperInstalled ? "Active — no password prompts" : "Authorize once for instant toggling")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color.white.opacity(0.48))
                                    }
                                    Spacer()
                                    Button(action: toggleHelper) {
                                        Text(isProcessingHelper ? "Working..." : (helperInstalled ? "Remove" : "Enable"))
                                            .font(.system(size: 11.5, weight: .semibold))
                                            .foregroundColor(helperInstalled ? Color.white.opacity(0.85) : .black)
                                            .padding(.horizontal, 11)
                                            .padding(.vertical, 5)
                                            .background(helperInstalled ? Color.white.opacity(0.08) : emerald)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isProcessingHelper)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                
                                rowDivider
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Applications Folder")
                                            .font(.system(size: 12.5, weight: .medium))
                                            .foregroundColor(.white)
                                        Text(ApplicationMover.isInstalledInApplications() ? "Installed in /Applications" : "Running from \(ApplicationMover.currentLocationDescription())")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color.white.opacity(0.48))
                                    }
                                    Spacer()
                                    if ApplicationMover.isInstalledInApplications() {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                            Text("Installed")
                                                .font(.system(size: 11.5, weight: .medium))
                                        }
                                        .foregroundColor(emerald)
                                    } else {
                                        Button("Move") {
                                            MoveToApplicationsWindowManager.shared.showPrompt(force: true)
                                        }
                                        .font(.system(size: 11.5, weight: .semibold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 5)
                                        .background(emerald)
                                        .cornerRadius(6)
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                
                                rowDivider
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Welcome Guide")
                                            .font(.system(size: 12.5, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("Re-open onboarding & permissions setup")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color.white.opacity(0.48))
                                    }
                                    Spacer()
                                    Button("Open") {
                                        AppPreferences.shared.resetOnboarding()
                                        MainWindowManager.shared.showMainWindow()
                                    }
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.85))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(6)
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                            }
                            .background(cardBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(cardBorder, lineWidth: 1))
                        }
                        
                        if let msg = statusBanner {
                            Text(msg)
                                .font(.system(size: 11.5))
                                .foregroundColor(emerald)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack(spacing: 14) {
                            Text("v1.0.0")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.35))
                            Spacer()
                            Link("Website", destination: URL(string: "https://openlid.devs.li")!)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.55))
                            Link("GitHub", destination: URL(string: "https://github.com/PurohitBhagyesh/openlid")!)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.55))
                            Link("Report Issue", destination: URL(string: "mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Support%20(macOS)")!)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(emerald)
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 460, height: 540)
        .preferredColorScheme(.dark)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
        }
    }
    
    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(0.8)
            .foregroundColor(Color.white.opacity(0.40))
    }
    
    private var rowDivider: some View {
        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.leading, 14)
    }
    
    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.48))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
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
        statusBanner = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if helperInstalled {
                    try PrivilegeManager.shared.uninstallHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = false
                        self.statusBanner = "Instant toggle helper removed."
                        self.isProcessingHelper = false
                    }
                } else {
                    try PrivilegeManager.shared.installHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = true
                        self.statusBanner = "Instant toggle helper enabled."
                        self.isProcessingHelper = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusBanner = error.localizedDescription
                    self.isProcessingHelper = false
                }
            }
        }
    }
}
