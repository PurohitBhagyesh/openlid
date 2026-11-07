@echo off
setlocal
if "%1"=="off" (
    powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1
    powercfg /setactive SCHEME_CURRENT
    echo [OpenLid] Standby: Default sleep restored when lid is closed.
    exit /b 0
)

if "%1"=="status" (
    echo ================ OpenLid for Windows ================
    echo Platform: Windows 10 / Windows 11 (x64 / ARM64)
    echo Website:  https://openlid.devs.li
    echo =====================================================
    exit /b 0
)

powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setactive SCHEME_CURRENT

echo =====================================================
echo  OpenLid for Windows: ACTIVE (Eye Vigilant)
echo  Your laptop will continue running with the lid closed.
echo  Run "openlid.cmd off" to restore default sleep.
echo =====================================================

