import AppKit
import Darwin

/// Handles offering to move the application bundle to /Applications if run from Downloads, Desktop, or external volumes.
public final class ApplicationMover {
    public static let suppressionKey = "OpenLidSuppressMoveToApplicationsPrompt"
    
    /// Checks whether the application bundle is already located in an Applications directory.
    public static func isInstalledInApplications(url: URL = Bundle.main.bundleURL) -> Bool {
        let standardPath = url.standardized.path
        let userHome = NSHomeDirectory()
        
        if standardPath.hasPrefix("/Applications/") ||
           standardPath == "/Applications" ||
           standardPath.hasPrefix("/System/Applications/") ||
           standardPath.hasPrefix("\(userHome)/Applications/") {
            return true
        }
        
        let resolvedPath = url.resolvingSymlinksInPath().path
        if resolvedPath.hasPrefix("/Applications/") ||
           resolvedPath.hasPrefix("/System/Applications/") ||
           resolvedPath.hasPrefix("\(userHome)/Applications/") {
            return true
        }
        
        return false
    }
    
    /// Resolves the actual original bundle path if Gatekeeper app translocation is active.
    public static func resolveOriginalBundleURL(from url: URL = Bundle.main.bundleURL) -> URL {
        guard let handle = dlopen(nil, RTLD_NOW) else { return url }
        defer { dlclose(handle) }
        
        typealias SecTranslocateIsTranslocatedURLFunc = @convention(c) (CFURL, UnsafeMutablePointer<DarwinBoolean>?, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> DarwinBoolean
        typealias SecTranslocateCreateOriginalPathForURLFunc = @convention(c) (CFURL, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> Unmanaged<CFURL>?
        
        if let isTransPtr = dlsym(handle, "SecTranslocateIsTranslocatedURL"),
           let origPathPtr = dlsym(handle, "SecTranslocateCreateOriginalPathForURL") {
            let isTranslocatedFn = unsafeBitCast(isTransPtr, to: SecTranslocateIsTranslocatedURLFunc.self)
            let createOriginalFn = unsafeBitCast(origPathPtr, to: SecTranslocateCreateOriginalPathForURLFunc.self)
            
            var isTranslocated: DarwinBoolean = false
            let success = isTranslocatedFn(url as CFURL, &isTranslocated, nil)
            if success.boolValue && isTranslocated.boolValue {
                if let origCFURL = createOriginalFn(url as CFURL, nil) {
                    return origCFURL.takeRetainedValue() as URL
                }
            }
        }
        return url
    }
    
    /// Checks if currently running inside a build or development environment.
    public static func isDevOrBuildEnvironment(url: URL = Bundle.main.bundleURL) -> Bool {
        let path = url.path
        return path.contains("/.build/") ||
               path.contains("/DerivedData/") ||
               path.contains("/Debug/") ||
               (path.contains("/Release/") && path.contains("/openlid/"))
    }
    
    /// Prompts the user to relocate to /Applications on launch if needed.
    public static func promptToMoveToApplicationsIfNecessary() {
        let sourceURL = resolveOriginalBundleURL(from: Bundle.main.bundleURL)
        
        if isInstalledInApplications(url: sourceURL) {
            return
        }
        
        if isDevOrBuildEnvironment(url: sourceURL) {
            return
        }
        
        if UserDefaults.standard.bool(forKey: suppressionKey) {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            presentMoveAlert(sourceURL: sourceURL)
        }
    }
    
    /// Manually requests moving to Applications without respecting suppression (e.g. from Settings).
    public static func requestManualMoveToApplications(completion: ((Bool, Error?) -> Void)? = nil) {
        let sourceURL = resolveOriginalBundleURL(from: Bundle.main.bundleURL)
        
        if isInstalledInApplications(url: sourceURL) {
            let alert = NSAlert()
            alert.messageText = "Already in Applications"
            alert.informativeText = "OpenLid is already installed and running from your Applications directory."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            completion?(true, nil)
            return
        }
        
        moveToApplications(from: sourceURL, completion: completion)
    }
    
    private static func presentMoveAlert(sourceURL: URL) {
        let alert = NSAlert()
        alert.messageText = "Move OpenLid to Applications Folder?"
        alert.informativeText = "OpenLid works best when running from your Applications folder. Moving it keeps your Downloads directory clean and ensures full compatibility with macOS system power assertions, launch-at-login background agents, and clamshell sleep guards.\n\nWould you like to move OpenLid now?"
        alert.alertStyle = .informational
        
        let moveBtn = alert.addButton(withTitle: "Move to Applications Folder")
        moveBtn.keyEquivalent = "\r"
        
        let cancelBtn = alert.addButton(withTitle: "Do Not Move")
        cancelBtn.keyEquivalent = "\u{1b}"
        
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Do not ask again"
        
        if let icon = NSApplication.shared.applicationIconImage ?? NSImage(named: NSImage.applicationIconName) {
            alert.icon = icon
        }
        
        let response = alert.runModal()
        
        if alert.suppressionButton?.state == .on {
            UserDefaults.standard.set(true, forKey: suppressionKey)
        }
        
        if response == .alertFirstButtonReturn {
            moveToApplications(from: sourceURL)
        }
    }
    
    public static func moveToApplications(from sourceURL: URL, completion: ((Bool, Error?) -> Void)? = nil) {
        let fileManager = FileManager.default
        
        // Target directory: try /Applications first; if not writable, use ~/Applications
        var destDir = URL(fileURLWithPath: "/Applications")
        if !fileManager.isWritableFile(atPath: destDir.path) {
            if let userApps = fileManager.urls(for: .applicationDirectory, in: .userDomainMask).first {
                destDir = userApps
            } else {
                destDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications")
            }
        }
        
        // Ensure destination directory exists
        try? fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
        
        let bundleName = sourceURL.lastPathComponent.isEmpty ? "OpenLid.app" : sourceURL.lastPathComponent
        let destURL = destDir.appendingPathComponent(bundleName)
        
        do {
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            
            try fileManager.copyItem(at: sourceURL, to: destURL)
            
            // Strip quarantine flag so Gatekeeper accepts the relocated bundle
            let xattrProc = Process()
            xattrProc.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            xattrProc.arguments = ["-d", "-r", "com.apple.quarantine", destURL.path]
            try? xattrProc.run()
            xattrProc.waitUntilExit()
            
            // Clean up original source bundle from Downloads if different
            if sourceURL.path != destURL.path && !sourceURL.path.contains("/private/var/folders/") {
                try? fileManager.trashItem(at: sourceURL, resultingItemURL: nil)
            }
            
            // Relaunch new instance from Applications and terminate current instance
            let relaunchProc = Process()
            relaunchProc.executableURL = URL(fileURLWithPath: "/bin/sh")
            relaunchProc.arguments = [
                "-c",
                "sleep 0.3; /usr/bin/open \"$1\"",
                "--",
                destURL.path
            ]
            try relaunchProc.run()
            
            DispatchQueue.main.async {
                completion?(true, nil)
                NSApplication.shared.terminate(nil)
            }
        } catch {
            DispatchQueue.main.async {
                completion?(false, error)
                let errorAlert = NSAlert()
                errorAlert.messageText = "Unable to Move OpenLid"
                errorAlert.informativeText = "OpenLid could not be automatically moved to \(destDir.path):\n\(error.localizedDescription)\n\nYou can manually drag OpenLid.app into your Applications folder."
                errorAlert.alertStyle = .warning
                errorAlert.addButton(withTitle: "OK")
                errorAlert.runModal()
            }
        }
    }
}
