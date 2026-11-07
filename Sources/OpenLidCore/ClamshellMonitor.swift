import Foundation
import IOKit

/// Monitors the physical clamshell (lid) state of the MacBook via IOKit.
public final class ClamshellMonitor: ObservableObject {
    public static let shared = ClamshellMonitor()
    
    @Published public private(set) var isLidClosed: Bool = false
    private var timer: Timer?
    
    public init() {
        updateLidState()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    public func startMonitoring() {
        guard timer == nil else { return }
        // Update immediately
        updateLidState()
        // Poll every 1.5 seconds for instant UI updates when lid opens or closes
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.updateLidState()
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    @discardableResult
    public func updateLidState() -> Bool {
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard entry != 0 else { return false }
        defer { IOObjectRelease(entry) }
        
        if let state = IORegistryEntryCreateCFProperty(entry, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool {
            let newValue = state
            if newValue != isLidClosed {
                DispatchQueue.main.async {
                    self.isLidClosed = newValue
                }
            }
            return newValue
        }
        return false
    }
}
