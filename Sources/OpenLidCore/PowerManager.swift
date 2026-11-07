import Foundation
import Combine
import IOKit.pwr_mgt

public final class PowerManager: ObservableObject {
    public static let shared = PowerManager()
    
    @Published public private(set) var isEnabled: Bool = false
    @Published public private(set) var isBusy: Bool = false
    @Published public var lastError: String? = nil
    @Published public var stopReason: String? = nil
    
    public let clamshell = ClamshellMonitor.shared
    public let battery = BatteryMonitor.shared
    public let thermal = ThermalMonitor.shared
    public let timer = SessionTimer()
    
    private var assertionID: IOPMAssertionID = 0
    private var hasActiveAssertion: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupSafetyHooks()
        // Forward timer ticks in real time to PowerManager subscribers
        timer.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Check if sleep is already disabled at system level on startup
        let liveState = checkLiveSystemSleepDisabled()
        self.isEnabled = liveState
    }
    
    deinit {
        cleanup()
    }
    
    private func setupSafetyHooks() {
        // Battery safety hook
        battery.onLowBatteryThresholdReached = { [weak self] in
            guard let self = self, self.isEnabled else { return }
            let msg = "Low battery safety cutoff (\(self.battery.batteryPercent)% remaining)"
            NotificationManager.shared.sendNotification(
                title: "OpenLid Battery Guard",
                body: "Battery dropped to \(self.battery.batteryPercent)%. Restored normal sleep to prevent total drain."
            )
            self.disable(reason: msg)
        }
        
        // Thermal safety hook
        thermal.onOverheatingDetected = { [weak self] in
            guard let self = self, self.isEnabled else { return }
            let msg = "Thermal safety guard: High CPU/chassis temperature (\(self.thermal.stateDescription))"
            NotificationManager.shared.sendNotification(
                title: "OpenLid Thermal Guard",
                body: "Dangerous temperatures detected (\(self.thermal.stateDescription)). Restored normal sleep to prevent overheating."
            )
            self.disable(reason: msg)
        }
        
        // Timer expiration hook
        timer.onTimerExpired = { [weak self] in
            guard let self = self, self.isEnabled else { return }
            NotificationManager.shared.sendNotification(
                title: "OpenLid Session Completed",
                body: "Your timed session has completed. Normal sleep restored."
            )
            self.disable(reason: "Session duration completed")
        }
    }
    
    /// Enables closed-lid running mode (disables system sleep on lid close).
    public func enable(preset: SessionPreset = .indefinite) {
        guard !isEnabled else {
            // If already enabled, just update timer preset
            timer.start(preset: preset)
            return
        }
        
        isBusy = true
        lastError = nil
        stopReason = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                try PrivilegeManager.shared.setDisableSleep(enabled: true)
                self.takePowerAssertion()
                
                DispatchQueue.main.async {
                    self.isEnabled = true
                    self.isBusy = false
                    self.timer.start(preset: preset)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isBusy = false
                    self.lastError = error.localizedDescription
                }
            }
        }
    }
    
    /// Disables closed-lid running mode (restores normal macOS sleep behavior).
    public func disable(reason: String? = nil) {
        isBusy = true
        lastError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                try PrivilegeManager.shared.setDisableSleep(enabled: false)
                self.releasePowerAssertion()
                
                DispatchQueue.main.async {
                    self.isEnabled = false
                    self.isBusy = false
                    self.timer.stop()
                    if let reason = reason {
                        self.stopReason = reason
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isBusy = false
                    self.lastError = error.localizedDescription
                }
            }
        }
    }
    
    public func toggle(preset: SessionPreset = .indefinite) {
        if isEnabled {
            disable()
        } else {
            enable(preset: preset)
        }
    }
    
    /// Checks `pmset -g` to see if sleep is actively disabled.
    public func checkLiveSystemSleepDisabled() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-g"]
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.localizedCaseInsensitiveContains("SleepDisabled 1") ||
                   output.localizedCaseInsensitiveContains("disablesleep 1")
        } catch {
            return false
        }
    }
    
    private func takePowerAssertion() {
        guard !hasActiveAssertion else { return }
        let reason = "OpenLid is preventing sleep while the MacBook lid is closed" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if result == kIOReturnSuccess {
            hasActiveAssertion = true
        }
    }
    
    private func releasePowerAssertion() {
        guard hasActiveAssertion else { return }
        IOPMAssertionRelease(assertionID)
        hasActiveAssertion = false
        assertionID = 0
    }
    
    /// Fail-safe cleanup to guarantee sleep is re-enabled when the app terminates.
    public func cleanup() {
        releasePowerAssertion()
        timer.stop()
        if isEnabled {
            try? PrivilegeManager.shared.setDisableSleep(enabled: false)
        }
    }
}
