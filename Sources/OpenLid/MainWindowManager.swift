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
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "OpenLid"
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
    public func closeMainWindow() {
        windowController?.window?.close()
    }
    
    public func windowWillClose(_ notification: Notification) {
        // Keep window controller available
    }
}
