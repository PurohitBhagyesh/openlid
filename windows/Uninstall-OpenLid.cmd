@echo off
:: ========================================================
::  OpenLid for Windows - Uninstaller
::  Restores default sleep and removes shortcuts & app
:: ========================================================
setlocal
title OpenLid Uninstaller
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenLid.ps1" -Uninstall
echo.
pause
exit /b %ERRORLEVEL%
