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
    }
    
    func applicationWillTerminate(_ notification: Notification) {
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
