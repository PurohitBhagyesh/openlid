import Foundation
import AppKit

public enum AppPresentationMode: String, CaseIterable, Identifiable {
    case menuBarOnly = "menubar"
    case windowedApp = "app"
    case both = "both"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .menuBarOnly: return "Menu Bar Icon Only"
        case .windowedApp: return "Application Window Only"
        case .both: return "Menu Bar + App Window (Recommended)"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .menuBarOnly: return "Discreet icon in the macOS menu bar; runs silently in the background."
        case .windowedApp: return "Standard application window with Dock icon."
        case .both: return "Full access: menu bar icon for quick toggles plus a standalone app window."
        }
    }
}

public final class AppPreferences: ObservableObject {
    public static let shared = AppPreferences()
    
    public static let presentationModeChangedNotification = Notification.Name("OpenLidPresentationModeChanged")
    
    private let modeKey = "openlid.appPresentationMode"
    private let onboardingKey = "openlid.hasCompletedOnboarding"
    
    @Published public var presentationMode: AppPresentationMode {
        didSet {
            UserDefaults.standard.set(presentationMode.rawValue, forKey: modeKey)
            DispatchQueue.main.async {
                self.applyPresentationMode()
                NotificationCenter.default.post(name: Self.presentationModeChangedNotification, object: self.presentationMode)
            }
        }
    }
    
    @Published public var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey)
        }
    }
    
    private init() {
        if let savedMode = UserDefaults.standard.string(forKey: modeKey),
           let mode = AppPresentationMode(rawValue: savedMode) {
            self.presentationMode = mode
        } else {
            self.presentationMode = .both
        }
        
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
    }
    
    @MainActor
    public func applyPresentationMode() {
        switch presentationMode {
        case .menuBarOnly:
            NSApp.setActivationPolicy(.accessory)
        case .windowedApp, .both:
            NSApp.setActivationPolicy(.regular)
        }
    }
    
    public func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
