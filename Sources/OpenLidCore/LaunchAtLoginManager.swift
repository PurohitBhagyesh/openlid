import Foundation
import ServiceManagement

/// Manages macOS Launch at Login and Auto-Awake behavior.
public final class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()
    
    private let awakeOnLoginKey = "com.openlid.awakeOnLogin"
    
    @Published public private(set) var isLaunchAtLoginEnabled: Bool = false
    @Published public var awakeOnLogin: Bool {
        didSet {
            UserDefaults.standard.set(awakeOnLogin, forKey: awakeOnLoginKey)
        }
    }
    
    private init() {
        self.awakeOnLogin = UserDefaults.standard.bool(forKey: awakeOnLoginKey)
        self.isLaunchAtLoginEnabled = checkLaunchAtLoginStatus()
    }
    
    public func checkLaunchAtLoginStatus() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    public func setLaunchAtLogin(enabled: Bool) throws {
        if #available(macOS 13.0, *) {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            DispatchQueue.main.async {
                self.isLaunchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
            }
        }
    }
    
    /// Triggered during application launch to automatically awake if requested.
    public func handleAppLaunch() {
        if awakeOnLogin {
            PowerManager.shared.enable(preset: .indefinite)
        }
    }
}

