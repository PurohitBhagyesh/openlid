import Foundation
import IOKit.ps

/// Monitors MacBook battery level, power source, and charging state with persistent safety cutoff thresholds.
public final class BatteryMonitor: ObservableObject {
    public static let shared = BatteryMonitor()
    
    private let thresholdKey = "openlid.lowBatteryThreshold"
    private let cutoffKey = "openlid.lowBatteryCutoffEnabled"
    
    @Published public private(set) var batteryPercent: Int = 100
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var isOnACPower: Bool = false
    @Published public private(set) var powerSourceName: String = "Unknown"
    
    /// Low battery threshold below which sleep prevention should be automatically aborted (e.g. 15%)
    @Published public var lowBatteryThreshold: Int {
        didSet {
            UserDefaults.standard.set(lowBatteryThreshold, forKey: thresholdKey)
        }
    }
    
    @Published public var lowBatteryCutoffEnabled: Bool {
        didSet {
            UserDefaults.standard.set(lowBatteryCutoffEnabled, forKey: cutoffKey)
        }
    }
    
    private var timer: Timer?
    public var onLowBatteryThresholdReached: (() -> Void)?
    
    public init() {
        let savedThreshold = UserDefaults.standard.integer(forKey: thresholdKey)
        self.lowBatteryThreshold = (savedThreshold >= 5 && savedThreshold <= 50) ? savedThreshold : 15
        
        if UserDefaults.standard.object(forKey: cutoffKey) != nil {
            self.lowBatteryCutoffEnabled = UserDefaults.standard.bool(forKey: cutoffKey)
        } else {
            self.lowBatteryCutoffEnabled = true
        }
        
        updateBatteryState()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    public func startMonitoring() {
        guard timer == nil else { return }
        updateBatteryState()
        // Poll every 4 seconds and also hook to common mode
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
                
                // Trigger safety cutoff if running on battery and charge drops to or below threshold
                if self.lowBatteryCutoffEnabled && !isAC && percent <= self.lowBatteryThreshold {
                    self.onLowBatteryThresholdReached?()
                }
            }
            break
        }
    }
}
