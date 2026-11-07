<div align="center">

```
   ██████╗ ██████╗ ███████╗███╗   ██╗██╗     ██╗██████╗ 
  ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██║     ██║██╔══██╗
  ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║██║  ██║
  ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║██║  ██║
  ╚██████╔╝██║     ███████╗██║ ╚████║███████╗██║██████╔╝
   ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝╚═════╝ 
```

### 👁️ The Unsleeping Eye for macOS & Windows

**Keep your laptop awake, running, and vigilant — even when the lid is closed.**

[![Platform](https://img.shields.io/badge/Platforms-macOS%2013%2B%20%7C%20Windows%2011%2F10-black?style=for-the-badge&logo=apple&logoColor=white)](https://openlid.devs.li)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![Windows](https://img.shields.io/badge/.NET%20%2F%20PowerShell-0078D4?style=for-the-badge&logo=windows&logoColor=white)](https://microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-10b981?style=for-the-badge)](LICENSE)
[![Website](https://img.shields.io/badge/Website-openlid.devs.li-06b6d4?style=for-the-badge)](https://openlid.devs.li)

<p align="center">
  <a href="#-downloads">Downloads</a> •
  <a href="#-features">Features</a> •
  <a href="#-macos-menu-bar">macOS Menu Bar</a> •
  <a href="#-windows-system-tray">Windows Tray</a> •
  <a href="#-cli-usage">CLI</a> •
  <a href="#-architecture">Architecture</a>
</p>

---

</div>

## 🌌 Overview

By default, closing your laptop lid puts macOS or Windows to sleep immediately unless plugged into AC power with an external monitor attached.

If you are:
- 🤖 **Running long local AI inference or coding agents** (Claude Code, Ollama, DeepSeek, OpenDevin)
- 🎧 **Streaming music or podcasts** to AirPods, Bluetooth speakers, or Sonos
- 🚀 **Hosting local dev servers, Docker containers, or Vite/Next.js builds**
- 📦 **Downloading massive datasets, game assets, or syncing background backups**

...closing the lid interrupts everything. Standard user-space utilities fail because the operating system treats lid closure as a low-level hardware interrupt.

**OpenLid solves this natively by modulating kernel power assertions on macOS (`kIOPMAssertionTypePreventSystemSleep` and `pmset`) and Windows (`SetThreadExecutionState` AwayMode & `powercfg LIDACTION 0`), backed by real-time thermal throttling breakers and battery floor margins.**

---

## 💾 Downloads

Download standalone, notarization-ready packages compiled natively for each platform architecture:

### 🍎 macOS
| Architecture | DMG Installer (Drag to Apps) | Portable ZIP Archive | Target Hardware |
| :--- | :---: | :---: | :--- |
| **Apple Silicon** | [Download `.dmg`](downloads/OpenLid-AppleSilicon.dmg) | [Download `.zip`](downloads/OpenLid-AppleSilicon.zip) | M1, M2, M3, M4, Pro, Max, Ultra |
| **Intel Processor** | [Download `.dmg`](downloads/OpenLid-Intel.dmg) | [Download `.zip`](downloads/OpenLid-Intel.zip) | Core i5, i7, i9 MacBooks |
| **Universal Binary** | [Download `.dmg`](downloads/OpenLid-Universal.dmg) | [Download `.zip`](downloads/OpenLid-Universal.zip) | Fat Mach-O (both architectures) |

```bash
# Homebrew Cask (macOS)
brew install --cask openlid
```

### 🪟 Windows (11 / 10)
| Architecture | Standalone Package | Target Hardware |
| :--- | :---: | :--- |
| **Windows x64** | [Download `.zip`](downloads/OpenLid-Windows-x64.zip) | Intel Core & AMD Ryzen Laptops |
| **Windows ARM64** | [Download `.zip`](downloads/OpenLid-Windows-ARM64.zip) | Snapdragon X Elite, Surface Pro ARM |

```powershell
# Windows PowerShell Quick-Launch (Zero-Install)
powershell -Command ".\windows\OpenLid.ps1 -On"
```

---

## 👁️ macOS Menu Bar & Windows System Tray

OpenLid lives natively in your status bar with an adaptive Unsleeping Eye symbol:

| State | macOS Menu Bar | Windows System Tray | Meaning |
| :--- | :---: | :---: | :--- |
| **Vigilant & Awake** | `👁️` (`eye.fill`) | 🟢 Glowing Eye | OpenLid is ACTIVE. Your laptop continues running with the lid closed. |
| **Clamshell Running** | `👁️‍🗨️` (`eye.circle.fill`) | 🟢 Pulse Dot | Lid is physically closed; display backlight is off, but CPU and network operate at full speed. |
| **Default Sleep** | `🚫` (`eye.slash`) | ⚪ Dimmed Eye | Sleep assertions disengaged. Closing the lid will sleep your laptop normally. |

---

## 💻 CLI Usage

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

## 🏗 Architecture

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
├── website/                         # WebGL 3D site & product showcase
│   ├── index.html                   # High-DPI SEO, OS switcher & 3D stage
│   ├── style.css                    # Dark glassmorphic theme & kinetic scroll
│   ├── app.js                       # Aesthetic scroll observer & OS switcher
│   └── 3d-viewer.js                 # Three.js 3D laptop physics engine
├── downloads/                       # Direct distribution builds (.dmg, .zip)
└── scripts/
    ├── bundle.sh                    # Universal lipo compilation & DMG creation
    ├── create_dmg.sh                # Drag-to-Applications disk image builder
    └── install.sh                   # System-wide installation
```

---

## ⚠️ Hardware Safety Advisory

> [!CAUTION]
> Laptops dissipate a portion of heat through the keyboard and display hinge assembly. **Never** leave your laptop running intensive compute workloads with the lid closed inside a sealed backpack or sleeve without airflow. OpenLid incorporates automated thermal shutdowns, but physical ventilation is always required.

---

## 📜 License

Distributed under the [MIT License](LICENSE). Copyright (c) 2026 Bhagyesh Purohit.
