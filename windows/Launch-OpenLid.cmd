@echo off
:: ========================================================
::  Launch OpenLid for Windows
::  Launches GUI App & System Tray silently in background
:: ========================================================
setlocal
cd /d "%~dp0"
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0OpenLid.ps1" -App
exit /b 0
