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
    
    @Namespace private var topTabNamespace
    
    public enum MainTab: String, CaseIterable, Identifiable, Hashable {
        case home = "Home"
        case settings = "Settings"
        public var id: String { rawValue }
    }
    
    public init() {}
    
    public var body: some View {
        Group {
            if !preferences.hasCompletedOnboarding || showOnboarding {
                OnboardingView(onComplete: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        preferences.hasCompletedOnboarding = true
                        showOnboarding = false
                        selectedTab = .home
                    }
                    if preferences.presentationMode == .menuBarOnly {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            MainWindowManager.shared.closeMainWindow()
                        }
                    }
                })
                .transition(.opacity)
            } else {
                mainAppContent
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                // Single translucent titlebar directly on the traffic-light row (ZERO extra forehead)
                HStack(spacing: 8) {
                    Spacer().frame(width: 64)
                    
                    Text("OpenLid")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !ApplicationMover.isInstalledInApplications() && !ApplicationMover.isDevOrBuildEnvironment() {
                        Button("Install") {
                            MoveToApplicationsWindowManager.shared.showPrompt(force: true)
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // Fluid sliding Liquid Glass tab switcher
                    HStack(spacing: 2) {
                        ForEach(MainTab.allCases) { tab in
                            let active = selectedTab == tab
                            Button(action: {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.80)) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: active ? .semibold : .regular))
                                    .foregroundColor(active ? .black : Color.white.opacity(0.62))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 3.5)
                                    .background {
                                        if active {
                                            Capsule()
                                                .fill(Color.white)
                                                .matchedGeometryEffect(id: "topTabPill", in: topTabNamespace)
                                        }
                                    }
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(2)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.16), lineWidth: 0.75)
                    )
                }
                .padding(.horizontal, 14)
                .frame(height: 38)
                
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
                
                // Smooth horizontal cross-slide between Home and Settings
                ZStack {
                    if selectedTab == .home {
                        homeTab
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        settingsTab
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .animation(.spring(response: 0.34, dampingFraction: 0.84), value: selectedTab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            // Non-shifting floating glass toast for errors / notices
            if let notice = powerManager.lastError ?? powerManager.stopReason ?? toastMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Text(notice)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        Spacer(minLength: 4)
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.18)) {
                                powerManager.lastError = nil
                                powerManager.stopReason = nil
                                toastMessage = nil
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .liquidGlassCard(cornerRadius: 9, elevated: true)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
    
    // MARK: - Home Tab (Zero layout shift, fluid spring motion)
    private var homeTab: some View {
        VStack(spacing: 10) {
            // Hero Liquid Glass Stage
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                AnimatedEyeView(size: 60, isAwake: powerManager.isEnabled, isScanning: powerManager.isEnabled)
                
                Spacer().frame(height: 14)
                
                Text(powerManager.isEnabled ? "Awake" : "Standby")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(height: 24)
                    .contentTransition(.interpolate)
                    .animation(.spring(response: 0.32, dampingFraction: 0.82), value: powerManager.isEnabled)
                
                Spacer().frame(height: 4)
                
                // Fixed-height 18pt rolling timer / status line -> ZERO jump on toggle
                ZStack {
                    if powerManager.isEnabled {
                        if powerManager.timer.isTimerRunning {
                            HStack(spacing: 6) {
                                Text(powerManager.timer.formattedRemainingTime)
                                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.88))
                                    .smoothNumericTransition(countsDown: true)
                                    .animation(.spring(response: 0.30, dampingFraction: 0.85), value: powerManager.timer.remainingSeconds)
                                Text("remaining")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(Color.white.opacity(0.45))
                                Button("Clear") {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                                        powerManager.selectPreset(.indefinite)
                                    }
                                }
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.68))
                                .buttonStyle(.plain)
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.94)))
                        } else {
                            HStack(spacing: 6) {
                                Text(powerManager.timer.formattedElapsedTime)
                                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.84))
                                    .smoothNumericTransition(countsDown: false)
                                    .animation(.spring(response: 0.30, dampingFraction: 0.85), value: powerManager.timer.elapsedSeconds)
                                Text("·")
                                    .foregroundColor(Color.white.opacity(0.35))
                                Text("Lid sleep disabled")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(Color.white.opacity(0.48))
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.94)))
                        }
                    } else {
                        Text("Normal macOS sleep behavior")
                            .font(.system(size: 11.5))
                            .foregroundColor(Color.white.opacity(0.42))
                            .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    }
                }
                .frame(height: 18)
                .animation(.spring(response: 0.32, dampingFraction: 0.84), value: powerManager.isEnabled)
                .animation(.spring(response: 0.32, dampingFraction: 0.84), value: powerManager.timer.isTimerRunning)
                
                Spacer().frame(height: 16)
                
                // Monochrome Primary Action Pill
                Button(action: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                        powerManager.toggle(preset: powerManager.selectedPreset)
                    }
                }) {
                    HStack(spacing: 7) {
                        if powerManager.isBusy {
                            ProgressView()
                                .scaleEffect(0.55)
                                .colorInvert()
                            Text("Updating")
                                .font(.system(size: 12.5, weight: .medium))
                        } else {
                            Text(powerManager.isEnabled ? "Restore Sleep" : "Keep Awake")
                                .font(.system(size: 12.5, weight: .semibold))
                        }
                    }
                    .foregroundColor(powerManager.isEnabled ? .white : .black)
                    .frame(width: 184, height: 36)
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
                    .animation(.spring(response: 0.32, dampingFraction: 0.82), value: powerManager.isEnabled)
                }
                .buttonStyle(.plain)
                .disabled(powerManager.isBusy)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .liquidGlassCard(cornerRadius: 15, elevated: powerManager.isEnabled)
            
            // Fluid Sliding Duration Liquid Glass Capsule
            LiquidSegmentedControl(
                options: SessionPreset.allCases,
                selection: powerManager.selectedPreset,
                height: 34,
                fontSize: 11,
                label: shortLabel
            ) { preset in
                powerManager.selectPreset(preset)
            }
            
            // Minimal 3-Column Monochrome Telemetry Bar
            HStack(spacing: 0) {
                statCell(label: "Lid", value: powerManager.clamshell.isLidClosed ? "Closed" : "Open", numeric: false)
                glassDivider
                statCell(label: powerManager.battery.isOnACPower ? "AC" : "Battery", value: "\(powerManager.battery.batteryPercent)%", numeric: true)
                glassDivider
                statCell(label: "Thermal", value: shortThermal(powerManager.thermal.thermalState), numeric: false)
                glassDivider
                Button(action: refreshHardwareMonitors) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.55))
                        .rotationEffect(.degrees(isRefreshingHardware ? 360 : 0))
                        .animation(isRefreshingHardware ? .linear(duration: 0.6).repeatForever(autoreverses: false) : .default, value: isRefreshingHardware)
                        .frame(width: 36, height: 48)
                }
                .buttonStyle(.plain)
                .help("Refresh hardware monitors")
            }
            .frame(height: 48)
            .liquidGlassCard(cornerRadius: 13, elevated: false)
        }
        .padding(14)
    }
    
    // MARK: - Settings Tab (Tight, balanced, zero unnecessary spacing)
    private var settingsTab: some View {
        VStack(spacing: 10) {
            // Toggles Glass Card
            VStack(spacing: 0) {
                toggleRow(icon: "arrow.up.right.circle", title: "Launch at Login", isOn: Binding(
                    get: { LaunchAtLoginManager.shared.isLaunchAtLoginEnabled },
                    set: { try? LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: $0) }
                ))
                rowHairline
                toggleRow(icon: "bolt", title: "Auto-Awake on Login", isOn: Binding(
                    get: { LaunchAtLoginManager.shared.awakeOnLogin },
                    set: { LaunchAtLoginManager.shared.awakeOnLogin = $0 }
                ))
                rowHairline
                toggleRow(icon: "thermometer.medium", title: "Thermal Protection", isOn: Binding(
                    get: { powerManager.thermal.thermalProtectionEnabled },
                    set: { powerManager.thermal.thermalProtectionEnabled = $0 }
                ))
            }
            .liquidGlassCard(cornerRadius: 12, elevated: false)
            
            // System Actions Glass Card
            VStack(spacing: 0) {
                actionRow(
                    icon: "lock.open",
                    title: "Instant Toggle Helper",
                    trailing: isProcessingHelper ? "Working..." : (helperInstalled ? "Remove" : "Enable"),
                    primary: !helperInstalled,
                    disabled: isProcessingHelper,
                    action: toggleHelper
                )
                rowHairline
                actionRow(
                    icon: "arrow.counterclockwise",
                    title: "Reset Sleep Settings",
                    trailing: isResettingAssertions ? "Resetting..." : "Reset",
                    primary: false,
                    disabled: isResettingAssertions,
                    action: resetSystemAssertions
                )
                rowHairline
                HStack(spacing: 9) {
                    rowIcon("folder")
                    Text("Applications")
                        .font(.system(size: 12.5))
                        .foregroundColor(.white)
                    Spacer()
                    if ApplicationMover.isInstalledInApplications() {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9.5, weight: .semibold))
                            Text("Installed")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Color.white.opacity(0.48))
                    } else {
                        Button("Move") {
                            MoveToApplicationsWindowManager.shared.showPrompt(force: true)
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3.5)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                rowHairline
                actionRow(
                    icon: "sparkles",
                    title: "Welcome Guide",
                    trailing: "Show",
                    primary: false,
                    disabled: false,
                    action: {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) {
                            showOnboarding = true
                        }
                    }
                )
            }
            .liquidGlassCard(cornerRadius: 12, elevated: false)
            
            Spacer(minLength: 0)
            
            // Quiet Monochrome Footer
            HStack(spacing: 12) {
                Text("v2.0.0")
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.32))
                Spacer()
                Link("Website", destination: URL(string: "https://openlid.devs.li")!)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.54))
                Link("GitHub", destination: URL(string: "https://github.com/PurohitBhagyesh/openlid")!)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.54))
                Link("Support", destination: URL(string: "mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Support%20(macOS)")!)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.86))
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
    }
    
    // MARK: - Components
    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(Color.white.opacity(0.52))
            .frame(width: 16, alignment: .center)
    }
    
    private var glassDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 0.75, height: 22)
    }
    
    private var rowHairline: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 37)
    }
    
    @ViewBuilder
    private func statCell(label: String, value: String, numeric: Bool) -> some View {
        VStack(spacing: 1.5) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.42))
            if numeric {
                Text(value)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.white)
                    .smoothNumericTransition()
                    .animation(.spring(response: 0.30, dampingFraction: 0.84), value: value)
            } else {
                Text(value)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.white)
                    .contentTransition(.interpolate)
                    .animation(.easeInOut(duration: 0.22), value: value)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 9) {
            rowIcon(icon)
            Text(title)
                .font(.system(size: 12.5))
                .foregroundColor(.white)
            Spacer()
            LiquidToggle(isOn: isOn)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }
    
    private func actionRow(icon: String, title: String, trailing: String, primary: Bool, disabled: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 9) {
            rowIcon(icon)
            Text(title)
                .font(.system(size: 12.5))
                .foregroundColor(.white)
            Spacer()
            Button(action: action) {
                Text(trailing)
                    .font(.system(size: 11, weight: primary ? .semibold : .medium))
                    .foregroundColor(primary ? .black : Color.white.opacity(0.84))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3.5)
                    .background(primary ? Color.white : Color.white.opacity(0.10))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(primary ? Color.clear : Color.white.opacity(0.16), lineWidth: 0.75)
                    )
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
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
        withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeOut(duration: 0.22)) {
                if toastMessage == message { toastMessage = nil }
            }
        }
    }
}
