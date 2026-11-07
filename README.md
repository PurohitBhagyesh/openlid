<div align="center">

```
   ██████╗ ██████╗ ███████╗███╗   ██╗██╗     ██╗██████╗ 
  ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██║     ██║██╔══██╗
  ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║██║  ██║
  ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║██║  ██║
  ╚██████╔╝██║     ███████╗██║ ╚████║███████╗██║██████╔╝
   ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝╚═════╝ 
```

### 👁️ The Unsleeping Eye for your MacBook

**Keep your Mac awake, running, and vigilant — even when the lid is closed.**

[![macOS](https://img.shields.io/badge/macOS-13.0%2B%20%7C%20Apple%20Silicon%20%26%20Intel-black?style=for-the-badge&logo=apple)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-10b981?style=for-the-badge)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-emerald?style=for-the-badge&logo=githubactions&logoColor=white)](.github/workflows/ci.yml)

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-menu-bar-eye-states">Eye States</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-cli-usage">CLI</a> •
  <a href="#-interactive-website">Website</a> •
  <a href="#-architecture">Architecture</a>
</p>

---

</div>

## 🌌 Overview

By default, closing your MacBook lid puts it to sleep instantly unless plugged into AC power with an external monitor and keyboard attached.

If you are:
- 🎧 **Streaming audio, podcasts, or music** to Bluetooth speakers or AirPods
- 🤖 **Running long AI inference, fine-tuning, or coding agents** (Claude Code, Ollama, OpenDevin)
- 🚀 **Hosting local dev servers, Docker containers, or Vite/Node environments**
- 📦 **Downloading massive datasets, game assets, or syncing backups**

...closing the lid interrupts everything. Standard utilities (`caffeinate`, etc.) cannot prevent clamshell closure sleep because Apple handles lid closure as a low-level hardware interrupt.

**OpenLid solves this with surgical power assertion management, hardware thermal guards, and an aesthetic status icon on your menu bar: the vigilant Eye.**

---

## 👁️ Menu Bar Eye States

OpenLid lives natively in your macOS Menu Bar represented by an adaptive Eye icon:

| Icon | State | Meaning |
| :---: | :---: | :--- |
| `👁️` (`eye.fill`) | **Vigilant & Awake** | OpenLid is ACTIVE. Your MacBook will continue running with the lid closed. |
| `👁️‍🗨️` (`eye.circle.fill`) | **Lid Closed & Running** | Physical lid is closed, screen is powered off, but CPU and tasks run at full speed. |
| `🚫` (`eye.slash`) | **Normal Sleep** | Default macOS sleep behavior restored. Closing the lid will sleep your Mac. |

---

## ✨ Features

- 👁️ **Vigilant Menu Bar Eye**: Sleek, distraction-free native SwiftUI interface.
- ⚡️ **Native Clamshell Sleep Bypass**: Keeps your system wide-awake without an external monitor.
- 🌡️ **Thermal Overheating Protection**: Continuously samples `ProcessInfo.processInfo.thermalState`. If system heat spikes to dangerous levels, sleep prevention automatically disengages to protect your screen and chassis.
- 🔋 **Smart Battery Cutoff**: Configurable battery floor (default 15%). Automatically aborts keep-awake mode if battery runs low, so you never wake up to an empty battery.
- ⏱️ **Session Timers**: Select **15m**, **30m**, **1h**, **2h**, or **Indefinite** sessions with a live countdown timer in the menu bar.
- 🚀 **Auto-Awake on Login**: Automatically launch on user login and optionally awaken your Mac immediately.
- 🔑 **1-Click Passwordless Helper**: Authorize once with Touch ID / admin password to write a scoped sudoers rule (`/etc/sudoers.d/openlid`). Future toggles happen in <50ms with zero dialogs.
- 🧹 **Fail-Safe Teardown**: Hooks into `SIGINT`, `SIGTERM`, and system shutdown to guarantee default sleep settings are restored.
- 💻 **Complete CLI (`openlid`)**: Automate and script sleep behavior from your terminal.

---

## 🚀 Quick Start

### 1. Build and Bundle

```bash
# Clone the repository
git clone https://github.com/PurohitBhagyesh/openlid.git
cd openlid

# Build the release .app bundle and CLI binary
./scripts/bundle.sh
```

### 2. Launch or Install

To launch immediately from the project:
```bash
open dist/OpenLid.app
```

To install permanently into `/Applications` and copy the CLI into `/usr/local/bin`:
```bash
./scripts/install.sh
```

---

## 💻 CLI Usage

OpenLid includes a command-line tool `openlid` that can be run from any terminal:

```bash
# Awaken your Mac indefinitely
openlid on

# Awaken your Mac for a specific session length
openlid on --duration 30m
openlid on -d 1h

# Check live telemetry and state
openlid status

# Put your Mac back to normal sleep behavior
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
• Battery Level:      94% (Charging ⚡️)
• Thermal State:      Nominal (Cool)
• Passwordless Helper: Installed ✅
================================================
```

---

## 🌐 Interactive Website & Simulator

OpenLid comes with a product website and interactive web simulator located in [`website/`](website):

- **Interactive Eye Simulator**: Toggle the virtual Eye, shut the virtual MacBook lid, and watch the simulated terminal keep streaming audio and running servers.
- **Login & Remote Awake Console**: Sign in to the demo cloud portal to manage and awaken your Mac remotely.
- **Preview Locally**: Run `./scripts/serve-website.sh` to preview at `http://localhost:8080`.

---

## 🏗 Architecture

```text
openlid/
├── Package.swift                    # Swift Package definition
├── Sources/
│   ├── OpenLidCore/                 # Core engine (IOKit, Power, Thermal, Battery)
│   │   ├── ClamshellMonitor.swift   # Reads AppleClamshellState from IOPMrootDomain
│   │   ├── BatteryMonitor.swift     # IOKit battery level, AC telemetry & cutoff
│   │   ├── ThermalMonitor.swift     # ProcessInfo.thermalState overheating guard
│   │   ├── SessionTimer.swift       # Countdown timer & duration presets
│   │   ├── LaunchAtLoginManager.swift# SMAppService & auto-awake on login
│   │   ├── PrivilegeManager.swift   # Sudoers helper & Touch ID elevation
│   │   └── PowerManager.swift       # Orchestrator & fail-safe teardown
│   ├── OpenLid/                     # macOS Menu Bar Application (SwiftUI)
│   │   ├── OpenLidApp.swift         # App lifecycle & signal traps
│   │   └── Views/
│   │       ├── MenuBarView.swift    # Popover with hero toggle, telemetry & presets
│   │       ├── SettingsView.swift   # Safety thresholds & helper installer
│   │       └── StatusIconView.swift # Vigilant Eye menu bar symbol & countdown
│   └── OpenLidCLI/                  # Command-Line Utility
│       └── main.swift               # Terminal subcommands (on/off/status/helper)
├── Tests/
│   └── OpenLidCoreTests/            # Unit test suite
├── website/                         # Aesthetic landing page, simulator & auth portal
│   ├── index.html
│   ├── style.css
│   └── app.js
└── scripts/
    ├── bundle.sh                    # Release bundling & ad-hoc code-signing
    ├── install.sh                   # System-wide installation script
    └── serve-website.sh             # Local preview web server
```

---

## ⚠️ Hardware Safety Advisory

> [!CAUTION]
> MacBooks dissipate heat partially through the keyboard and display hinge assembly. **Never** leave your MacBook running high-intensity tasks with the lid closed inside a tightly zippered backpack or sleeve. OpenLid features automatic thermal shutdowns, but physical airflow is always essential.

---

## 📜 License

Distributed under the [MIT License](LICENSE). Built for macOS developers and power users.
