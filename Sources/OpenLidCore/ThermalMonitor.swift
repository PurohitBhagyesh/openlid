import Foundation

/// Monitors system thermal state to prevent dangerous overheating in closed clamshell mode.
public final class ThermalMonitor: ObservableObject {
    public static let shared = ThermalMonitor()
    
    @Published public private(set) var thermalState: ProcessInfo.ThermalState = .nominal
    @Published public var thermalProtectionEnabled: Bool = true
    
    public var onOverheatingDetected: (() -> Void)?
    private var observer: NSObjectProtocol?
    
    public init() {
        self.thermalState = ProcessInfo.processInfo.thermalState
        setupNotification()
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupNotification() {
        observer = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateThermalState()
        }
    }
    
    public func updateThermalState() {
        let current = ProcessInfo.processInfo.thermalState
        DispatchQueue.main.async {
            self.thermalState = current
            if self.thermalProtectionEnabled && (current == .serious || current == .critical) {
                self.onOverheatingDetected?()
            }
        }
    }
    
    public var stateDescription: String {
        switch thermalState {
        case .nominal:
            return "Nominal (Cool)"
        case .fair:
            return "Fair (Warm)"
        case .serious:
            return "Serious (Hot)"
        case .critical:
            return "Critical (Danger)"
        @unknown default:
            return "Unknown"
        }
    }
    
    public var isDangerous: Bool {
        return thermalState == .serious || thermalState == .critical
    }
}
