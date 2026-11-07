<div align="center">

```
   ██████╗ ██████╗ ███████╗███╗   ██╗██╗     ██╗██████╗ 
  ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██║     ██║██╔══██╗
  ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║██║  ██║
  ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║██║  ██║
  ╚██████╔╝██║     ███████╗██║ ╚████║███████╗██║██████╔╝
   ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝╚═════╝ 
```

### The Unsleeping Eye for macOS & Windows

**Keep your laptop awake, running, and vigilant — even when the lid is closed.**

[![Platform](https://img.shields.io/badge/Platforms-macOS%2013%2B%20%7C%20Windows%2011%2F10-black?style=for-the-badge&logo=apple&logoColor=white)](https://openlid.devs.li)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![Size](https://img.shields.io/badge/Size-%3C%202.5%20MB%20(Universal)-10b981?style=for-the-badge)](https://openlid.devs.li)
[![License: MIT](https://img.shields.io/badge/License-MIT-10b981?style=for-the-badge)](LICENSE)
[![Website](https://img.shields.io/badge/Website-openlid.devs.li-06b6d4?style=for-the-badge)](https://openlid.devs.li)

Developed with precision by **[Bhagyesh Purohit](https://github.com/PurohitBhagyesh)**

<p align="center">
  <a href="#downloads">Downloads</a> •
  <a href="#overview">Overview</a> •
  <a href="#presentation-modes">Presentation Modes</a> •
  <a href="#onboarding--permissions-flow">Onboarding</a> •
  <a href="#animated-vigilant-eye">Animated Eye</a> •
  <a href="#cli-usage">CLI</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#contact--support">Contact & Support</a>
</p>

---

</div>

## Overview

By default, closing your laptop lid puts macOS or Windows to sleep immediately unless plugged into AC power with an external monitor attached.

If you are:
- **Running local AI inference or coding agents** (Claude Code, Ollama, DeepSeek, OpenDevin)
- **Streaming audio or podcasts** to Bluetooth headphones or external speakers
- **Hosting local development servers, Docker containers, or builds**
- **Downloading large datasets or syncing background backups**

...closing the lid interrupts everything. Standard user-space utilities fail because the operating system treats lid closure as a low-level hardware interrupt.

**OpenLid solves this natively by modulating kernel power assertions on macOS (`kIOPMAssertionTypePreventSystemSleep` and `pmset`) and Windows (`SetThreadExecutionState` AwayMode & `powercfg LIDACTION 0`), backed by real-time thermal throttling breakers and native hardware sentinels.**

---

## Presentation Modes: Menu Bar / Taskbar vs. Standalone App Window

OpenLid is designed with complete user freedom. Both macOS and Windows provide three presentation modes selectable in Settings:

1. **Menu Bar / System Tray Only (Discreet Taskbar Mode):**
   - **macOS:** Operates as an `NSApplication.ActivationPolicy.accessory`. Lives quietly in the macOS menu bar without taking space in the Dock.
   - **Windows:** Minimizes to the notification area / system tray next to the Windows clock.
2. **Windowed App Only (Standard Dock / Taskbar Mode):**
   - **macOS:** Operates as a regular app with Dock icon and dedicated Main Application Window.
   - **Windows:** Standard desktop application window pinned to the Windows taskbar.
3. **Both (Menu Bar + Windowed App):**
   - Provides an instant status indicator and quick-toggle popover in the menu bar/system tray alongside a full application dashboard window.

Users can toggle between these modes at any time in **Settings → App Presentation Mode** or via the terminal using `openlid mode [menubar|app|both]`.

---

## Onboarding & Permissions Flow

On first launch (or when clicking **Re-run Welcome Tutorial & Permissions**), OpenLid greets users with a streamlined 3-step setup:

```
[ Step 1: Welcome to OpenLid ]
      ┌────────────────┐
      │  Animated Eye  │ ◄── Eyeball scans left-to-right continuously
      │   (3D Depth)   │
      └────────────────┘
    Welcome to OpenLid
  [ Get Started → ]
         │
         ▼
[ Step 2: Essential Permissions ]
  • Kernel Sleep Assertion (IOPMAssertion / Win32 Away Mode)
  • Clamshell Elevation Helper (sudoers Touch ID / powercfg)
  • IOPS Hardware Sentinel (Battery & Thermal Watchdog)
  [ Authorize & Install Helper ] ──► [ Continue → ]
         │
         ▼
[ Step 3: Choose Presentation Mode ]
  ( ) Menu Bar (Taskbar) Only
  ( ) Windowed App (Dock)
  (*) Both (Recommended)
  [ Enter OpenLid ]
         │
         ▼
[ Main Application UI & Dashboard ]
```

---

## Animated Vigilant Eye

When OpenLid is **Active & Awake**, the eye symbol features a live vigilance animation:
- **Horizontal Eyeball Scanning:** The glowing neon-emerald iris and pupil move smoothly from left to right and right to left, simulating continuous vigilance.
- **Glass Specular Light Reflection:** Layered 3D depth and specular highlight for an authentic hardware sentinel appearance.
- **Dynamic Transition:** When opening the menu or returning from Settings, the animated eye remains responsive and indicates active sleep prevention.
- **Sleep Mode:** When disengaged, the eye shows a subdued, slashed indicator indicating normal sleep is permitted.

---

## Downloads

Standalone portable ZIP archives compiled natively for each platform architecture (Zero DMG requirement):

### macOS (13.0 Ventura+)

| Architecture | Portable ZIP Archive | Target Hardware | Contents |
| :--- | :---: | :--- | :--- |
| **Apple Silicon** | [Download `.zip`](downloads/OpenLid-AppleSilicon.zip) | Apple Silicon (M1, M2, M3, M4 series) | `OpenLid.app` + `openlid` CLI |
| **Intel Processor** | [Download `.zip`](downloads/OpenLid-Intel.zip) | Intel MacBooks (Core i5, i7, i9) | `OpenLid.app` + `openlid` CLI |
| **Universal Binary** | [Download `.zip`](downloads/OpenLid-Universal.zip) | All MacBooks (Universal 2 Fat Mach-O) | `OpenLid.app` + `openlid` CLI |

```bash
# Homebrew Cask (macOS)
brew install --cask openlid
```

### Windows (11 / 10)

| Architecture | Standalone Archive | Target Hardware | Contents |
| :--- | :---: | :--- | :--- |
| **Windows x64** | [Download `.zip`](downloads/OpenLid-Windows-x64.zip) | Intel Core & AMD Ryzen Laptops | `OpenLidTray.cs` + `OpenLid.ps1` + `openlid.cmd` |
| **Windows ARM64** | [Download `.zip`](downloads/OpenLid-Windows-ARM64.zip) | Snapdragon X Elite, Surface Pro ARM | `OpenLidTray.cs` + `OpenLid.ps1` + `openlid.cmd` |

```powershell
# Windows PowerShell Quick-Launch (Zero-Install GUI)
powershell -ExecutionPolicy Bypass -Command ".\windows\OpenLid.ps1 -App"
```

---

## CLI Usage

### macOS (`openlid`)

```bash
# Enable closed-lid sleep prevention
openlid on

# Enable for a specific duration
openlid on --duration 30m
openlid on -d 1h

# Check live hardware telemetry & mode
openlid status

# Configure presentation mode (menubar, app, or both)
openlid mode menubar
openlid mode app
openlid mode both

# Launch standalone GUI application window
openlid app

# Re-run onboarding & permissions wizard
openlid welcome

# Disable sleep prevention (return to default macOS sleep)
openlid off

# Toggle state
openlid toggle

# Install passwordless sudo helper for instant zero-prompt toggles
openlid helper install
```

### Windows (`OpenLid.ps1` / `openlid.cmd`)

```cmd
:: Launch GUI Application Window
openlid.cmd app

:: Re-run Welcome Onboarding
openlid.cmd welcome

:: Set presentation mode
powershell -File .\OpenLid.ps1 -Mode both

:: Enable closed-lid sleep prevention
openlid.cmd on

:: Disable sleep prevention
openlid.cmd off

:: Check status
openlid.cmd status
```

---

## Architecture

```text
openlid/
├── Package.swift                    # Swift Package Manager manifest
├── Sources/
│   ├── OpenLidCore/                 # macOS Core Engine (IOKit, Power, Thermal, Battery)
│   │   ├── AppPreferences.swift     # Presentation mode (menubar vs app vs both) & onboarding state
│   │   ├── ClamshellMonitor.swift   # Reads AppleClamshellState from IOPMrootDomain
│   │   ├── BatteryMonitor.swift     # IOPSCopyPowerSourcesInfo power telemetry
│   │   ├── ThermalMonitor.swift     # ProcessInfo.thermalState overheating guard
│   │   ├── SessionTimer.swift       # Countdown timer & duration presets
│   │   ├── LaunchAtLoginManager.swift# SMAppService & auto-awake on login
│   │   ├── PrivilegeManager.swift   # Sudoers helper & Touch ID elevation
│   │   ├── ControlServer.swift      # Local REST API on 127.0.0.1:31415
│   │   ├── ApplicationMover.swift   # Auto-prompts to move app to /Applications
│   │   └── PowerManager.swift       # Assertion coordinator & signal trap cleanup
│   ├── OpenLid/                     # macOS Dual-Mode App (SwiftUI & AppKit)
│   │   ├── OpenLidApp.swift         # Lifecycle, activation policy & menu commands
│   │   ├── MainWindowManager.swift  # Standalone Application Window Controller
│   │   ├── SettingsWindowManager.swift # Settings Window Controller
│   │   └── Views/
│   │       ├── AnimatedEyeView.swift# 3D layered eye with scanning pupil animation
│   │       ├── OnboardingView.swift # 3-step Welcome & Permissions Wizard
│   │       ├── MainWindowView.swift # Full standalone GUI Application Window
│   │       ├── MenuBarView.swift    # Status bar popover with animated eye & tools
│   │       ├── SettingsView.swift   # Mode picker, thermal guards & developer contact
│   │       └── StatusIconView.swift # Menu bar template icon
│   └── OpenLidCLI/                  # macOS Command-Line Interface (main.swift)
├── windows/                         # Windows Subsystem (11/10)
│   ├── OpenLidTray.cs               # Native C# Dual GUI & Tray App with Animated Eye
│   ├── OpenLid.ps1                  # Zero-install PowerShell engine & launcher
│   ├── openlid.cmd                  # Windows batch launcher
│   └── README-Windows.txt           # Windows instructions
├── index.html                       # Product landing site with Eye theme switcher
├── style.css                        # Universal responsive design system
├── app.js                           # State manager, UPI detection & share widget
├── downloads/                       # Direct distribution builds (.zip only)
└── scripts/
    ├── bundle.sh                    # Universal lipo compilation & ZIP packaging
    └── install.sh                   # System-wide installation
```

---

## Contact & Support

If you encounter any problem, bug, or have a feature request:

- **Lead Developer:** OpenLid Developer
- **GitHub Profile:** [@PurohitBhagyesh](https://github.com/PurohitBhagyesh)
- **macOS Support Email:** [purohitunofficialbhagyesh@gmail.com](mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Problem%20Report%20(macOS)&body=Hi,%0D%0A%0D%0AI%20am%20reporting%20an%20issue%20with%20OpenLid%20for%20macOS:%0D%0A-%20Mac%20Model:%20%0D%0A-%20macOS%20Version:%20%0D%0A-%20Chip%20(Apple%20Silicon%20/%20Intel):%0D%0A-%20Issue%20Description:%20%0D%0A)
- **Windows Support Email:** [purohitunofficialbhagyesh@gmail.com](mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Problem%20Report%20(Windows)&body=Hi,%0D%0A%0D%0AI%20am%20reporting%20an%20issue%20with%20OpenLid%20for%20Windows:%0D%0A-%20Laptop%20Manufacturer%20&%20Model:%20%0D%0A-%20Windows%20Version:%20%0D%0A-%20Architecture:%20%0D%0A-%20Issue%20Description:%20%0D%0A)
- **Issue Tracker:** [GitHub Issues](https://github.com/PurohitBhagyesh/openlid/issues)
- **Official Website:** [openlid.devs.li](https://openlid.devs.li)

---

## Hardware Safety Advisory

> [!CAUTION]
> Laptops dissipate a portion of heat through the keyboard and display hinge assembly. **Never** leave your laptop running intensive compute workloads with the lid closed inside a sealed backpack or sleeve without airflow. OpenLid incorporates automated thermal shutdowns, but physical ventilation is always required.

---

## License

Distributed under the [MIT License](LICENSE). Copyright (c) 2026 OpenLid Contributors.

• Developed by [Bhagyesh Purohit](https://github.com/PurohitBhagyesh)
