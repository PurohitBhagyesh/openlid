import SwiftUI
import AppKit
import OpenLidCore

public final class MainWindowManager: NSObject, NSWindowDelegate {
    public static let shared = MainWindowManager()
    
    private var windowController: NSWindowController?
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePresentationModeChanged(_:)),
            name: AppPreferences.presentationModeChangedNotification,
            object: nil
        )
    }
    
    @objc private func handlePresentationModeChanged(_ notification: Notification) {
        if let mode = notification.object as? AppPresentationMode {
            if mode == .windowedApp || mode == .both {
                DispatchQueue.main.async {
                    self.showMainWindow()
                }
            }
        }
    }
    
    @MainActor
    public func showMainWindow() {
        if let controller = windowController, let window = controller.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let mainView = MainWindowView()
        let hostingController = NSHostingController(rootView: mainView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 680),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "OpenLid"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.showsResizeIndicator = false
        // Strictly disable macOS fullscreen space & zoom
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
    public func closeMainWindow() {
        windowController?.window?.close()
    }
    
    public func windowWillClose(_ notification: Notification) {
        // Window closed
    }
}
