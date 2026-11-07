import SwiftUI
import OpenLidCore

public struct MainWindowView: View {
    @ObservedObject var powerManager = PowerManager.shared
    @ObservedObject var preferences = AppPreferences.shared
    @State private var selectedTab: MainTab = .dashboard
    @State private var selectedPreset: SessionPreset = .indefinite
    @State private var showOnboarding: Bool = false
    
    // Controls Tab states
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var isProcessingHelper: Bool = false
    @State private var helperMessage: String? = nil
    @State private var isRefreshingHardware: Bool = false
    @State private var hardwareRefreshedJustNow: Bool = false
    @State private var isResettingAssertions: Bool = false
    @State private var resetMessage: String? = nil
    @State private var activeAssertionsText: String? = nil
    @State private var isInspectingAssertions: Bool = false
    
    public enum MainTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case controls = "Controls"
        case settings = "Settings"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .dashboard: return "waveform.path.ecg"
            case .controls: return "wrench.and.screwdriver"
            case .settings: return "gearshape"
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        Group {
            if !preferences.hasCompletedOnboarding || showOnboarding {
                OnboardingView(onComplete: {
                    preferences.hasCompletedOnboarding = true
                    showOnboarding = false
                    selectedTab = .dashboard
                })
            } else {
                mainAppContent
            }
        }
        .frame(width: 580, height: 680)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
            refreshHardwareMonitors()
        }
    }
    
    private var mainAppContent: some View {
        VStack(spacing: 0) {
            // App Navigation Header
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    AnimatedEyeView(size: 28, isAwake: powerManager.isEnabled, isScanning: powerManager.isEnabled)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("OpenLid")
                                .font(.system(size: 15, weight: .bold))
                            Text("v1.0.0")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(4)
                        }
                        Text(powerManager.isEnabled ? "Awake & Vigilant (Clamshell Override)" : "Normal Sleep Allowed")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Tabs Picker
                Picker("", selection: $selectedTab) {
                    ForEach(MainTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Tab Content
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .dashboard:
                        dashboardView
                    case .controls:
                        controlsView
                    case .settings:
                        settingsEmbeddedView
                    }
                }
                .padding(20)
            }
        }
        .background(Color(NSColor.underPageBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Dashboard Tab
    private var dashboardView: some View {
        VStack(spacing: 16) {
            // Hero Toggle Card
            Button(action: {
                powerManager.toggle(preset: selectedPreset)
            }) {
                HStack(spacing: 18) {
                    AnimatedEyeView(size: 64, isAwake: powerManager.isEnabled, isScanning: powerManager.isEnabled)
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(powerManager.isEnabled ? "Mac is Awake (Eye Vigilant)" : "Keep Awake with Lid Closed")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(powerManager.isEnabled ? "AWAKE" : "ASLEEP")
                                .font(.system(size: 10, weight: .heavy))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(powerManager.isEnabled ? Color.green.opacity(0.2) : Color.secondary.opacity(0.15))
                                .foregroundColor(powerManager.isEnabled ? .green : .secondary)
                                .clipShape(Capsule())
                        }
                        
                        Text(powerManager.isEnabled ? "Mac continues running even if lid is closed. Display sleeps naturally." : "Click to enable clamshell sleep bypass mode.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Image(systemName: powerManager.isEnabled ? "power.circle.fill" : "power.circle")
                        .font(.system(size: 32))
                        .foregroundColor(powerManager.isEnabled ? .green : .secondary)
                }
                .padding(18)
                .background(powerManager.isEnabled ? Color.green.opacity(0.08) : Color.secondary.opacity(0.06))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(powerManager.isEnabled ? Color.green.opacity(0.35) : Color.secondary.opacity(0.12), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            
            // Real-Time Live Timer Card (Always updates every second)
            if powerManager.isEnabled {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(powerManager.timer.isTimerRunning ? Color.orange.opacity(0.18) : Color.green.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: powerManager.timer.isTimerRunning ? "timer" : "clock.arrow.circlepath")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(powerManager.timer.isTimerRunning ? .orange : .green)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(powerManager.timer.isTimerRunning ? "Session Countdown (Real-Time)" : "Active Vigilant Session (Real-Time)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text(powerManager.timer.isTimerRunning ? "Time Remaining:" : "Elapsed Awake Time:")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            
                            Text(powerManager.timer.isTimerRunning ? powerManager.timer.formattedRemainingTime : powerManager.timer.formattedElapsedTime)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(powerManager.timer.isTimerRunning ? .orange : .green)
                        }
                    }
                    
                    Spacer()
                    
                    if powerManager.timer.isTimerRunning {
                        Button("Stop Timer") {
                            powerManager.timer.stop()
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Text("Continuous")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(6)
                    }
                }
                .padding(14)
                .background(powerManager.timer.isTimerRunning ? Color.orange.opacity(0.08) : Color.green.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(powerManager.timer.isTimerRunning ? Color.orange.opacity(0.3) : Color.green.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Session Timer Presets
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Session Duration")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    if powerManager.isEnabled && powerManager.timer.isTimerRunning {
                        Text("Live: \(powerManager.timer.formattedRemainingTime)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                
                HStack(spacing: 8) {
                    ForEach(SessionPreset.allCases) { preset in
                        Button(action: {
                            selectedPreset = preset
                            if powerManager.isEnabled {
                                powerManager.timer.start(preset: preset)
                            }
                        }) {
                            Text(preset.title)
                                .font(.system(size: 12, weight: selectedPreset == preset ? .bold : .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedPreset == preset ? Color.green : Color.secondary.opacity(0.1))
                                .foregroundColor(selectedPreset == preset ? .black : .primary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.04))
            .cornerRadius(10)
            
            // Telemetry Grid with Hardware Refresh
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Live System Telemetry")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: refreshHardwareMonitors) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10, weight: .bold))
                                .rotationEffect(.degrees(isRefreshingHardware ? 360 : 0))
                                .animation(isRefreshingHardware ? Animation.linear(duration: 0.6).repeatForever(autoreverses: false) : .default, value: isRefreshingHardware)
                            Text(hardwareRefreshedJustNow ? "Synced Just Now" : "Refresh Hardware")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(hardwareRefreshedJustNow ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    telemetryCard(
                        icon: powerManager.clamshell.isLidClosed ? "laptopcomputer.and.arrow.down" : "laptopcomputer",
                        title: "Lid State",
                        value: powerManager.clamshell.isLidClosed ? "Lid Closed" : "Lid Open",
                        color: powerManager.clamshell.isLidClosed ? .orange : .green
                    )
                    
                    telemetryCard(
                        icon: powerManager.battery.isCharging ? "bolt.batteryblock.fill" : (powerManager.battery.isOnACPower ? "powerplug.fill" : "battery.100"),
                        title: "Battery Level",
                        value: "\(powerManager.battery.batteryPercent)% \(powerManager.battery.isOnACPower ? "(AC)" : "(Batt)")",
                        color: powerManager.battery.batteryPercent < 20 ? .red : .green
                    )
                    
                    telemetryCard(
                        icon: "thermometer.medium",
                        title: "Thermal Pressure",
                        value: powerManager.thermal.stateDescription,
                        color: powerManager.thermal.thermalState == .critical ? .red : .green
                    )
                    
                    telemetryCard(
                        icon: helperInstalled ? "bolt.shield.fill" : "lock.badge.clock",
                        title: "Toggle Helper",
                        value: helperInstalled ? "Active (Instant)" : "Standard (Prompt)",
                        color: helperInstalled ? .green : .orange
                    )
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.04))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Controls Tab (Expanded with Hardware & Safety Controls)
    private var controlsView: some View {
        VStack(spacing: 14) {
            // Instant Toggle Helper Control
            actionCard(
                icon: "bolt.badge.clock",
                title: "Instant Toggle Helper",
                desc: helperInstalled ? "Helper is active in /etc/sudoers.d/openlid. Toggles occur instantly with 0ms delay." : "Authorize once via Touch ID / admin password to enable instantaneous toggling without popups.",
                actionTitle: helperInstalled ? "Uninstall Helper" : "Install Helper"
            ) {
                toggleHelper()
            }
            
            if let msg = helperMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            
            // Refresh Hardware Monitor Action
            actionCard(
                icon: "arrow.clockwise",
                title: "Refresh Hardware Monitors",
                desc: "Queries IOKit, AppleClamshellState, and IOPS power source registers immediately.",
                actionTitle: hardwareRefreshedJustNow ? "Refreshed ✓" : "Sync Now"
            ) {
                refreshHardwareMonitors()
            }
            
            // Reset System Power Assertions
            actionCard(
                icon: "arrow.counterclockwise.circle",
                title: "Reset System Power Assertions",
                desc: "Executes 'pmset -a disablesleep 0' and flushes any stuck or orphaned background sleep assertions.",
                actionTitle: isResettingAssertions ? "Resetting..." : "Reset to Default"
            ) {
                resetSystemAssertions()
            }
            
            if let msg = resetMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            
            // Live Assertions Inspector
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "gauge.badge.plus")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Live Power Assertions Inspector")
                                .font(.system(size: 13, weight: .bold))
                            Text("View active macOS kernel assertions (PreventUserIdleSystemSleep)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: inspectAssertions) {
                        Text(activeAssertionsText == nil ? "Inspect" : "Re-check")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.12))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                if let text = activeAssertionsText {
                    Text(text)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(6)
                }
            }
            .padding(14)
            .background(Color.secondary.opacity(0.04))
            .cornerRadius(10)
            
            // Low Battery Protection Floor Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "battery.50")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Low Battery Cutoff Floor")
                                .font(.system(size: 13, weight: .bold))
                            Text("Automatically drops assertion if battery drops below safety threshold")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { powerManager.battery.lowBatteryCutoffEnabled },
                        set: { powerManager.battery.lowBatteryCutoffEnabled = $0 }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
                
                if powerManager.battery.lowBatteryCutoffEnabled {
                    HStack(spacing: 12) {
                        Slider(
                            value: Binding(
                                get: { Double(powerManager.battery.lowBatteryThreshold) },
                                set: { powerManager.battery.lowBatteryThreshold = Int($0) }
                            ),
                            in: 5...30,
                            step: 1
                        )
                        Text("\(powerManager.battery.lowBatteryThreshold)%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .frame(width: 36)
                    }
                }
            }
            .padding(14)
            .background(Color.secondary.opacity(0.04))
            .cornerRadius(10)
            
            // Thermal Overheating Guard
            HStack(spacing: 14) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Thermal Overheating Guard")
                        .font(.system(size: 13, weight: .bold))
                    Text("Terminates sleep prevention if CPU/GPU reaches critical thermal pressure")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { powerManager.thermal.thermalProtectionEnabled },
                    set: { powerManager.thermal.thermalProtectionEnabled = $0 }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }
            .padding(14)
            .background(Color.secondary.opacity(0.04))
            .cornerRadius(10)
            
            // Re-run Onboarding Tutorial & Permissions
            actionCard(
                icon: "sparkles",
                title: "Re-run Welcome Tutorial & Presentation Setup",
                desc: "Walk through the initial onboarding guide and configure presentation modes.",
                actionTitle: "Launch Wizard"
            ) {
                showOnboarding = true
            }
            
            // CLI Copy
            actionCard(
                icon: "terminal.fill",
                title: "Command-Line Interface (CLI)",
                desc: "Run 'openlid on --duration 30m', 'openlid off', and 'openlid status' anywhere.",
                actionTitle: "Copy CLI Command"
            ) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("openlid status", forType: .string)
            }
        }
    }
    
    // MARK: - Settings Tab
    private var settingsEmbeddedView: some View {
        SettingsView(onDismiss: {
            selectedTab = .dashboard
        })
    }
    
    // MARK: - UI Helpers
    private func telemetryCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(8)
    }
    
    private func actionCard(icon: String, title: String, desc: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: action) {
                Text(actionTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.secondary.opacity(0.04))
        .cornerRadius(10)
    }
    
    // MARK: - Actions
    private func refreshHardwareMonitors() {
        isRefreshingHardware = true
        hardwareRefreshedJustNow = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.powerManager.clamshell.updateLidState()
            self.powerManager.battery.updateBatteryState()
            self.powerManager.thermal.updateThermalState()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isRefreshingHardware = false
                self.hardwareRefreshedJustNow = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.hardwareRefreshedJustNow = false
                }
            }
        }
    }
    
    private func toggleHelper() {
        isProcessingHelper = true
        helperMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if helperInstalled {
                    try PrivilegeManager.shared.uninstallHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = false
                        self.helperMessage = "Helper uninstalled successfully."
                        self.isProcessingHelper = false
                    }
                } else {
                    try PrivilegeManager.shared.installHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = true
                        self.helperMessage = "Helper installed! Instant toggles are active."
                        self.isProcessingHelper = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.helperMessage = "Failed: \(error.localizedDescription)"
                    self.isProcessingHelper = false
                }
            }
        }
    }
    
    private func resetSystemAssertions() {
        isResettingAssertions = true
        resetMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            // Restore pmset disablesleep 0 and release power assertions
            self.powerManager.disable(reason: "System assertions reset by user")
            try? PrivilegeManager.shared.setDisableSleep(enabled: false)
            
            DispatchQueue.main.async {
                self.isResettingAssertions = false
                self.resetMessage = "System power settings restored to default (disablesleep 0)."
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.resetMessage = nil
                }
            }
        }
    }
    
    private func inspectAssertions() {
        isInspectingAssertions = true
        DispatchQueue.global(qos: .userInitiated).async {
            let pipe = Pipe()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            process.arguments = ["-g", "assertions"]
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "No assertion data available."
            
            // Extract the active assertions summary lines
            let lines = output.components(separatedBy: "\n")
            let relevant = lines.filter { line in
                line.contains("PreventUserIdleSystemSleep") ||
                line.contains("PreventSystemSleep") ||
                line.contains("Listed by owning process") ||
                line.contains("openlid")
            }.prefix(6).joined(separator: "\n")
            
            DispatchQueue.main.async {
                self.activeAssertionsText = relevant.isEmpty ? "No active sleep prevention assertions currently held by system." : relevant
                self.isInspectingAssertions = false
            }
        }
    }
}
