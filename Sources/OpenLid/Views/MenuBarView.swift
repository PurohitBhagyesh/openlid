import SwiftUI
import OpenLidCore

struct MenuBarView: View {
    @ObservedObject var powerManager = PowerManager.shared
    @State private var selectedPreset: SessionPreset = .indefinite
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    
    var body: some View {
        mainView
            .frame(width: 350)
            .onAppear {
                helperInstalled = PrivilegeManager.shared.isHelperInstalled()
                powerManager.clamshell.updateLidState()
                powerManager.battery.updateBatteryState()
            }
    }
    
    private var mainView: some View {
        VStack(spacing: 12) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: powerManager.isEnabled ? "eye.fill" : "eye.slash")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(powerManager.isEnabled ? .green : .secondary)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("OpenLid")
                            .font(.system(size: 15, weight: .bold))
                        Text(powerManager.isEnabled ? "Awake & Vigilant" : "Normal Sleep Mode")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status badge
                Text(powerManager.isEnabled ? "AWAKE" : "ASLEEP")
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(powerManager.isEnabled ? Color.green.opacity(0.2) : Color.secondary.opacity(0.15))
                    .foregroundColor(powerManager.isEnabled ? .green : .secondary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            
            Divider()
                .padding(.horizontal, 10)
            
            // Hero Toggle Card
            VStack(spacing: 10) {
                Button(action: {
                    powerManager.toggle(preset: selectedPreset)
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(powerManager.isEnabled ? Color.green : Color.secondary.opacity(0.2))
                                .frame(width: 38, height: 38)
                            
                            if powerManager.isBusy {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: powerManager.isEnabled ? "eye.fill" : "eye.slash")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(powerManager.isEnabled ? .white : .primary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(powerManager.isEnabled ? "Mac is Awake (Eye Vigilant)" : "Keep Awake with Lid Closed")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(powerManager.isEnabled ? "Mac continues running even if lid is closed" : "Click to keep Mac awake when closing lid")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(10)
                    .background(powerManager.isEnabled ? Color.green.opacity(0.1) : Color.primary.opacity(0.04))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(powerManager.isEnabled ? Color.green.opacity(0.3) : Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            
            // Timer Countdown banner (if running)
            if powerManager.isEnabled && powerManager.timer.isTimerRunning {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text("Session ends in:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(powerManager.timer.formattedRemainingTime)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Stop Timer") {
                        powerManager.timer.stop()
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 14)
            }
            
            // Session Preset Duration Selector (No truncation!)
            VStack(alignment: .leading, spacing: 6) {
                Text("Session Duration")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 5) {
                    ForEach([SessionPreset.indefinite, .min15, .min30, .hour1, .hour2], id: \.self) { preset in
                        Button(action: {
                            selectedPreset = preset
                            if powerManager.isEnabled {
                                powerManager.timer.start(preset: preset)
                            }
                        }) {
                            HStack(spacing: 3) {
                                if preset == .indefinite {
                                    Image(systemName: "infinity")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                Text(presetShortTitle(preset))
                                    .font(.system(size: 11, weight: selectedPreset == preset ? .bold : .medium))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(selectedPreset == preset ? Color.accentColor : Color.secondary.opacity(0.12))
                            .foregroundColor(selectedPreset == preset ? .white : .primary)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 14)
            
            // Hardware Telemetry Strip
            HStack(spacing: 8) {
                // Lid State
                TelemetryCard(
                    icon: powerManager.clamshell.isLidClosed ? "lock.fill" : "book.closed",
                    title: "Lid",
                    value: powerManager.clamshell.isLidClosed ? "Closed" : "Open",
                    color: powerManager.clamshell.isLidClosed ? .orange : .green
                )
                
                // Battery
                TelemetryCard(
                    icon: powerManager.battery.isOnACPower ? "bolt.fill" : "battery.75",
                    title: powerManager.battery.isOnACPower ? "Power" : "Battery",
                    value: "\(powerManager.battery.batteryPercent)%",
                    color: powerManager.battery.batteryPercent <= 20 ? .red : .blue
                )
                
                // Thermal
                TelemetryCard(
                    icon: "thermometer.medium",
                    title: "Thermal",
                    value: thermalShortTitle(powerManager.thermal.thermalState),
                    color: powerManager.thermal.isDangerous ? .red : .green
                )
            }
            .padding(.horizontal, 14)
            
            // Error or Stop Reason Alert
            if let error = powerManager.lastError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                    Spacer()
                    Button(action: { powerManager.lastError = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
                .padding(.horizontal, 14)
            } else if let reason = powerManager.stopReason {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text(reason)
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    Spacer()
                    Button(action: { powerManager.stopReason = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
                .padding(.horizontal, 14)
            }
            
            // Helper Quick Notice (if not installed)
            if !helperInstalled {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.badge.clock")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Instant Toggle Mode")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Authorize once to skip password popups")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Install") {
                        installHelperQuick()
                    }
                    .font(.system(size: 10, weight: .bold))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.accentColor.opacity(0.08))
                .cornerRadius(8)
                .padding(.horizontal, 14)
            }
            
            Divider()
                .padding(.horizontal, 10)
            
            // Developer Tagline Row
            HStack(spacing: 6) {
                Link(destination: URL(string: "https://github.com/PurohitBhagyesh")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("Bhagyesh Purohit")
                            .font(.system(size: 10, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Link(destination: URL(string: "https://openlid.devs.li")!) {
                    Text("openlid.devs.li ↗")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            
            // Footer Controls
            HStack {
                Button(action: {
                    SettingsWindowManager.shared.showSettings()
                }) {
                    Label("Settings...", systemImage: "gearshape")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    powerManager.cleanup()
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit OpenLid")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(width: 350)
    }
    
    private func presetShortTitle(_ preset: SessionPreset) -> String {
        switch preset {
        case .indefinite: return "Always"
        case .min15: return "15m"
        case .min30: return "30m"
        case .hour1: return "1h"
        case .hour2: return "2h"
        }
    }
    
    private func thermalShortTitle(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Cool"
        case .fair: return "Fair"
        case .serious: return "Hot"
        case .critical: return "Danger"
        @unknown default: return "OK"
        }
    }
    
    private func installHelperQuick() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try PrivilegeManager.shared.installHelper()
                DispatchQueue.main.async {
                    self.helperInstalled = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.powerManager.lastError = "Helper install: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct TelemetryCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(6)
    }
}
