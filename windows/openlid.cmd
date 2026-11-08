@echo off
:: ========================================================
::  OpenLid for Windows - Terminal & CLI Control
::  Usage:
::    openlid on          Enable lid sleep bypass
::    openlid off         Restore default lid sleep
::    openlid status      View current system status
::    openlid app         Open GUI app window
::    openlid tray        Run in system tray only
::    openlid install     Install to user Programs folder
::    openlid uninstall   Clean uninstall & restore sleep
:: ========================================================
setlocal
cd /d "%~dp0"

if "%1"=="" goto interactive
if /i "%1"=="app" goto launch_app
if /i "%1"=="gui" goto launch_app
if /i "%1"=="tray" goto launch_tray
if /i "%1"=="install" goto do_install
if /i "%1"=="uninstall" goto do_uninstall
if /i "%1"=="off" goto do_off
if /i "%1"=="on" goto do_on
if /i "%1"=="status" goto do_status
if /i "%1"=="help" goto do_help
if /i "%1"=="-h" goto do_help
if /i "%1"=="--help" goto do_help

:: Fall through to PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenLid.ps1" %*
exit /b %ERRORLEVEL%

:launch_app
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0OpenLid.ps1" -App
exit /b 0

:launch_tray
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0OpenLid.ps1" -Tray
exit /b 0

:do_install
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenLid.ps1" -Install
exit /b %ERRORLEVEL%

:do_uninstall
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenLid.ps1" -Uninstall
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
echo =====================================================
echo  OpenLid for Windows: ACTIVE (Eye Vigilant)
echo  Your laptop will continue running with the lid closed.
echo  Run "openlid off" to restore default sleep.
echo =====================================================
exit /b 0

:do_status
echo ================ OpenLid for Windows ================
echo Platform: Windows 10 / Windows 11 (x64 / ARM64)
echo Website:  https://openlid.devs.li
echo GitHub:   https://github.com/PurohitBhagyesh/openlid
echo =====================================================
exit /b 0

:do_help
echo OpenLid for Windows - Clamshell Sleep Prevention
echo.
echo Usage:
echo   openlid               Interactive menu / Launch GUI
echo   openlid on            Enable closed-lid wakefulness (CLI)
echo   openlid off           Restore normal lid sleep behavior
echo   openlid status        Display current status and platform info
echo   openlid app           Launch standalone GUI app window
echo   openlid tray          Launch in background system tray
echo   openlid install       Install OpenLid to Programs folder
echo   openlid uninstall     Uninstall OpenLid and restore settings
exit /b 0

:interactive
echo ========================================================
echo       OpenLid for Windows (v1.0.0)
echo       Clamshell Sleep Prevention Manager
echo ========================================================
echo [1] Launch OpenLid App (GUI + System Tray)
echo [2] Install OpenLid to Programs Folder (Desktop Shortcut)
echo [3] Enable Lid Sleep Bypass (Terminal On)
echo [4] Disable Lid Sleep Bypass (Restore Normal Sleep)
echo [5] Check Status
echo [6] Exit
echo.
set /p choice="Choose an option [1-6]: "
if "%choice%"=="1" goto launch_app
if "%choice%"=="2" goto do_install
if "%choice%"=="3" goto do_on
if "%choice%"=="4" goto do_off
if "%choice%"=="5" goto do_status
exit /b 0
