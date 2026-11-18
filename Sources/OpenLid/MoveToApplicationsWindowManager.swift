import SwiftUI
import AppKit
import OpenLidCore

public final class MoveToApplicationsWindowManager: NSObject, NSWindowDelegate {
    public static let shared = MoveToApplicationsWindowManager()
    
    private var windowController: NSWindowController?
    private var dismissCompletion: (() -> Void)?
    
    private override init() {
        super.init()
    }
    
    @MainActor
    public func showPrompt(force: Bool = false, onDismiss: (() -> Void)? = nil) {
        if !force && !ApplicationMover.shouldPromptOnLaunch() {
            onDismiss?()
            return
        }
        
        if let controller = windowController, let window = controller.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        self.dismissCompletion = onDismiss
        
        let view = MoveToApplicationsView { [weak self] in
            self?.closeWindow()
        }
        let hostingController = NSHostingController(rootView: view)
        hostingController.sizingOptions = []
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 286),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Move to Applications"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentViewController = hostingController
        window.setContentSize(NSSize(width: 380, height: 286))
        window.isReleasedWhenClosed = false
        window.showsResizeIndicator = false
        window.collectionBehavior = [.fullScreenNone, .moveToActiveSpace]
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.level = .floating
        window.delegate = self
        window.center()
        
        let controller = NSWindowController(window: window)
        self.windowController = controller
        
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    @MainActor
    public func closeWindow() {
        windowController?.window?.close()
    }
    
    public func windowWillClose(_ notification: Notification) {
        let cb = dismissCompletion
        dismissCompletion = nil
        windowController = nil
        DispatchQueue.main.async {
            cb?()
        }
    }
}
