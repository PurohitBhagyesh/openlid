import AppKit
import Darwin

public enum ApplicationMoveStage: Equatable {
    case idle
    case copying
    case authorizing
    case cleaningUp
    case relaunching
    case failed(String)
}

/// Handles detecting whether OpenLid is running outside /Applications and relocating it reliably.
public final class ApplicationMover {
    public static let suppressionKey = "OpenLidSuppressMoveToApplicationsPrompt"
    
    /// Checks whether the application bundle is already located in an Applications directory.
    public static func isInstalledInApplications(url: URL = Bundle.main.bundleURL) -> Bool {
        let original = resolveOriginalBundleURL(from: url)
        let candidates = [
            url.standardized.path,
            url.resolvingSymlinksInPath().path,
            original.standardized.path,
            original.resolvingSymlinksInPath().path
        ]
        let userAppsPrefix = NSHomeDirectory() + "/Applications/"
        
        for path in candidates {
            if path.hasPrefix("/Applications/") ||
               path == "/Applications" ||
               path.hasPrefix("/System/Applications/") ||
               path.hasPrefix(userAppsPrefix) {
                return true
            }
        }
        return false
    }
    
    /// Resolves the actual original bundle path if Gatekeeper App Translocation is active.
    public static func resolveOriginalBundleURL(from url: URL = Bundle.main.bundleURL) -> URL {
        guard let handle = dlopen(nil, RTLD_NOW) else { return url }
        defer { dlclose(handle) }
        
        typealias SecTranslocateIsTranslocatedURLFunc = @convention(c) (
            CFURL,
            UnsafeMutablePointer<DarwinBoolean>?,
            UnsafeMutablePointer<Unmanaged<CFError>?>?
        ) -> DarwinBoolean
        
        typealias SecTranslocateCreateOriginalPathForURLFunc = @convention(c) (
            CFURL,
            UnsafeMutablePointer<Unmanaged<CFError>?>?
        ) -> Unmanaged<CFURL>?
        
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
    
    /// Checks if currently running inside an Xcode / SwiftPM build directory.
    public static func isDevOrBuildEnvironment(url: URL = Bundle.main.bundleURL) -> Bool {
        let path = url.path
        return path.contains("/.build/") ||
               path.contains("/DerivedData/") ||
               path.contains("/Xcode/Products/") ||
               path.hasSuffix("/OpenLid") // raw executable without .app bundle
    }
    
    /// Returns true if the app should prompt the user on launch to move into /Applications.
    public static func shouldPromptOnLaunch(url: URL = Bundle.main.bundleURL) -> Bool {
        if isInstalledInApplications(url: url) {
            return false
        }
        if isDevOrBuildEnvironment(url: url) {
            return false
        }
        if UserDefaults.standard.bool(forKey: suppressionKey) {
            return false
        }
        return true
    }
    
    /// Persists the "Do not ask again" preference.
    public static func setPromptSuppressed(_ suppressed: Bool) {
        UserDefaults.standard.set(suppressed, forKey: suppressionKey)
    }
    
    /// Returns a human-readable label for where the app is currently running from.
    public static func currentLocationDescription(url: URL = Bundle.main.bundleURL) -> String {
        let resolved = resolveOriginalBundleURL(from: url)
        let path = resolved.deletingLastPathComponent().path
        let home = NSHomeDirectory()
        if path.hasPrefix(home + "/Downloads") {
            return "Downloads"
        } else if path.hasPrefix(home + "/Desktop") {
            return "Desktop"
        } else if path.hasPrefix("/Volumes/") {
            return "Disk Image"
        } else if path.hasPrefix(home) {
            return path.replacingOccurrences(of: home, with: "~")
        }
        return path
    }
    
    /// Relocates the running `.app` bundle into `/Applications` (with admin fallback if needed),
    /// strips quarantine flags, cleans up Downloads/Desktop copies, and relaunches cleanly.
    public static func relocateToApplications(
        bundleURL: URL = Bundle.main.bundleURL,
        onStageChange: @escaping (ApplicationMoveStage) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            // Always copy from the live running bundleURL (readable even under Gatekeeper translocation)
            let copySourceURL = bundleURL
            let originalSourceURL = resolveOriginalBundleURL(from: bundleURL)
            
            let bundleName: String = {
                let name = originalSourceURL.lastPathComponent
                return name.hasSuffix(".app") ? name : "OpenLid.app"
            }()
            
            let systemAppsDir = URL(fileURLWithPath: "/Applications", isDirectory: true)
            let destURL = systemAppsDir.appendingPathComponent(bundleName)
            
            DispatchQueue.main.async { onStageChange(.copying) }
            
            // Terminate any OTHER running instance already at destURL before replacing
            terminateOtherInstances(at: destURL)
            
            // Step 1: Attempt direct user-space copy via temporary staging directory for atomicity
            var copiedSuccessfully = false
            var lastError: Error?
            
            if fileManager.isWritableFile(atPath: systemAppsDir.path) {
                let stagingURL = systemAppsDir.appendingPathComponent(".\(bundleName).staging-\(UUID().uuidString)")
                do {
                    try copyBundleWithDitto(from: copySourceURL, to: stagingURL)
                    stripQuarantine(at: stagingURL)
                    
                    if fileManager.fileExists(atPath: destURL.path) {
                        try fileManager.removeItem(at: destURL)
                    }
                    try fileManager.moveItem(at: stagingURL, to: destURL)
                    copiedSuccessfully = true
                } catch {
                    try? fileManager.removeItem(at: stagingURL)
                    lastError = error
                }
            }
            
            // Step 2: Fallback to macOS administrator authorization if /Applications or existing bundle is protected
            if !copiedSuccessfully {
                DispatchQueue.main.async { onStageChange(.authorizing) }
                do {
                    try copyBundleWithAdminPrivileges(from: copySourceURL, to: destURL)
                    copiedSuccessfully = true
                } catch {
                    lastError = error
                }
            }
            
            // Step 3: Fallback to ~/Applications if admin prompt was declined or unavailable
            var finalURL = destURL
            if !copiedSuccessfully {
                let userAppsDir = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
                    .appendingPathComponent("Applications", isDirectory: true)
                let userDestURL = userAppsDir.appendingPathComponent(bundleName)
                do {
                    try fileManager.createDirectory(at: userAppsDir, withIntermediateDirectories: true)
                    if fileManager.fileExists(atPath: userDestURL.path) {
                        try fileManager.removeItem(at: userDestURL)
                    }
                    try copyBundleWithDitto(from: copySourceURL, to: userDestURL)
                    stripQuarantine(at: userDestURL)
                    finalURL = userDestURL
                    copiedSuccessfully = true
                } catch {
                    // Keep the original /Applications error if ~/Applications also fails
                    lastError = lastError ?? error
                }
            }
            
            guard copiedSuccessfully else {
                let err = lastError ?? NSError(
                    domain: "OpenLid.ApplicationMover",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Could not copy OpenLid into Applications."]
                )
                DispatchQueue.main.async {
                    onStageChange(.failed(err.localizedDescription))
                    completion(.failure(err))
                }
                return
            }
            
            // Step 4: Clean up original bundle ONLY if it lived in Downloads or Desktop
            DispatchQueue.main.async { onStageChange(.cleaningUp) }
            if shouldTrashOriginalBundle(originalSourceURL, destination: finalURL) {
                try? fileManager.trashItem(at: originalSourceURL, resultingItemURL: nil)
            }
            
            // Step 5: Relaunch cleanly after current PID finishes terminating
            DispatchQueue.main.async { onStageChange(.relaunching) }
            do {
                try relaunchAfterExit(at: finalURL)
                DispatchQueue.main.async {
                    completion(.success(finalURL))
                    // Give UI a brief moment to show "Relaunching..." before terminating
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        NSApplication.shared.terminate(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    onStageChange(.failed("Moved successfully, but could not relaunch automatically: \(error.localizedDescription)"))
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Only recycle the original bundle when it was unpacked in Downloads or Desktop (avoid deleting dev dist/ builds).
    internal static func shouldTrashOriginalBundle(_ originalURL: URL, destination: URL) -> Bool {
        let origPath = originalURL.standardized.path
        let destPath = destination.standardized.path
        guard origPath != destPath else { return false }
        guard !origPath.contains("/private/var/folders/") else { return false }
        guard !origPath.hasPrefix("/Volumes/") else { return false }
        
        let home = NSHomeDirectory()
        return origPath.hasPrefix(home + "/Downloads/") ||
               origPath.hasPrefix(home + "/Desktop/")
    }
    
    private static func terminateOtherInstances(at targetURL: URL) {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let targetPath = targetURL.standardized.path
        for app in NSWorkspace.shared.runningApplications {
            guard app.processIdentifier != currentPID else { continue }
            if let appURL = app.bundleURL, appURL.standardized.path == targetPath {
                app.terminate()
            }
        }
    }
    
    /// Uses Apple's `ditto` to preserve code signatures, symlinks, and extended attributes cleanly.
    private static func copyBundleWithDitto(from source: URL, to destination: URL) throws {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        proc.arguments = [source.path, destination.path]
        let errPipe = Pipe()
        proc.standardError = errPipe
        try proc.run()
        proc.waitUntilExit()
        
        if proc.terminationStatus != 0 {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "ditto failed"
            throw NSError(
                domain: "OpenLid.ApplicationMover",
                code: Int(proc.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: errMsg]
            )
        }
    }
    
    private static func stripQuarantine(at url: URL) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        proc.arguments = ["-dr", "com.apple.quarantine", url.path]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        try? proc.run()
        proc.waitUntilExit()
    }
    
    private static func shellEscape(_ path: String) -> String {
        return "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
    
    private static func copyBundleWithAdminPrivileges(from source: URL, to destination: URL) throws {
        let src = shellEscape(source.path)
        let dst = shellEscape(destination.path)
        let shellCmd = "rm -rf \(dst) && /usr/bin/ditto \(src) \(dst) && /usr/bin/xattr -dr com.apple.quarantine \(dst) || true"
        let escapedForAppleScript = shellCmd
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let script = "do shell script \"\(escapedForAppleScript)\" with administrator privileges"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        let errPipe = Pipe()
        proc.standardError = errPipe
        try proc.run()
        proc.waitUntilExit()
        
        if proc.terminationStatus != 0 || !FileManager.default.fileExists(atPath: destination.path) {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Administrator authorization failed"
            throw NSError(
                domain: "OpenLid.ApplicationMover",
                code: Int(proc.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: errMsg]
            )
        }
    }
    
    /// Spawns a detached shell helper that waits for the current process PID to exit completely,
    /// then opens the relocated application bundle with `-n` so LaunchServices always boots the new copy.
    private static func relaunchAfterExit(at destination: URL) throws {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let script = """
        PID=\(currentPID)
        DEST="$1"
        TRIES=0
        while kill -0 "$PID" 2>/dev/null && [ "$TRIES" -lt 60 ]; do
            sleep 0.1
            TRIES=$((TRIES + 1))
        done
        sleep 0.15
        /usr/bin/open -n "$DEST"
        """
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/sh")
        proc.arguments = ["-c", script, "--", destination.path]
        proc.standardInput = FileHandle.nullDevice
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try proc.run()
    }
}
