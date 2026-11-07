import SwiftUI
import AppKit
import OpenLidCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup signal traps for graceful teardown
        signal(SIGINT) { _ in
            PowerManager.shared.cleanup()
            exit(0)
        }
        signal(SIGTERM) { _ in
            PowerManager.shared.cleanup()
            exit(0)
        }
        
        // Handle auto-awake on user login
        LaunchAtLoginManager.shared.handleAppLaunch()
        
        // Offer to move to /Applications if launched from Downloads
        ApplicationMover.promptToMoveToApplicationsIfNecessary()
        
        // Apply user's presentation mode preference (menu bar vs windowed vs both)
        AppPreferences.shared.applyPresentationMode()
        
        // If onboarding is not completed, or if mode is windowedApp or both, show the main window
        if !AppPreferences.shared.hasCompletedOnboarding ||
            AppPreferences.shared.presentationMode == .windowedApp ||
            AppPreferences.shared.presentationMode == .both {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                MainWindowManager.shared.showMainWindow()
            }
        }
        
        // Start local REST control server for website and automations
        ControlServer.shared.start()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            MainWindowManager.shared.showMainWindow()
        }
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        ControlServer.shared.stop()
        PowerManager.shared.cleanup()
    }
}

@main
struct OpenLidApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var powerManager = PowerManager.shared
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            StatusIconView(powerManager: powerManager)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Open Main Window") {
                    MainWindowManager.shared.showMainWindow()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Welcome Tutorial & Permissions...") {
                    AppPreferences.shared.resetOnboarding()
                    MainWindowManager.shared.showMainWindow()
                }
            }
            
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    SettingsWindowManager.shared.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
