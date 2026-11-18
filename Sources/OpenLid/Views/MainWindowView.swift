import SwiftUI
import OpenLidCore

public struct MainWindowView: View {
    @ObservedObject var powerManager = PowerManager.shared
    @ObservedObject var preferences = AppPreferences.shared
    @State private var selectedTab: MainTab = .home
    @State private var showOnboarding: Bool = false
    
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var isProcessingHelper: Bool = false
    @State private var toastMessage: String? = nil
    @State private var isRefreshingHardware: Bool = false
    @State private var isResettingAssertions: Bool = false
    
    public enum MainTab: String, CaseIterable, Identifiable {
        case home = "Home"
        case settings = "Settings"
        public var id: String { rawValue }
    }
    
    public init() {}
    
    public var body: some View {
        Group {
            if !preferences.hasCompletedOnboarding || showOnboarding {
                OnboardingView(onComplete: {
                    preferences.hasCompletedOnboarding = true
                    showOnboarding = false
                    selectedTab = .home
                })
            } else {
                mainAppContent
            }
        }
        .frame(width: 420, height: 440)
        .preferredColorScheme(.dark)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
            refreshHardwareMonitors()
        }
    }
    
    private var mainAppContent: some View {
        ZStack {
            LiquidGlassCanvas()
            
            VStack(spacing: 0) {
                // Single unified translucent top bar aligned with traffic lights
                HStack(spacing: 8) {
                    Spacer().frame(width: 64)
                    
                    Text("OpenLid")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !ApplicationMover.isInstalledInApplications() && !ApplicationMover.isDevOrBuildEnvironment() {
                        Button("Install") {
                            MoveToApplicationsWindowManager.shared.showPrompt(force: true)
                        }
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // Minimal Liquid Glass segmented tab bar
                    HStack(spacing: 2) {
                        ForEach(MainTab.allCases) { tab in
                            let active = selectedTab == tab
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.16)) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 11.5, weight: active ? .semibold : .regular))
                                    .foregroundColor(active ? .black : Color.white.opacity(0.62))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 4)
                                    .background(active ? Color.white : Color.clear)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(2.5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.75)
                    )
                }
                .padding(.horizontal, 16)
                .frame(height: 48)
                
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
                
                if selectedTab == .home {
                    homeTab
                } else {
                    settingsTab
                }
            }
            
            // Non-shifting floating glass toast for errors / notices
            if let notice = powerManager.lastError ?? powerManager.stopReason ?? toastMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Text(notice)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        Spacer(minLength: 4)
                        Button(action: {
                            powerManager.lastError = nil
                            powerManager.stopReason = nil
                            toastMessage = nil
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .liquidGlassCard(cornerRadius: 10, elevated: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
    
    // MARK: - Home Tab (Zero layout shift, zero dead gap)
    private var homeTab: some View {
        VStack(spacing: 12) {
            // Hero Liquid Glass Stage (fills cleanly, fixed internal heights so ON/OFF never shifts)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                AnimatedEyeView(size: 64, isAwake: powerManager.isEnabled, isScanning: powerManager.isEnabled)
                
                Spacer().frame(height: 16)
                
                Text(powerManager.isEnabled ? "Awake" : "Standby")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(height: 26)
                
                Spacer().frame(height: 4)
                
                // Fixed-height 20pt subtitle/timer line -> ZERO jump on toggle
                HStack(spacing: 6) {
                    if powerManager.isEnabled {
                        if powerManager.timer.isTimerRunning {
                            Text(powerManager.timer.formattedRemainingTime)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.85))
                            Text("remaining")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.45))
                            Button("Clear") {
                                powerManager.selectPreset(.indefinite)
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.65))
                            .buttonStyle(.plain)
                        } else {
                            Text(powerManager.timer.formattedElapsedTime)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.80))
                            Text("·")
                                .foregroundColor(Color.white.opacity(0.35))
                            Text("Lid sleep disabled")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.48))
                        }
                    } else {
                        Text("Normal macOS sleep behavior")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.42))
                    }
                }
                .frame(height: 20)
                
                Spacer().frame(height: 18)
                
                // Monochrome Primary Action Pill (fixed 38pt height)
                Button(action: {
                    powerManager.toggle(preset: powerManager.selectedPreset)
                }) {
                    HStack(spacing: 7) {
                        if powerManager.isBusy {
                            ProgressView()
                                .scaleEffect(0.58)
                                .colorInvert()
                            Text("Updating")
                                .font(.system(size: 13, weight: .medium))
                        } else {
                            Text(powerManager.isEnabled ? "Restore Sleep" : "Keep Awake")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundColor(powerManager.isEnabled ? .white : .black)
                    .frame(width: 196, height: 38)
                    .background(
                        Capsule()
                            .fill(powerManager.isEnabled ? Color.white.opacity(0.11) : Color.white)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                powerManager.isEnabled ? Color.white.opacity(0.24) : Color.clear,
                                lineWidth: 0.75
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(powerManager.isBusy)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .liquidGlassCard(cornerRadius: 16, elevated: powerManager.isEnabled)
            
            // Duration Segmented Liquid Glass Capsule (fixed 38pt height)
            HStack(spacing: 3) {
                ForEach(SessionPreset.allCases) { preset in
                    let selected = powerManager.selectedPreset == preset
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            powerManager.selectPreset(preset)
                        }
                    }) {
                        Text(shortLabel(preset))
                            .font(.system(size: 11.5, weight: selected ? .semibold : .regular))
                            .foregroundColor(selected ? .black : Color.white.opacity(0.64))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(selected ? Color.white : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .frame(height: 38)
            .liquidGlassCard(cornerRadius: 19, elevated: false)
            
            // Minimal 3-Column Monochrome Telemetry Bar (fixed 54pt height)
            HStack(spacing: 0) {
                statCell(label: "Lid", value: powerManager.clamshell.isLidClosed ? "Closed" : "Open")
                glassDivider
                statCell(label: powerManager.battery.isOnACPower ? "AC" : "Battery", value: "\(powerManager.battery.batteryPercent)%")
                glassDivider
                statCell(label: "Thermal", value: shortThermal(powerManager.thermal.thermalState))
                glassDivider
                Button(action: refreshHardwareMonitors) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.55))
                        .rotationEffect(.degrees(isRefreshingHardware ? 360 : 0))
                        .animation(isRefreshingHardware ? .linear(duration: 0.6).repeatForever(autoreverses: false) : .default, value: isRefreshingHardware)
                        .frame(width: 40, height: 54)
                }
                .buttonStyle(.plain)
                .help("Refresh hardware monitors")
            }
            .frame(height: 54)
            .liquidGlassCard(cornerRadius: 14, elevated: false)
        }
        .padding(16)
    }
    
    // MARK: - Settings Tab (Pure monochrome Liquid Glass rows)
    private var settingsTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                // Display Mode Capsule
                HStack(spacing: 3) {
                    ForEach(AppPresentationMode.allCases) { mode in
                        let active = preferences.presentationMode == mode
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                preferences.presentationMode = mode
                            }
                        }) {
                            Text(shortModeTitle(mode))
                                .font(.system(size: 11.5, weight: active ? .semibold : .regular))
                                .foregroundColor(active ? .black : Color.white.opacity(0.64))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(active ? Color.white : Color.clear)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .frame(height: 36)
                .liquidGlassCard(cornerRadius: 18, elevated: false)
                
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
                    actionRow(
                        title: "Instant Toggle Helper",
                        trailing: isProcessingHelper ? "Working..." : (helperInstalled ? "Remove" : "Enable"),
                        primary: !helperInstalled,
                        disabled: isProcessingHelper,
                        action: toggleHelper
                    )
                    rowHairline
                    actionRow(
                        title: "Reset Sleep Settings",
                        trailing: isResettingAssertions ? "Resetting..." : "Reset",
                        primary: false,
                        disabled: isResettingAssertions,
                        action: resetSystemAssertions
                    )
                    rowHairline
                    HStack {
                        Text("Applications")
                            .font(.system(size: 12.5, weight: .regular))
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
                    actionRow(
                        title: "Welcome Guide",
                        trailing: "Show",
                        primary: false,
                        disabled: false,
                        action: { showOnboarding = true }
                    )
                }
                .liquidGlassCard(cornerRadius: 14, elevated: false)
                
                // Quiet Monochrome Footer
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
    
    // MARK: - Components
    private var glassDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 0.75, height: 24)
    }
    
    private var rowHairline: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 14)
    }
    
    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10.5))
                .foregroundColor(Color.white.opacity(0.42))
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12.5, weight: .regular))
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
    
    private func actionRow(title: String, trailing: String, primary: Bool, disabled: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundColor(.white)
            Spacer()
            Button(action: action) {
                Text(trailing)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(primary ? .black : Color.white.opacity(0.82))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(primary ? Color.white : Color.white.opacity(0.09))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(primary ? Color.clear : Color.white.opacity(0.14), lineWidth: 0.75)
                    )
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
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
        toastMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if helperInstalled {
                    try PrivilegeManager.shared.uninstallHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = false
                        self.showTransientToast("Helper removed")
                        self.isProcessingHelper = false
                    }
                } else {
                    try PrivilegeManager.shared.installHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = true
                        self.showTransientToast("Instant toggle enabled")
                        self.isProcessingHelper = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showTransientToast(error.localizedDescription)
                    self.isProcessingHelper = false
                }
            }
        }
    }
    
    private func resetSystemAssertions() {
        isResettingAssertions = true
        toastMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            self.powerManager.disable(reason: nil)
            try? PrivilegeManager.shared.setDisableSleep(enabled: false)
            DispatchQueue.main.async {
                self.isResettingAssertions = false
                self.showTransientToast("Sleep settings restored")
            }
        }
    }
    
    private func showTransientToast(_ message: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if toastMessage == message { toastMessage = nil }
            }
        }
    }
}
