================================================================================
   OpenLid for Windows (v1.0.0) — Clamshell Sleep Prevention Manager
   Website: https://openlid.devs.li  •  GitHub: https://github.com/PurohitBhagyesh/openlid
================================================================================

Keep your Windows laptop running with the lid closed — smoothly, safely, and
without requiring external displays or dummy plugs.

--------------------------------------------------------------------------------
1. QUICK START
--------------------------------------------------------------------------------
• Double-click "Launch-OpenLid.cmd" to immediately start OpenLid in the background.
  An animated eye icon will appear in your system tray (next to the clock)
  and the main dashboard window will open.

• Double-click "Install-OpenLid.cmd" to permanently install OpenLid to your
  user Programs directory (%LOCALAPPDATA%\Programs\OpenLid) and create handy
  Desktop and Start Menu shortcuts.

--------------------------------------------------------------------------------
2. MOVE TO APPLICATIONS (PROGRAMS) FOLDER
--------------------------------------------------------------------------------
OpenLid offers seamless relocation when launched from your Downloads folder.
Clicking "Yes" when prompted automatically:
  [✓] Copies all files to %LOCALAPPDATA%\Programs\OpenLid
  [✓] Creates a Desktop shortcut with the custom OpenLid icon
  [✓] Adds OpenLid to your Start Menu
  [✓] Cleans up transient temporary files
  [✓] Relaunches cleanly without command prompt windows

--------------------------------------------------------------------------------
3. PRESENTATION MODES
--------------------------------------------------------------------------------
OpenLid supports 3 presentation modes:
  1. System Tray Only — Sits discreetly next to your Windows clock
  2. Standalone Application Window — Full dashboard with live telemetry
  3. Both (Recommended) — System tray icon + full windowed dashboard

You can switch modes anytime via the "Presentation Mode & Preferences..." button.

--------------------------------------------------------------------------------
4. COMMAND-LINE INTERFACE (CLI)
--------------------------------------------------------------------------------
Run via Command Prompt or PowerShell:
  openlid on                Enable sleep prevention indefinitely
  openlid on -Duration 30   Enable sleep prevention for 30 minutes
  openlid off               Disengage sleep prevention and restore default sleep
  openlid status            Display current power & lid telemetry
  openlid app               Launch full GUI dashboard
  openlid tray              Launch in system tray only
  openlid install           Install to user Programs folder
  openlid uninstall         Cleanly uninstall and restore default power rules

--------------------------------------------------------------------------------
5. ARCHITECTURAL DETAILS & SAFETY
--------------------------------------------------------------------------------
• Kernel AwayMode: Calls SetThreadExecutionState(ES_CONTINUOUS | ES_AWAYMODE_REQUIRED
  | ES_SYSTEM_REQUIRED) to keep CPU, network, downloads, and background servers
  active while allowing the display backlight to turn off cleanly.
• Hardware LIDACTION Override: Dynamically programs powercfg SUB_BUTTONS LIDACTION
  to prevent Windows ACPI lid closure from triggering Modern Standby or S3 sleep.
• Zero Bloat: Runs purely via native .NET / PowerShell components already built
  into Windows 10 and 11. No heavy electron runtimes or external dependencies.

--------------------------------------------------------------------------------
6. UNINSTALLATION
--------------------------------------------------------------------------------
Double-click "Uninstall-OpenLid.cmd" or run:
  .\OpenLid.ps1 -Uninstall
This immediately restores default Windows lid sleep settings and removes all
shortcuts and application files.

--------------------------------------------------------------------------------
SUPPORT & COMMUNITY
--------------------------------------------------------------------------------
• Official Website: https://openlid.devs.li
• GitHub:          https://github.com/PurohitBhagyesh/openlid
• Issue Tracker:   https://github.com/PurohitBhagyesh/openlid/issues
• Support Email:   purohitunofficialbhagyesh@gmail.com
================================================================================
