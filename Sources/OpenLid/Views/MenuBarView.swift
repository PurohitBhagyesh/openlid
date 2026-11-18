import SwiftUI
import OpenLidCore

struct MenuBarView: View {
    @ObservedObject var powerManager = PowerManager.shared
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    
    var body: some View {
        ZStack {
            LiquidGlassBackdrop(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
            Color.black.opacity(0.36)
                .ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Hero Liquid Glass Toggle Card (fixed height -> ZERO jump when toggled ON/OFF)
                Button(action: {
                    powerManager.toggle(preset: powerManager.selectedPreset)
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            if powerManager.isBusy {
                                ProgressView()
                                    .scaleEffect(0.55)
                                    .colorInvert()
                            } else {
                                AnimatedEyeView(size: 36, isAwake: powerManager.isEnabled, isScanning: powerManager.isEnabled)
                            }
                        }
                        .frame(width: 38, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(powerManager.isEnabled ? "Awake" : "Standby")
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(height: 17, alignment: .leading)
                            
                            Group {
                                if powerManager.isEnabled {
                                    Text(powerManager.timer.isTimerRunning
                                         ? "\(powerManager.timer.formattedRemainingTime) left"
                                         : powerManager.timer.formattedElapsedTime)
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.72))
                                } else {
                                    Text("Lid sleep normal")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.white.opacity(0.45))
                                }
                            }
                            .frame(height: 14, alignment: .leading)
                        }
                        
                        Spacer()
                        
                        // Monochrome Liquid Glass Switch Pill
                        ZStack {
                            Capsule()
                                .fill(powerManager.isEnabled ? Color.white : Color.white.opacity(0.14))
                                .frame(width: 36, height: 20)
                            Circle()
                                .fill(powerManager.isEnabled ? Color.black : Color.white.opacity(0.78))
                                .frame(width: 14, height: 14)
                                .offset(x: powerManager.isEnabled ? 8 : -8)
                                .animation(.spring(response: 0.22, dampingFraction: 0.82), value: powerManager.isEnabled)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 58)
                    .liquidGlassCard(cornerRadius: 13, elevated: powerManager.isEnabled)
                }
                .buttonStyle(.plain)
                .disabled(powerManager.isBusy)
                
                // Duration Segmented Liquid Glass Capsule
                HStack(spacing: 2) {
                    ForEach(SessionPreset.allCases) { preset in
                        let selected = powerManager.selectedPreset == preset
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                powerManager.selectPreset(preset)
                            }
                        }) {
                            Text(presetShortTitle(preset))
                                .font(.system(size: 11, weight: selected ? .semibold : .regular))
                                .foregroundColor(selected ? .black : Color.white.opacity(0.62))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(selected ? Color.white : Color.clear)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2.5)
                .frame(height: 32)
                .liquidGlassCard(cornerRadius: 16, elevated: false)
                
                // Monochrome 3-Stat Telemetry Strip
                HStack(spacing: 0) {
                    statItem(label: "Lid", value: powerManager.clamshell.isLidClosed ? "Closed" : "Open")
                    dividerLine
                    statItem(label: powerManager.battery.isOnACPower ? "AC" : "Battery", value: "\(powerManager.battery.batteryPercent)%")
                    dividerLine
                    statItem(label: "Thermal", value: thermalShortTitle(powerManager.thermal.thermalState))
                }
                .frame(height: 44)
                .liquidGlassCard(cornerRadius: 12, elevated: false)
                
                if let notice = powerManager.lastError ?? powerManager.stopReason {
                    HStack(spacing: 6) {
                        Text(notice)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.82))
                            .lineLimit(2)
                        Spacer()
                        Button(action: {
                            powerManager.lastError = nil
                            powerManager.stopReason = nil
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .liquidGlassCard(cornerRadius: 9, elevated: true)
                }
                
                if !helperInstalled {
                    HStack {
                        Text("Instant Toggle")
                            .font(.system(size: 11.5))
                            .foregroundColor(Color.white.opacity(0.75))
                        Spacer()
                        Button("Enable") {
                            installHelperQuick()
                        }
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3.5)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .liquidGlassCard(cornerRadius: 10, elevated: false)
                }
                
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
                
                // Quiet Monochrome Footer
                HStack {
                    Button("Window") {
                        MainWindowManager.shared.showMainWindow()
                    }
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.white)
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button("Settings") {
                        SettingsWindowManager.shared.showSettings()
                    }
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.white.opacity(0.58))
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button("Quit") {
                        powerManager.cleanup()
                        NSApplication.shared.terminate(nil)
                    }
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.white.opacity(0.42))
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
            .padding(12)
        }
        .frame(width: 296)
        .preferredColorScheme(.dark)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
            refreshHardwareMonitors()
        }
    }
    
    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 0.75, height: 20)
    }
    
    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 9.5))
                .foregroundColor(Color.white.opacity(0.40))
            Text(value)
                .font(.system(size: 12, weight: .medium))
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
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Warm"
        case .critical: return "Hot"
        @unknown default: return "OK"
        }
    }
    
    private func refreshHardwareMonitors() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.powerManager.clamshell.updateLidState()
            self.powerManager.battery.updateBatteryState()
            self.powerManager.thermal.updateThermalState()
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
