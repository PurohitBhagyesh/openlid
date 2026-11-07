# OpenLid 💻

> Keep your MacBook running at full throttle even when the lid is closed — safely, smoothly, and without an external monitor.

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue.svg)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 🎯 The Problem

By default, macOS forces your MacBook into sleep mode the moment you close the lid unless:
1. You are plugged into AC power **AND**
2. An external display is connected **AND**
3. An external keyboard/mouse is connected.

If you are listening to music, streaming audio/podcasts, running a dev server (Docker, Vite, Node, Python), training an ML model, or letting an AI coding agent work overnight, closing your laptop interrupts everything.

Standard idle-sleep utilities (like `caffeinate` or general keeping-awake apps) **cannot prevent sleep on lid close** because Apple treats clamshell closure as a hardware power event.

**OpenLid solves this natively and safely.**

---

## ✨ Features

- ⚡️ **Native Clamshell Sleep Prevention**: Run background tasks, dev servers, audio playback, downloads, and AI agents with the lid closed on battery or AC.
- 🎛 **Sleek Menu Bar Interface**: Lives in your macOS Menu Bar (`LSUIElement`). Quick toggle, duration selectors, and hardware telemetry in a single popover.
- 💻 **Companion CLI (`openlid`)**: Control OpenLid directly from your terminal or shell scripts (`openlid on`, `openlid off`, `openlid status`).
- ⏱ **Session Duration Presets**: Set it to run **Indefinitely**, or for **15 minutes**, **30 minutes**, **1 hour**, or **2 hours**.
- 🛡 **Low Battery Cutoff Guard**: Automatically restores normal sleep if battery drops below a configurable threshold (e.g. 15%) so your battery never unexpectedly drains.
- 🌡 **Thermal Overheating Protection**: Continuously monitors Apple Silicon / Intel thermal states (`ProcessInfo.thermalState`). If dangerous temperatures are detected, OpenLid instantly restores sleep to protect your hardware.
- ⚡️ **Zero-Friction Instant Toggle**: Includes a 1-click helper installer (`/etc/sudoers.d/openlid`) so you authorize once via Touch ID / admin password and never get prompted again.
- 🧹 **Fail-Safe Cleanup**: Signal handlers (`SIGINT`, `SIGTERM`) and app termination hooks automatically reset macOS power settings so your Mac is never stuck in a sleep-disabled state.

---

## 🚀 Quick Start

### 1. Build and Bundle

```bash
# Clone the repository
git clone https://github.com/your-username/openlid.git
cd openlid

# Build the release .app bundle and CLI tool
./scripts/bundle.sh
```

### 2. Launch or Install

To launch immediately:
```bash
open dist/OpenLid.app
```

To install `OpenLid.app` into `/Applications` and `openlid` CLI into `/usr/local/bin`:
```bash
./scripts/install.sh
```

---

## 🖥 Command Line Interface (`openlid`)

OpenLid includes a command-line tool `openlid` for developers and scripts:

```bash
# Enable closed-lid mode indefinitely
openlid on

# Enable closed-lid mode for a specific duration
openlid on --duration 30m
openlid on -d 1h

# Check live hardware, battery, and sleep status
openlid status

# Disable closed-lid mode (restore normal macOS sleep)
openlid off

# Toggle state
openlid toggle

# Install passwordless helper for zero-prompt toggles
openlid helper install
```

### Example `openlid status` output:
```text
================ OpenLid Status ================
• Closed-Lid Running: 🟢 ACTIVE (Lid close sleep prevented)
• Physical Lid:       🔒 CLOSED
• Power Source:       ⚡️ Connected to AC Power
• Battery Level:      94% (Charging ⚡️)
• Thermal State:      Nominal (Cool)
• Passwordless Helper: Installed ✅
================================================
```

---

## 🏗 Architecture

The project is structured into three clean Swift targets:

```text
openlid/
├── Package.swift
├── Sources/
│   ├── OpenLidCore/            # Core library (IOKit, Power, Thermal, Battery)
│   │   ├── ClamshellMonitor.swift  # Reads AppleClamshellState from IOPMrootDomain
│   │   ├── BatteryMonitor.swift    # IOKit.ps power source telemetry & cutoff
│   │   ├── ThermalMonitor.swift    # ProcessInfo thermal states & safety triggers
│   │   ├── SessionTimer.swift      # Countdown timer & duration presets
│   │   ├── PrivilegeManager.swift  # Sudoers helper & AppleScript elevation
│   │   └── PowerManager.swift      # Central orchestrator & fail-safe cleanup
│   ├── OpenLid/                # macOS Menu Bar Application (SwiftUI)
│   │   ├── OpenLidApp.swift        # App lifecycle & signal traps
│   │   └── Views/
│   │       ├── MenuBarView.swift   # Main popover interface & telemetry
│   │       ├── SettingsView.swift  # Safety & helper preferences
│   │       └── StatusIconView.swift# Dynamic menu bar icon & countdown
│   └── OpenLidCLI/             # Command-Line Utility
│       └── main.swift              # Terminal subcommands (on/off/status/helper)
├── Tests/
│   └── OpenLidCoreTests/       # Unit tests
└── scripts/
    ├── bundle.sh               # Compiles release binary and creates OpenLid.app
    └── install.sh              # Installs app to /Applications & CLI to /usr/local/bin
```

---

## ⚠️ Hardware Safety Note

MacBooks vent heat partially through the keyboard and display hinge assembly. 

> [!WARNING]
> **Never** leave your MacBook running heavy workloads with the lid closed inside an enclosed container, backpack, or sleeve. Ensure adequate airflow when using closed-lid mode. OpenLid includes built-in thermal guards, but physical ventilation is always required.

---

## 📄 License

MIT License. Feel free to use, modify, and distribute.
