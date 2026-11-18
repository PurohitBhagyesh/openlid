@echo off
setlocal
title OpenLid Uninstaller
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0app\OpenLid.ps1" -Uninstall
echo.
pause
exit /b %ERRORLEVEL%

