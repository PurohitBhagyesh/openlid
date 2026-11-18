@echo off
setlocal
title OpenLid Installer
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0app\OpenLid.ps1" -Install
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Installation failed with exit code %ERRORLEVEL%.
    pause
)
exit /b %ERRORLEVEL%

