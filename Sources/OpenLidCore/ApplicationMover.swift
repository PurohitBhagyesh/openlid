import AppKit

/// Handles offering to move the application bundle to /Applications if run from Downloads or external volumes.
public final class ApplicationMover {
    public static func promptToMoveToApplicationsIfNecessary() {
        let bundlePath = Bundle.main.bundlePath
        let bundleURL = URL(fileURLWithPath: bundlePath)
        
        // Skip if already in /Applications or ~/Applications
        if bundlePath.hasPrefix("/Applications/") || bundlePath.hasPrefix(NSHomeDirectory() + "/Applications/") {
            return
        }
        
        // Skip if running from Xcode build or dev environment
        if bundlePath.contains("/.build/") || bundlePath.contains("/DerivedData/") {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let alert = NSAlert()
            alert.messageText = "Move to Applications Folder?"
            alert.informativeText = "OpenLid is running from your downloads folder. Would you like to move it to your Applications folder?"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Move to Applications")
            alert.addButton(withTitle: "Do Not Move")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                moveToApplications(from: bundleURL)
            }
        }
    }
    
    private static func moveToApplications(from sourceURL: URL) {
        let fileManager = FileManager.default
        let destinationURL = URL(fileURLWithPath: "/Applications").appendingPathComponent("OpenLid.app")
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            
            // Launch the new copy in /Applications
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: destinationURL, configuration: config) { _, _ in
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
            }
        } catch {
            print("Failed to move application: \(error.localizedDescription)")
        }
    }
}
