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
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "OpenLid Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(red: 0.047, green: 0.055, blue: 0.071, alpha: 1.0)
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.showsResizeIndicator = false
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
