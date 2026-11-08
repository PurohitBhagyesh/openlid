@echo off
:: ========================================================
::  OpenLid for Windows - One-Click Installer
::  Installs to %LOCALAPPDATA%\Programs\OpenLid
::  Creates Start Menu and Desktop Shortcuts
:: ========================================================
setlocal
title OpenLid Installer
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenLid.ps1" -Install
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Installation failed with exit code %ERRORLEVEL%.
    pause
)
exit /b %ERRORLEVEL%
