import SwiftUI
import OpenLidCore

public struct MainWindowView: View {
    @ObservedObject var powerManager = PowerManager.shared
    @ObservedObject var preferences = AppPreferences.shared
    @State private var selectedTab: MainTab = .overview
    @State private var showOnboarding: Bool = false
    
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var isProcessingHelper: Bool = false
    @State private var statusBanner: String? = nil
    @State private var isRefreshingHardware: Bool = false
    @State private var isResettingAssertions: Bool = false
    
    public enum MainTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case settings = "Settings"
        public var id: String { rawValue }
    }
    
    private let bgColor = Color(red: 0.047, green: 0.055, blue: 0.071)
    private let cardBg = Color.white.opacity(0.035)
    private let cardBorder = Color.white.opacity(0.075)
    private let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)
    
    public init() {}
    
    public var body: some View {
        Group {
            if !preferences.hasCompletedOnboarding || showOnboarding {
                OnboardingView(onComplete: {
                    preferences.hasCompletedOnboarding = true
                    showOnboarding = false
                    selectedTab = .overview
                })
            } else {
                mainAppContent
            }
        }
        .frame(width: 480, height: 560)
        .preferredColorScheme(.dark)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
            refreshHardwareMonitors()
        }
    }
    
    private var mainAppContent: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            // Subtle ambient radial glow when active
            RadialGradient(
                gradient: Gradient(colors: [
                    emerald.opacity(powerManager.isEnabled ? 0.14 : 0.0),
                    Color.clear
                ]),
                center: .top,
                startRadius: 10,
                endRadius: 300
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.45), value: powerManager.isEnabled)
            
            VStack(spacing: 0) {
                // Single unified top bar aligned with window traffic lights
                HStack(spacing: 10) {
                    Spacer().frame(width: 66)
                    
                    HStack(spacing: 7) {
                        Circle()
                            .fill(powerManager.isEnabled ? emerald : Color.white.opacity(0.25))
                            .frame(width: 7, height: 7)
                        Text("OpenLid")
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Minimal pill tab switcher
                    HStack(spacing: 2) {
                        ForEach(MainTab.allCases) { tab in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 11.5, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? .white : Color.white.opacity(0.55))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(selectedTab == tab ? Color.white.opacity(0.11) : Color.clear)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(cardBorder, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 12)
                
                Divider().background(Color.white.opacity(0.06))
                
                if selectedTab == .overview {
                    overviewTab
                } else {
                    settingsTab
                }
            }
        }
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        VStack(spacing: 16) {
            // Optional slim relocation pill
            if !ApplicationMover.isInstalledInApplications() && !ApplicationMover.isDevOrBuildEnvironment() {
                HStack(spacing: 10) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(emerald)
                    Text("Running from \(ApplicationMover.currentLocationDescription())")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.85))
                    Spacer()
                    Button("Move to Applications") {
                        MoveToApplicationsWindowManager.shared.showPrompt(force: true)
                    }
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(emerald)
                    .cornerRadius(6)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(emerald.opacity(0.08))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(emerald.opacity(0.24), lineWidth: 1)
                )
            }
            
            // Clean Hero Focus Card
            VStack(spacing: 16) {
                AnimatedEyeView(size: 72, isAwake: powerManager.isEnabled, isScanning: powerManager.isEnabled)
                    .padding(.top, 6)
                
                VStack(spacing: 5) {
                    Text(powerManager.isEnabled ? "Mac is Awake" : "Normal Sleep")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(powerManager.isEnabled ? "Stays running cleanly when the lid closes." : "Sleep prevention is off. Lid closes normally.")
                        .font(.system(size: 12.5))
                        .foregroundColor(Color.white.opacity(0.55))
                }
                
                // Live session timer badge when active
                if powerManager.isEnabled {
                    HStack(spacing: 8) {
                        if powerManager.timer.isTimerRunning {
                            Image(systemName: "timer")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                            Text(powerManager.timer.formattedRemainingTime)
                                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                            Button("Clear") {
                                powerManager.selectPreset(.indefinite)
                            }
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.65))
                            .buttonStyle(.plain)
                        } else {
                            Circle()
                                .fill(emerald)
                                .frame(width: 6, height: 6)
                            Text(powerManager.timer.formattedElapsedTime)
                                .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(red: 0.45, green: 0.90, blue: 0.72))
                            Text("• Always")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.45))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                
                // Primary Tactile Toggle Button
                Button(action: {
                    powerManager.toggle(preset: powerManager.selectedPreset)
                }) {
                    HStack(spacing: 8) {
                        if powerManager.isBusy {
                            ProgressView()
                                .scaleEffect(0.6)
                                .colorInvert()
                            Text("Updating...")
                                .font(.system(size: 13.5, weight: .semibold))
                        } else {
                            Image(systemName: powerManager.isEnabled ? "moon.zzz.fill" : "bolt.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text(powerManager.isEnabled ? "Restore Normal Sleep" : "Keep Awake")
                                .font(.system(size: 13.5, weight: .bold))
                        }
                    }
                    .foregroundColor(powerManager.isEnabled ? .white : .black)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 10)
                    .background(
                        powerManager.isEnabled
                            ? Color.white.opacity(0.10)
                            : emerald
                    )
                    .cornerRadius(9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(powerManager.isEnabled ? Color.white.opacity(0.14) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(powerManager.isBusy)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(cardBg)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(powerManager.isEnabled ? emerald.opacity(0.28) : cardBorder, lineWidth: 1)
            )
            
            // Compact Session Duration Bar
            VStack(alignment: .leading, spacing: 8) {
                Text("DURATION")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundColor(Color.white.opacity(0.40))
                
                HStack(spacing: 6) {
                    ForEach(SessionPreset.allCases) { preset in
                        let selected = powerManager.selectedPreset == preset
                        Button(action: {
                            powerManager.selectPreset(preset)
                        }) {
                            Text(shortLabel(preset))
                                .font(.system(size: 12, weight: selected ? .bold : .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selected ? emerald : Color.white.opacity(0.04))
                                .foregroundColor(selected ? .black : Color.white.opacity(0.78))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selected ? Color.clear : cardBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Clean 3-Stat Telemetry Strip
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("TELEMETRY")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(Color.white.opacity(0.40))
                    Spacer()
                    Button(action: refreshHardwareMonitors) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.45))
                            .rotationEffect(.degrees(isRefreshingHardware ? 360 : 0))
                            .animation(isRefreshingHardware ? .linear(duration: 0.6).repeatForever(autoreverses: false) : .default, value: isRefreshingHardware)
                    }
                    .buttonStyle(.plain)
                    .help("Refresh hardware monitors")
                }
                
                HStack(spacing: 0) {
                    statColumn(
                        icon: powerManager.clamshell.isLidClosed ? "laptopcomputer.and.arrow.down" : "laptopcomputer",
                        label: "Lid",
                        value: powerManager.clamshell.isLidClosed ? "Closed" : "Open",
                        tint: powerManager.clamshell.isLidClosed ? .orange : emerald
                    )
                    Divider().frame(height: 32).background(Color.white.opacity(0.07))
                    statColumn(
                        icon: powerManager.battery.isOnACPower ? "bolt.fill" : "battery.75",
                        label: powerManager.battery.isOnACPower ? "AC Power" : "Battery",
                        value: "\(powerManager.battery.batteryPercent)%",
                        tint: powerManager.battery.batteryPercent < 20 ? .red : emerald
                    )
                    Divider().frame(height: 32).background(Color.white.opacity(0.07))
                    statColumn(
                        icon: "thermometer.medium",
                        label: "Thermal",
                        value: shortThermal(powerManager.thermal.thermalState),
                        tint: powerManager.thermal.isDangerous ? .red : emerald
                    )
                }
                .padding(.vertical, 12)
                .background(cardBg)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cardBorder, lineWidth: 1)
                )
            }
            
            // Optional inline error / stop reason notice
            if let notice = powerManager.lastError ?? powerManager.stopReason {
                let isErr = powerManager.lastError != nil
                HStack(spacing: 8) {
                    Image(systemName: isErr ? "exclamationmark.circle.fill" : "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isErr ? .red : .orange)
                    Text(notice)
                        .font(.system(size: 11.5))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(2)
                    Spacer()
                    Button(action: {
                        powerManager.lastError = nil
                        powerManager.stopReason = nil
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background((isErr ? Color.red : Color.orange).opacity(0.10))
                .cornerRadius(8)
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
    }
    
    // MARK: - Settings Tab
    private var settingsTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Presentation Mode
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
                
                // Behavior Toggles
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
                
                // System Rows
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("SYSTEM")
                    VStack(spacing: 0) {
                        actionRow(
                            title: "Instant Toggle Helper",
                            subtitle: helperInstalled ? "Active — no password prompts" : "Authorize once for instant toggling",
                            buttonTitle: isProcessingHelper ? "Working..." : (helperInstalled ? "Remove" : "Enable"),
                            accent: !helperInstalled,
                            disabled: isProcessingHelper,
                            action: toggleHelper
                        )
                        rowDivider
                        actionRow(
                            title: "Reset Power Assertions",
                            subtitle: "Restore default macOS sleep settings",
                            buttonTitle: isResettingAssertions ? "Resetting..." : "Reset",
                            accent: false,
                            disabled: isResettingAssertions,
                            action: resetSystemAssertions
                        )
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
                        actionRow(
                            title: "Welcome Guide",
                            subtitle: "Re-open onboarding & permissions setup",
                            buttonTitle: "Open",
                            accent: false,
                            disabled: false,
                            action: { showOnboarding = true }
                        )
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
                
                // Minimal Footer Links
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
    
    // MARK: - Components
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
    
    private func statColumn(icon: String, label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(tint)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.48))
            }
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
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
    
    private func actionRow(title: String, subtitle: String, buttonTitle: String, accent: Bool, disabled: Bool, action: @escaping () -> Void) -> some View {
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
            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(accent ? .black : Color.white.opacity(0.85))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(accent ? emerald : Color.white.opacity(0.08))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
    
    private func shortLabel(_ preset: SessionPreset) -> String {
        switch preset {
        case .indefinite: return "Always"
        case .min15: return "15m"
        case .min30: return "30m"
        case .hour1: return "1h"
        case .hour2: return "2h"
        }
    }
    
    private func shortModeTitle(_ mode: AppPresentationMode) -> String {
        switch mode {
        case .menuBarOnly: return "Menu Bar"
        case .windowedApp: return "Window"
        case .both: return "Both"
        }
    }
    
    private func shortThermal(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Warm"
        case .critical: return "Hot"
        @unknown default: return "OK"
        }
    }
    
    // MARK: - Actions
    private func refreshHardwareMonitors() {
        isRefreshingHardware = true
        DispatchQueue.global(qos: .userInitiated).async {
            self.powerManager.clamshell.updateLidState()
            self.powerManager.battery.updateBatteryState()
            self.powerManager.thermal.updateThermalState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.isRefreshingHardware = false
            }
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
    
    private func resetSystemAssertions() {
        isResettingAssertions = true
        statusBanner = nil
        DispatchQueue.global(qos: .userInitiated).async {
            self.powerManager.disable(reason: nil)
            try? PrivilegeManager.shared.setDisableSleep(enabled: false)
            DispatchQueue.main.async {
                self.isResettingAssertions = false
                self.statusBanner = "System sleep settings restored to default."
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.statusBanner = nil
                }
            }
        }
    }
}
