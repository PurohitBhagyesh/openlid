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
        
        // Apply user's presentation mode preference (menu bar vs windowed vs both)
        AppPreferences.shared.applyPresentationMode()
        
        let shouldShowMainWindow = !AppPreferences.shared.hasCompletedOnboarding ||
            AppPreferences.shared.presentationMode == .windowedApp ||
            AppPreferences.shared.presentationMode == .both
        
        // Offer modern Move-to-Applications flow first if running outside /Applications
        if ApplicationMover.shouldPromptOnLaunch() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                MoveToApplicationsWindowManager.shared.showPrompt(force: false) {
                    if shouldShowMainWindow {
                        MainWindowManager.shared.showMainWindow()
                    }
                }
            }
        } else if shouldShowMainWindow {
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
    @StateObject private var preferences = AppPreferences.shared
    
    var body: some Scene {
        MenuBarExtra(
            isInserted: Binding(
                get: { preferences.presentationMode != .windowedApp },
                set: { _ in }
            )
        ) {
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
                
                Button("Tutorial & Permissions...") {
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
