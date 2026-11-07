import Foundation
import IOKit.ps

/// Monitors MacBook battery level, power source, and charging state for real-time telemetry.
public final class BatteryMonitor: ObservableObject {
    public static let shared = BatteryMonitor()
    
    @Published public private(set) var batteryPercent: Int = 100
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var isOnACPower: Bool = false
    @Published public private(set) var powerSourceName: String = "Unknown"
    
    private var timer: Timer?
    
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
        // Poll every 4 seconds and hook to common mode
        let t = Timer(timeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.updateBatteryState()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
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
            }
            break
        }
    }
}
