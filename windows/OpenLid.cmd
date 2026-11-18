@echo off
setlocal
cd /d "%~dp0"

if not "%~1"=="" goto cli_mode

if exist "%~dp0app\OpenLid.exe" (
    start "" "%~dp0app\OpenLid.exe" --app
    exit /b 0
)

start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0app\OpenLid.ps1" -App
exit /b 0

:cli_mode
call "%~dp0app\openlid-cli.cmd" %*
exit /b %ERRORLEVEL%

