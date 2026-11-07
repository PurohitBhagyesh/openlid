import Foundation
import IOKit.ps

/// Monitors MacBook battery level, power source, and charging state.
public final class BatteryMonitor: ObservableObject {
    public static let shared = BatteryMonitor()
    
    @Published public private(set) var batteryPercent: Int = 100
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var isOnACPower: Bool = false
    @Published public private(set) var powerSourceName: String = "Unknown"
    
    /// Low battery threshold below which sleep prevention should be automatically aborted (e.g. 15%)
    @Published public var lowBatteryThreshold: Int = 15
    @Published public var lowBatteryCutoffEnabled: Bool = true
    
    private var timer: Timer?
    public var onLowBatteryThresholdReached: (() -> Void)?
    
    public init() {
        updateBatteryState()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    public func startMonitoring() {
        guard timer == nil else { return }
        updateBatteryState()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateBatteryState()
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    public func updateBatteryState() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }
        
        for ps in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            let percent = (desc[kIOPSCurrentCapacityKey as String] as? Int) ?? 100
            let charging = (desc[kIOPSIsChargingKey as String] as? Bool) ?? false
            let state = (desc[kIOPSPowerSourceStateKey as String] as? String) ?? "Battery Power"
            let isAC = (state == kIOPSACPowerValue as String)
            let name = (desc[kIOPSNameKey as String] as? String) ?? "Internal Battery"
            
            DispatchQueue.main.async {
                self.batteryPercent = percent
                self.isCharging = charging
                self.isOnACPower = isAC
                self.powerSourceName = name
                
                // Check safety threshold if on battery and cutoff enabled
                if self.lowBatteryCutoffEnabled && !isAC && percent <= self.lowBatteryThreshold {
                    self.onLowBatteryThresholdReached?()
                }
            }
            break
        }
    }
}

