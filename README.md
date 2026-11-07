<div align="center">

```
   ██████╗ ██████╗ ███████╗███╗   ██╗██╗     ██╗██████╗ 
  ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██║     ██║██╔══██╗
  ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║██║  ██║
  ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║██║  ██║
  ╚██████╔╝██║     ███████╗██║ ╚████║███████╗██║██████╔╝
   ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝╚═════╝ 
```

### 👁️ The Unsleeping Eye for macOS

**Keep your MacBook awake, running, and vigilant — even when the lid is closed.**

[![macOS](https://img.shields.io/badge/macOS-13.0%2B%20%7C%20Apple%20Silicon%20%26%20Intel-black?style=for-the-badge&logo=apple)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-10b981?style=for-the-badge)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-emerald?style=for-the-badge&logo=githubactions&logoColor=white)](.github/workflows/ci.yml)
[![Website](https://img.shields.io/badge/Website-openlid.devs.li-06b6d4?style=for-the-badge)](https://openlid.devs.li)

<p align="center">
  <a href="#-downloads">Downloads</a> •
  <a href="#-3d-clamshell-simulator">3D Simulator</a> •
  <a href="#-menu-bar-eye-states">Eye States</a> •
  <a href="#-cli-usage">CLI</a> •
  <a href="#-architecture">Architecture</a> •
  <a href="#-hardware-safety">Safety</a>
</p>

---

</div>

## 🌌 Overview

By default, closing your MacBook lid puts macOS to sleep immediately unless the laptop is connected to AC power with an external monitor and keyboard attached.

If you are:
- 🤖 **Running long local AI inference or coding agents** (Claude Code, Ollama, DeepSeek, OpenDevin)
- 🎧 **Streaming music or podcasts** to AirPods or Bluetooth speakers
- 🚀 **Hosting local dev servers, Docker containers, or Vite/Next.js builds**
- 📦 **Downloading massive datasets, game assets, or syncing background backups**

...closing the lid interrupts everything. Standard user-space utilities (`caffeinate`, `NSProcessInfo.beginActivity`) fail because macOS handles lid closure as a hardware interrupt within `IOPMrootDomain`.

**OpenLid solves this natively by modulating kernel power assertions (`kIOPMAssertionTypePreventSystemSleep` and `pmset -a disablesleep 1`), backed by real-time thermal throttling breakers and battery floor margins.**

---

## 💾 Downloads

Download standalone, notarization-ready packages compiled natively for your processor:

| Architecture | DMG Installer (Drag to Apps) | Portable ZIP Archive | Target Hardware |
| :--- | :---: | :---: | :--- |
| **Apple Silicon** | [Download `.dmg`](downloads/OpenLid-AppleSilicon.dmg) | [Download `.zip`](downloads/OpenLid-AppleSilicon.zip) | M1, M2, M3, M4, Pro, Max, Ultra |
| **Intel Processor** | [Download `.dmg`](downloads/OpenLid-Intel.dmg) | [Download `.zip`](downloads/OpenLid-Intel.zip) | Core i5, i7, i9 MacBooks |
| **Universal Binary** | [Download `.dmg`](downloads/OpenLid-Universal.dmg) | [Download `.zip`](downloads/OpenLid-Universal.zip) | Fat Mach-O (both architectures) |

### Package Manager (Homebrew)
```bash
brew install --cask openlid
```

---

## 🎮 3D Clamshell Simulator

OpenLid includes an interactive **3D WebGL Clamshell Simulator** on the official website:
👉 **[https://openlid.devs.li](https://openlid.devs.li)** *(fallback: [openlid.vercel.app](https://openlid.vercel.app))*

- **360° Physics Orbit**: Click and drag to inspect the MacBook chassis, ports, and display assembly.
- **Hinge Angle Controls**: Slide between 0° (Closed Clamshell) and 125° (Fully Open).
- **Dual Engine Simulation**: Observe the difference between default macOS sleep (display cuts off, execution stops) and OpenLid vigilance (emerald status pulse, continuous kernel execution).

---

## 👁️ Menu Bar Eye States

OpenLid lives in your macOS menu bar with an adaptive SF Symbol Eye icon:

| Icon | State | Meaning |
| :---: | :---: | :--- |
| `👁️` (`eye.fill`) | **Vigilant & Awake** | OpenLid is ACTIVE. Your MacBook continues running with the lid closed. |
| `👁️‍🗨️` (`eye.circle.fill`) | **Clamshell Running** | Lid is physically closed, display backlight is off, but CPU and network operate at full speed. |
| `🚫` (`eye.slash`) | **Default Sleep** | Sleep assertions disengaged. Closing the lid will sleep your Mac normally. |

---

## ✨ Features

- 👁️ **Adaptive Menu Bar Eye**: Real-time visual feedback and quick-access popover.
- ⚡️ **Hardware Clamshell Bypass**: Keep your laptop active without dummy HDMI dongles or external displays.
- 🌡️ **Thermal Protection Breaker**: Continuously samples `ProcessInfo.processInfo.thermalState`. Automatically drops assertions if system thermal pressure hits `.serious` or `.critical`.
- 🔋 **Configurable Battery Margin**: Automatically disengages if battery drops below your chosen safety floor (default 15%).
- ⏱️ **Preset Session Timers**: Timed sessions for 15m, 30m, 1h, 2h, or Indefinite with live countdown.
- 🚀 **Auto-Awake on Login**: Native `SMAppService` launch-at-login integration.
- 🔑 **Touch ID Sudo Helper**: Authorize once with Touch ID to install `/etc/sudoers.d/openlid` for &lt;30ms toggles without popups.
- 🛡️ **Signal Trap Cleanups**: Hooks `SIGINT`, `SIGTERM`, and abnormal termination to guarantee kernel sleep settings are cleanly restored.
- 💻 **Complete CLI (`openlid`)**: Full command-line interface for terminal workflows and Raycast shortcuts.

---

## 💻 CLI Usage

The bundled CLI tool `openlid` provides scriptable control:

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

### Sample `openlid status` Output:
```text
================ OpenLid Status ================
• Closed-Lid Running: 🟢 ACTIVE (Eye Vigilant)
• Physical Lid:       🔒 CLOSED
• Power Source:       ⚡️ Connected to AC Power
• Battery Level:      96% (Charging ⚡️)
• Thermal State:      Nominal (Cool)
• Passwordless Helper: Installed ✅
================================================
```

---

## 🏗 Architecture

```text
openlid/
├── Package.swift                    # Swift Package Manager manifest
├── Sources/
│   ├── OpenLidCore/                 # Core engine (IOKit, Power, Thermal, Battery)
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
│   │   └── Views/
│   │       ├── MenuBarView.swift    # Popover with master toggle & telemetry
│   │       ├── SettingsView.swift   # Dedicated settings with back navigation
│   │       └── StatusIconView.swift # Vigilant Eye menu bar symbol
│   └── OpenLidCLI/                  # Command-Line Interface
│       └── main.swift               # Terminal commands (on/off/status/helper)
├── website/                         # Un-slopped product site with 3D simulator
│   ├── index.html                   # Semantic markup & WebGL container
│   ├── style.css                    # Dark glassmorphic theme & kinetic scroll
│   ├── app.js                       # Aesthetic scroll observer & local REST bridge
│   └── 3d-viewer.js                 # Three.js 3D MacBook physics engine
└── scripts/
    ├── bundle.sh                    # Universal lipo compilation & DMG creation
    ├── create_dmg.sh                # Drag-to-Applications disk image builder
    └── install.sh                   # System-wide installation
```

---

## ⚠️ Hardware Safety Advisory

> [!CAUTION]
> MacBooks dissipate a portion of heat through the keyboard and display hinge assembly. **Never** leave your MacBook running intensive compute tasks with the lid closed inside a sealed backpack or sleeve without airflow. OpenLid incorporates automated thermal shutdowns, but physical ventilation is always required.

---

## 📜 License

Distributed under the [MIT License](LICENSE). Copyright (c) 2026 Bhagyesh Purohit.
