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
        
        // Start local REST control server for website and automations
        ControlServer.shared.start()
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
    }
}

