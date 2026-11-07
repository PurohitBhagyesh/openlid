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
  <a href="#features">Features</a> •
  <a href="#status-bar-indicators">Status Bar</a> •
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

**OpenLid solves this natively by modulating kernel power assertions on macOS (`kIOPMAssertionTypePreventSystemSleep` and `pmset`) and Windows (`SetThreadExecutionState` AwayMode & `powercfg LIDACTION 0`), backed by real-time thermal throttling breakers and battery floor margins.**

---

## Features

- **Ultra-Lightweight Footprint:** Under **2.5 MB** compiled Universal 2 Mach-O binary (< 700 KB compressed archive); uses less than **20 MB** of system RAM.
- **Native Menu Bar & Tray:** High-contrast template icons that automatically adapt to light/dark wallpaper themes.
- **Session Presets:** Choose between `∞ Always`, `15m`, `30m`, `1h`, and `2h` countdown timers without accidental truncation.
- **Hardware Sentinels:** 
  - **Thermal Sentinel:** Automatically drops sleep bypass if internal temperatures reach serious/critical thresholds.
  - **Battery Cutoff Floor:** Configurable minimum battery margin (default: 15%) so you never drain your laptop to zero when unplugged.
- **Instant Passwordless Elevation:** Touch ID-authorized scoped `/etc/sudoers.d/openlid` rule to toggle power states instantly without password prompts.
- **Local Telemetry REST API:** Runs on `127.0.0.1:31415` for instant status inspection from terminal, scripts, or the OpenLid web dashboard.
- **Cross-Platform:** Native Swift for macOS; zero-install C# and PowerShell for Windows 11/10 (x64 and Snapdragon ARM64).

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
| **Windows x64** | [Download `.zip`](downloads/OpenLid-Windows-x64.zip) | Intel Core & AMD Ryzen Laptops | `OpenLidTray.exe` + PowerShell Scripts |
| **Windows ARM64** | [Download `.zip`](downloads/OpenLid-Windows-ARM64.zip) | Snapdragon X Elite, Surface Pro ARM | `OpenLidTray.exe` + PowerShell Scripts |

```powershell
# Windows PowerShell Quick-Launch (Zero-Install)
powershell -Command ".\windows\OpenLid.ps1 -On"
```

---

## Status Bar Indicators

OpenLid lives natively in your status bar with an adaptive Unsleeping Eye symbol:

| State | macOS Menu Bar | Windows System Tray | Meaning |
| :--- | :---: | :---: | :--- |
| **Vigilant & Awake** | `eye.fill` (Open Eye) | Green Eye | OpenLid is ACTIVE. Your laptop continues running with the lid closed. |
| **Clamshell Running** | `eye.circle.fill` | Green Pulse Dot | Lid is physically closed; display backlight is off, but CPU and network operate at full speed. |
| **Default Sleep** | `eye.slash` (Closed Eye) | Dimmed Eye | Sleep assertions disengaged. Closing the lid will sleep your laptop normally. |

---

## CLI Usage

### macOS (`openlid`)

```bash
# Enable closed-lid sleep prevention
openlid on

# Enable for a specific duration
openlid on --duration 30m
openlid on -d 1h

# Check live hardware telemetry
openlid status

# Disable sleep prevention (return to default macOS sleep)
openlid off

# Toggle state
openlid toggle

# Install passwordless sudo helper for instant zero-prompt toggles
openlid helper install
```

### Windows (`OpenLid.ps1` / `openlid.cmd`)

```cmd
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
│   │   ├── ClamshellMonitor.swift   # Reads AppleClamshellState from IOPMrootDomain
│   │   ├── BatteryMonitor.swift     # IOPSCopyPowerSourcesInfo telemetry & cutoff
│   │   ├── ThermalMonitor.swift     # ProcessInfo.thermalState overheating guard
│   │   ├── SessionTimer.swift       # Countdown timer & duration presets
│   │   ├── LaunchAtLoginManager.swift# SMAppService & auto-awake on login
│   │   ├── PrivilegeManager.swift   # Sudoers helper & Touch ID elevation
│   │   ├── ControlServer.swift      # Local REST API on 127.0.0.1:31415
│   │   ├── ApplicationMover.swift   # Auto-prompts to move app to /Applications
│   │   └── PowerManager.swift       # Assertion coordinator & signal trap cleanup
│   ├── OpenLid/                     # macOS Menu Bar App (SwiftUI)
│   │   ├── OpenLidApp.swift         # MenuBarExtra window lifecycle
│   │   └── Views/                   # MenuBarView, SettingsView, StatusIconView
│   └── OpenLidCLI/                  # macOS Command-Line Interface (main.swift)
├── windows/                         # Windows Subsystem (11/10)
│   ├── OpenLidTray.cs               # Native C# System Tray app with AwayMode
│   ├── OpenLid.ps1                  # Zero-install PowerShell engine
│   └── openlid.cmd                  # Windows batch launcher
├── index.html                       # Product landing site with Eye theme switcher
├── style.css                        # Universal responsive design system
├── app.js                           # State manager & live telemetry client
├── downloads/                       # Direct distribution builds (.zip only)
└── scripts/
    ├── bundle.sh                    # Universal lipo compilation & ZIP packaging
    └── install.sh                   # System-wide installation
```

---

## Contact & Support

If you encounter any problem, bug, or have a feature request:

- **Lead Developer:** Bhagyesh Purohit
- **GitHub Profile:** [@PurohitBhagyesh](https://github.com/PurohitBhagyesh)
- **Email Directly:** [purohitunofficialbhagyesh@gmail.com](mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Support%20%2F%20Issue%20Report)
- **Issue Tracker:** [GitHub Issues](https://github.com/PurohitBhagyesh/openlid/issues)
- **Official Website:** [openlid.devs.li](https://openlid.devs.li)

---

## Hardware Safety Advisory

> [!CAUTION]
> Laptops dissipate a portion of heat through the keyboard and display hinge assembly. **Never** leave your laptop running intensive compute workloads with the lid closed inside a sealed backpack or sleeve without airflow. OpenLid incorporates automated thermal shutdowns, but physical ventilation is always required.

---

## License

Distributed under the [MIT License](LICENSE). Copyright (c) 2026 Bhagyesh Purohit.
