import Foundation

public enum PrivilegeError: LocalizedError {
    case executionFailed(String)
    case cancelledByUser
    
    public var errorDescription: String? {
        switch self {
        case .executionFailed(let msg):
            return "Command execution failed: \(msg)"
        case .cancelledByUser:
            return "Authorization was cancelled by the user."
        }
    }
}

/// Manages elevated permissions required to toggle macOS closed-lid sleep settings.
public final class PrivilegeManager {
    public static let shared = PrivilegeManager()
    
    public static let sudoersPath = "/etc/sudoers.d/openlid"
    public static let pmsetBinary = "/usr/bin/pmset"
    public static let sudoBinary = "/usr/bin/sudo"
    
    private init() {}
    
    /// Checks whether the passwordless helper (sudoers configuration) is installed.
    public func isHelperInstalled() -> Bool {
        // Test if sudo can run pmset without password
        let task = Process()
        task.executableURL = URL(fileURLWithPath: Self.sudoBinary)
        task.arguments = ["-n", Self.pmsetBinary, "-g"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// Installs the passwordless sudoers helper for pmset so toggles are instantaneous.
    public func installHelper() throws {
        let username = NSUserName()
        let rule = "\(username) ALL=(ALL) NOPASSWD: \(Self.pmsetBinary) -a disablesleep *"
        let script = "echo '\(rule)' > \(Self.sudoersPath) && chmod 0440 \(Self.sudoersPath)"
        
        try runWithAdminPrivileges(command: script)
    }
    
    /// Removes the sudoers helper file.
    public func uninstallHelper() throws {
        let script = "rm -f \(Self.sudoersPath)"
        try runWithAdminPrivileges(command: script)
    }
    
    /// Sets `pmset -a disablesleep 1` or `0`.
    /// First attempts passwordless sudo. If helper is not installed, falls back to AppleScript Touch ID/admin prompt.
    public func setDisableSleep(enabled: Bool) throws {
        let val = enabled ? "1" : "0"
        let commandArgs = ["-a", "disablesleep", val]
        
        // 1. Try passwordless sudo
        let sudoTask = Process()
        sudoTask.executableURL = URL(fileURLWithPath: Self.sudoBinary)
        sudoTask.arguments = ["-n", Self.pmsetBinary] + commandArgs
        let errPipe = Pipe()
        sudoTask.standardError = errPipe
        
        do {
            try sudoTask.run()
            sudoTask.waitUntilExit()
            if sudoTask.terminationStatus == 0 {
                return // Success via helper!
            }
        } catch {
            // Sudo failed or threw, fall through to AppleScript
        }
        
        // 2. Fall back to osascript with administrator privileges
        let shellCmd = "\(Self.pmsetBinary) -a disablesleep \(val)"
        try runWithAdminPrivileges(command: shellCmd)
    }
    
    /// Executes a shell script via AppleScript with administrator privileges (Touch ID / password dialog).
    private func runWithAdminPrivileges(command: String) throws {
        let appleScriptText = "do shell script \"\(command)\" with administrator privileges"
        var errorDict: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScriptText) {
            scriptObject.executeAndReturnError(&errorDict)
            if let error = errorDict {
                let errorNumber = (error["NSAppleScriptErrorNumber"] as? Int) ?? 0
                if errorNumber == -128 { // User cancelled
                    throw PrivilegeError.cancelledByUser
                }
                let message = (error["NSAppleScriptErrorMessage"] as? String) ?? "Unknown AppleScript error"
                throw PrivilegeError.executionFailed(message)
            }
        } else {
            throw PrivilegeError.executionFailed("Failed to initialize NSAppleScript")
        }
    }
}
