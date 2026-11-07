import SwiftUI
import OpenLidCore

public struct MainWindowView: View {
    @ObservedObject var powerManager = PowerManager.shared
    @ObservedObject var preferences = AppPreferences.shared
    @State private var selectedTab: MainTab = .dashboard
    @State private var selectedPreset: SessionPreset = .indefinite
    @State private var showOnboarding: Bool = false
    
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
        .frame(minWidth: 540, minHeight: 620)
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
                .frame(width: 250)
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
                            Text(powerManager.isEnabled ? "Mac is Awake (Lid Bypass Active)" : "Keep Awake with Lid Closed")
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
                        
                        Text(powerManager.isEnabled ? "Mac will not sleep when lid closes. Screen turns off to save power." : "Click to enable clamshell sleep bypass mode.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
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
            
            // Session Timer Presets
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Session Duration")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    if powerManager.isEnabled && powerManager.timer.isTimerRunning {
                        Text("Remaining: \(powerManager.timer.formattedRemainingTime)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                
                HStack(spacing: 8) {
                    ForEach(SessionPreset.allCases) { preset in
                        Button(action: {
                            selectedPreset = preset
                            if powerManager.isEnabled {
                                powerManager.enable(preset: preset)
                            }
                        }) {
                            Text(preset.title)
                                .font(.system(size: 12, weight: selectedPreset == preset ? .bold : .medium))
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
            
            // Telemetry Grid
            VStack(alignment: .leading, spacing: 8) {
                Text("Live System Telemetry")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    telemetryCard(
                        icon: powerManager.clamshell.isLidClosed ? "laptopcomputer.and.arrow.down" : "laptopcomputer",
                        title: "Lid State",
                        value: powerManager.clamshell.isLidClosed ? "Lid Closed" : "Lid Open",
                        color: powerManager.clamshell.isLidClosed ? .blue : .primary
                    )
                    
                    telemetryCard(
                        icon: powerManager.battery.isCharging ? "bolt.batteryblock.fill" : "battery.100",
                        title: "Battery Level",
                        value: "\(powerManager.battery.batteryPercent)% \(powerManager.battery.isCharging ? "(Charging)" : "")",
                        color: powerManager.battery.batteryPercent < 20 ? .red : .green
                    )
                    
                    telemetryCard(
                        icon: "thermometer.medium",
                        title: "Thermal Pressure",
                        value: powerManager.thermal.stateDescription,
                        color: powerManager.thermal.thermalState == .critical ? .red : .green
                    )
                    
                    telemetryCard(
                        icon: powerManager.battery.isOnACPower ? "powerplug.fill" : "battery.50",
                        title: "Power Source",
                        value: powerManager.battery.isOnACPower ? "AC Connected" : "Battery Mode",
                        color: .primary
                    )
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.04))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Controls Tab
    private var controlsView: some View {
        VStack(spacing: 14) {
            actionCard(
                icon: "sparkles",
                title: "Re-run Welcome Tutorial & Permissions",
                desc: "Walk through the initial onboarding guide and verify kernel sleep assertions.",
                actionTitle: "Launch Wizard"
            ) {
                showOnboarding = true
            }
            
            actionCard(
                icon: "terminal.fill",
                title: "Command-Line Interface (CLI)",
                desc: "Use 'openlid on', 'openlid off', and 'openlid status' from any terminal session or SSH.",
                actionTitle: "Copy CLI Path"
            ) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("openlid status", forType: .string)
            }
            
            actionCard(
                icon: "arrow.clockwise",
                title: "Refresh Hardware Monitors",
                desc: "Queries IOKit and SMC power registers immediately to sync battery, thermal, and lid states.",
                actionTitle: "Query Now"
            ) {
                powerManager.clamshell.updateLidState()
                powerManager.battery.updateBatteryState()
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
                .font(.system(size: 22))
                .foregroundColor(.green)
                .frame(width: 30)
            
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
}
