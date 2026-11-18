@echo off
setlocal
cd /d "%~dp0"

if "%~1"=="" goto do_help
if /i "%~1"=="app" goto launch_app
if /i "%~1"=="gui" goto launch_app
if /i "%~1"=="tray" goto launch_tray
if /i "%~1"=="install" goto do_install
if /i "%~1"=="uninstall" goto do_uninstall
if /i "%~1"=="off" goto do_off
if /i "%~1"=="on" goto do_on
if /i "%~1"=="status" goto do_status
if /i "%~1"=="help" goto do_help
if /i "%~1"=="-h" goto do_help
if /i "%~1"=="--help" goto do_help

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenLid.ps1" %*
exit /b %ERRORLEVEL%

:launch_app
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0OpenLid.ps1" -App
exit /b 0

:launch_tray
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0OpenLid.ps1" -Tray
exit /b 0

:do_install
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenLid.ps1" -Install
exit /b %ERRORLEVEL%

:do_uninstall
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenLid.ps1" -Uninstall
exit /b %ERRORLEVEL%

:do_off
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1
powercfg /setactive SCHEME_CURRENT
echo [OpenLid] Standby: Default sleep restored when lid is closed.
exit /b 0

:do_on
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setactive SCHEME_CURRENT
echo [OpenLid] ACTIVE: Laptop will stay awake with the lid closed.
echo Run "OpenLid.cmd off" to restore normal lid sleep.
exit /b 0

:do_status
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenLid.ps1" -Status
exit /b 0

:do_help
echo OpenLid for Windows v2.0.0 -- Clamshell Sleep Prevention
echo.
echo Usage:
echo   OpenLid.cmd            Launch OpenLid GUI and System Tray
echo   OpenLid.cmd on         Enable closed-lid wakefulness
echo   OpenLid.cmd off        Restore normal lid sleep behavior
echo   OpenLid.cmd status     Display status and platform info
echo   OpenLid.cmd tray       Launch in background system tray
echo   OpenLid.cmd install    Install to Programs folder with shortcuts
echo   OpenLid.cmd uninstall  Uninstall OpenLid and restore settings
exit /b 0

