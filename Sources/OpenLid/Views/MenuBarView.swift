import SwiftUI
import OpenLidCore

struct MenuBarView: View {
    @ObservedObject var powerManager = PowerManager.shared
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    
    private let footerActions: [LiquidFooterAction] = [
        LiquidFooterAction(id: "settings", systemImage: "gearshape", label: "Settings"),
        LiquidFooterAction(id: "window", systemImage: "macwindow", label: "Window"),
        LiquidFooterAction(id: "quit", systemImage: "power", label: "Quit")
    ]
    
    var body: some View {
        ZStack {
            LiquidGlassBackdrop(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
            Color.black.opacity(0.36)
                .ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Hero Liquid Glass Toggle Card (fixed height -> ZERO jump, fluid motion)
                Button(action: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                        powerManager.toggle(preset: powerManager.selectedPreset)
                    }
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
                                .contentTransition(.interpolate)
                                .animation(.spring(response: 0.30, dampingFraction: 0.82), value: powerManager.isEnabled)
                                .frame(height: 17, alignment: .leading)
                            
                            ZStack(alignment: .leading) {
                                if powerManager.isEnabled {
                                    if powerManager.timer.isTimerRunning {
                                        Text("\(powerManager.timer.formattedRemainingTime) left")
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(Color.white.opacity(0.76))
                                            .smoothNumericTransition(countsDown: true)
                                            .animation(.spring(response: 0.30, dampingFraction: 0.85), value: powerManager.timer.remainingSeconds)
                                            .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .leading)))
                                    } else {
                                        Text(powerManager.timer.formattedElapsedTime)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(Color.white.opacity(0.76))
                                            .smoothNumericTransition(countsDown: false)
                                            .animation(.spring(response: 0.30, dampingFraction: 0.85), value: powerManager.timer.elapsedSeconds)
                                            .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .leading)))
                                    }
                                } else {
                                    Text("Lid sleep normal")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.white.opacity(0.45))
                                        .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .leading)))
                                }
                            }
                            .frame(height: 14, alignment: .leading)
                            .animation(.spring(response: 0.30, dampingFraction: 0.84), value: powerManager.isEnabled)
                            .animation(.spring(response: 0.30, dampingFraction: 0.84), value: powerManager.timer.isTimerRunning)
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
                        }
                        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: powerManager.isEnabled)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 58)
                    .liquidGlassCard(cornerRadius: 13, elevated: powerManager.isEnabled)
                }
                .buttonStyle(.plain)
                .disabled(powerManager.isBusy)
                
                // Fluid Sliding Duration Liquid Glass Capsule
                LiquidSegmentedControl(
                    options: SessionPreset.allCases,
                    selection: powerManager.selectedPreset,
                    height: 32,
                    fontSize: 11,
                    label: presetShortTitle
                ) { preset in
                    powerManager.selectPreset(preset)
                }
                
                // Monochrome 3-Stat Telemetry Strip
                HStack(spacing: 0) {
                    statItem(label: "Lid", value: powerManager.clamshell.isLidClosed ? "Closed" : "Open", numeric: false)
                    dividerLine
                    statItem(label: powerManager.battery.isOnACPower ? "AC" : "Battery", value: "\(powerManager.battery.batteryPercent)%", numeric: true)
                    dividerLine
                    statItem(label: "Thermal", value: thermalShortTitle(powerManager.thermal.thermalState), numeric: false)
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
                            withAnimation(.easeOut(duration: 0.16)) {
                                powerManager.lastError = nil
                                powerManager.stopReason = nil
                            }
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
                
                // Fluid Gliding Monochrome Icon Footer (highlight & label glide across icons on hover)
                LiquidIconDock(actions: footerActions) { action in
                    switch action.id {
                    case "settings":
                        SettingsWindowManager.shared.showSettings()
                    case "window":
                        MainWindowManager.shared.showMainWindow()
                    case "quit":
                        powerManager.cleanup()
                        NSApplication.shared.terminate(nil)
                    default:
                        break
                    }
                }
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
    
    @ViewBuilder
    private func statItem(label: String, value: String, numeric: Bool) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 9.5))
                .foregroundColor(Color.white.opacity(0.40))
            if numeric {
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .smoothNumericTransition()
                    .animation(.spring(response: 0.30, dampingFraction: 0.84), value: value)
            } else {
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .contentTransition(.interpolate)
                    .animation(.easeInOut(duration: 0.22), value: value)
            }
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
