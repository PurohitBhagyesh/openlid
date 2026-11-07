import Foundation
import OpenLidCore

func printHelp() {
    print("""
    OpenLid CLI - Keep your MacBook running with the lid closed

    USAGE:
        openlid <command> [options]

    COMMANDS:
        on, enable         Keep MacBook awake even when the lid is closed
                           Options: --duration, -d <15m|30m|1h|2h|indefinite>
        off, disable       Restore normal macOS sleep behavior
        toggle             Toggle closed-lid awake state
        status             Show live lid, battery, thermal, and sleep status
        helper install     Install passwordless sudo helper for instant toggling
        helper uninstall   Remove passwordless sudo helper
        help, -h, --help   Show this help message

    EXAMPLES:
        openlid on
        openlid on --duration 30m
        openlid off
        openlid status
        openlid helper install
    """)
}

func parseDuration(_ raw: String) -> SessionPreset {
    switch raw.lowercased() {
    case "15m", "15min", "15": return .min15
    case "30m", "30min", "30": return .min30
    case "1h", "60m", "60": return .hour1
    case "2h", "120m", "120": return .hour2
    default: return .indefinite
    }
}

let args = CommandLine.arguments

guard args.count > 1 else {
    printHelp()
    exit(0)
}

let command = args[1].lowercased()

switch command {
case "on", "enable":
    var preset: SessionPreset = .indefinite
    if let dIdx = args.firstIndex(of: "--duration") ?? args.firstIndex(of: "-d"), dIdx + 1 < args.count {
        preset = parseDuration(args[dIdx + 1])
    }
    
    print("⏳ Enabling OpenLid (duration: \(preset.title))...")
    do {
        try PrivilegeManager.shared.setDisableSleep(enabled: true)
        print("✅ OpenLid is ACTIVE! Your MacBook will continue running with the lid closed.")
        if preset != .indefinite, let dur = preset.duration {
            print("⏱ Session will run for \(Int(dur / 60)) minutes.")
        }
    } catch {
        print("❌ Error enabling OpenLid: \(error.localizedDescription)")
        exit(1)
    }

case "off", "disable":
    print("⏳ Disabling OpenLid...")
    do {
        try PrivilegeManager.shared.setDisableSleep(enabled: false)
        print("✅ Normal macOS sleep behavior restored.")
    } catch {
        print("❌ Error disabling OpenLid: \(error.localizedDescription)")
        exit(1)
    }

case "toggle":
    let isCurrentlyDisabled = PowerManager.shared.checkLiveSystemSleepDisabled()
    if isCurrentlyDisabled {
        print("⏳ Disabling OpenLid...")
        try? PrivilegeManager.shared.setDisableSleep(enabled: false)
        print("✅ OpenLid is now INACTIVE. Normal sleep restored.")
    } else {
        print("⏳ Enabling OpenLid...")
        try? PrivilegeManager.shared.setDisableSleep(enabled: true)
        print("✅ OpenLid is now ACTIVE. Mac will run with lid closed.")
    }

case "status":
    let isSleepDisabled = PowerManager.shared.checkLiveSystemSleepDisabled()
    let isLidClosed = ClamshellMonitor.shared.isLidClosed
    let battery = BatteryMonitor.shared
    let thermal = ThermalMonitor.shared
    let helperInstalled = PrivilegeManager.shared.isHelperInstalled()
    
    print("""
    ================ OpenLid Status ================
    • Closed-Lid Running: \(isSleepDisabled ? "🟢 ACTIVE (Lid close sleep prevented)" : "⚪️ INACTIVE (Normal sleep)")
    • Physical Lid:       \(isLidClosed ? "🔒 CLOSED" : "📖 OPEN")
    • Power Source:       \(battery.isOnACPower ? "⚡️ Connected to AC Power" : "🔋 Battery (\(battery.batteryPercent)%)")
    • Battery Level:      \(battery.batteryPercent)% \(battery.isCharging ? "(Charging ⚡️)" : "")
    • Thermal State:      \(thermal.stateDescription)
    • Passwordless Helper:\(helperInstalled ? " Installed ✅" : " Not Installed (Admin prompt used) ⚠️")
    ================================================
    """)

case "helper":
    guard args.count > 2 else {
        print("Usage: openlid helper [install|uninstall]")
        exit(1)
    }
    let sub = args[2].lowercased()
    if sub == "install" {
        print("⏳ Installing passwordless sudo helper for OpenLid...")
        do {
            try PrivilegeManager.shared.installHelper()
            print("✅ Helper successfully installed at /etc/sudoers.d/openlid!")
            print("🎉 You can now toggle OpenLid instantly with zero password prompts.")
        } catch {
            print("❌ Failed to install helper: \(error.localizedDescription)")
            exit(1)
        }
    } else if sub == "uninstall" {
        print("⏳ Removing passwordless sudo helper...")
        do {
            try PrivilegeManager.shared.uninstallHelper()
            print("✅ Helper successfully removed.")
        } catch {
            print("❌ Failed to remove helper: \(error.localizedDescription)")
            exit(1)
        }
    } else {
        print("Unknown helper command: \(sub)")
        exit(1)
    }

case "help", "-h", "--help":
    printHelp()

default:
    print("Unknown command: '\(command)'")
    printHelp()
    exit(1)
}

