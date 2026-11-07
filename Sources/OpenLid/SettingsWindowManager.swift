import SwiftUI
import AppKit

final class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    
    private var windowController: NSWindowController?
    
    private override init() {
        super.init()
    }
    
    @MainActor
    func showSettings() {
        if let controller = windowController, let window = controller.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView(onDismiss: { [weak self] in
            self?.closeSettings()
        })
        
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 680),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "OpenLid Settings"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.showsResizeIndicator = false
        // Strictly disable fullscreen
        window.collectionBehavior = [.fullScreenNone]
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.delegate = self
        window.center()
        
        let controller = NSWindowController(window: window)
        self.windowController = controller
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @MainActor
    func closeSettings() {
        windowController?.window?.close()
    }
    
    func windowWillClose(_ notification: Notification) {
        // Keep window controller available for reopening
    }
}
