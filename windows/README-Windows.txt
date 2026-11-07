=========================================================
OpenLid for Windows (v1.0.0) — Clamshell Sleep Prevention
=========================================================

Keep your Windows laptop running with the lid closed — safely, smoothly, and without external monitors.

PRESENTATION MODES:
1. System Tray (Taskbar icon next to Windows clock)
2. Standalone Application Window
3. Both (System Tray + App Window)

HOW TO RUN:
• Double-click `openlid.cmd` or run `powershell -ExecutionPolicy Bypass -File .\OpenLid.ps1 -App`
• To run in background System Tray only: `powershell -ExecutionPolicy Bypass -File .\OpenLid.ps1 -Tray`
• To run via Command-Line / Terminal:
    - Enable:  `.\OpenLid.ps1 -On` (or `.\OpenLid.ps1 -On -Duration 30`)
    - Disable: `.\OpenLid.ps1 -Off`
    - Status:  `.\OpenLid.ps1 -Status`

Website:  https://openlid.devs.li
GitHub:   https://github.com/PurohitBhagyesh/openlid
License:  MIT License
=========================================================

