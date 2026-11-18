import SwiftUI
import OpenLidCore

struct MenuBarView: View {
    @ObservedObject var powerManager = PowerManager.shared
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var isRefreshingHardware: Bool = false
    
    private let bgColor = Color(red: 0.055, green: 0.065, blue: 0.082)
    private let cardBg = Color.white.opacity(0.04)
    private let cardBorder = Color.white.opacity(0.08)
    private let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)
    
    var body: some View {
        VStack(spacing: 12) {
            // Compact Hero Toggle Card
            Button(action: {
                powerManager.toggle(preset: powerManager.selectedPreset)
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        if powerManager.isBusy {
                            ProgressView()
                                .scaleEffect(0.6)
                                .colorInvert()
                                .frame(width: 40, height: 40)
                        } else {
                            AnimatedEyeView(size: 40, isAwake: powerManager.isEnabled, isScanning: powerManager.isEnabled)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(powerManager.isEnabled ? "Awake" : "Standby")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            if powerManager.isEnabled {
                                Text(powerManager.timer.isTimerRunning ? powerManager.timer.formattedRemainingTime : powerManager.timer.formattedElapsedTime)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(powerManager.timer.isTimerRunning ? .orange : Color(red: 0.45, green: 0.90, blue: 0.72))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background((powerManager.timer.isTimerRunning ? Color.orange : emerald).opacity(0.14))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(powerManager.isEnabled ? "Lid close sleep disabled" : "Click to keep Mac awake")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.50))
                    }
                    
                    Spacer()
                    
                    // Tactile Power Pill
                    ZStack {
                        Capsule()
                            .fill(powerManager.isEnabled ? emerald : Color.white.opacity(0.12))
                            .frame(width: 38, height: 22)
                        Circle()
                            .fill(powerManager.isEnabled ? Color.black : Color.white.opacity(0.75))
                            .frame(width: 16, height: 16)
                            .offset(x: powerManager.isEnabled ? 8 : -8)
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: powerManager.isEnabled)
                    }
                }
                .padding(12)
                .background(powerManager.isEnabled ? emerald.opacity(0.09) : cardBg)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(powerManager.isEnabled ? emerald.opacity(0.32) : cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(powerManager.isBusy)
            
            // Duration Pills (Unified Emerald)
            HStack(spacing: 5) {
                ForEach(SessionPreset.allCases) { preset in
                    let selected = powerManager.selectedPreset == preset
                    Button(action: {
                        powerManager.selectPreset(preset)
                    }) {
                        Text(presetShortTitle(preset))
                            .font(.system(size: 11, weight: selected ? .bold : .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(selected ? emerald : cardBg)
                            .foregroundColor(selected ? .black : Color.white.opacity(0.75))
                            .cornerRadius(7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(selected ? Color.clear : cardBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Clean 3-Stat Telemetry Strip
            HStack(spacing: 0) {
                miniStat(
                    icon: powerManager.clamshell.isLidClosed ? "laptopcomputer.and.arrow.down" : "laptopcomputer",
                    value: powerManager.clamshell.isLidClosed ? "Closed" : "Open",
                    tint: powerManager.clamshell.isLidClosed ? .orange : emerald
                )
                Divider().frame(height: 20).background(Color.white.opacity(0.08))
                miniStat(
                    icon: powerManager.battery.isOnACPower ? "bolt.fill" : "battery.75",
                    value: "\(powerManager.battery.batteryPercent)%",
                    tint: powerManager.battery.batteryPercent <= 20 ? .red : emerald
                )
                Divider().frame(height: 20).background(Color.white.opacity(0.08))
                miniStat(
                    icon: "thermometer.medium",
                    value: thermalShortTitle(powerManager.thermal.thermalState),
                    tint: powerManager.thermal.isDangerous ? .red : emerald
                )
            }
            .padding(.vertical, 9)
            .background(cardBg)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(cardBorder, lineWidth: 1)
            )
            
            // Optional inline alert (error or stop reason)
            if let notice = powerManager.lastError ?? powerManager.stopReason {
                let isErr = powerManager.lastError != nil
                HStack(spacing: 6) {
                    Image(systemName: isErr ? "exclamationmark.circle.fill" : "info.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(isErr ? .red : .orange)
                    Text(notice)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(2)
                    Spacer()
                    Button(action: {
                        powerManager.lastError = nil
                        powerManager.stopReason = nil
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background((isErr ? Color.red : Color.orange).opacity(0.12))
                .cornerRadius(8)
            }
            
            // Optional compact helper notice
            if !helperInstalled {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 12))
                        .foregroundColor(emerald)
                    Text("Enable Instant Toggle")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.82))
                    Spacer()
                    Button("Enable") {
                        installHelperQuick()
                    }
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(emerald)
                    .cornerRadius(5)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(emerald.opacity(0.08))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(emerald.opacity(0.22), lineWidth: 1)
                )
            }
            
            Divider().background(Color.white.opacity(0.07))
            
            // Minimal Footer
            HStack {
                Button(action: {
                    MainWindowManager.shared.showMainWindow()
                }) {
                    Label("Open", systemImage: "macwindow")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    SettingsWindowManager.shared.showSettings()
                }) {
                    Label("Settings", systemImage: "gearshape")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.65))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    powerManager.cleanup()
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 2)
        }
        .padding(14)
        .frame(width: 312)
        .background(bgColor)
        .preferredColorScheme(.dark)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
            refreshHardwareMonitors()
        }
    }
    
    private func miniStat(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(tint)
            Text(value)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
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
        case .serious: return "Warm"
        case .critical: return "Hot"
        @unknown default: return "OK"
        }
    }
    
    private func refreshHardwareMonitors() {
        isRefreshingHardware = true
        DispatchQueue.global(qos: .userInitiated).async {
            self.powerManager.clamshell.updateLidState()
            self.powerManager.battery.updateBatteryState()
            self.powerManager.thermal.updateThermalState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isRefreshingHardware = false
            }
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
                    self.powerManager.lastError = "Helper install failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
