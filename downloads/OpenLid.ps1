# OpenLid for Windows — Instant Clamshell Sleep Prevention
# Usage: .\OpenLid.ps1 [-On | -Off | -Status | -Tray]

param (
    [switch]$On,
    [switch]$Off,
    [switch]$Status,
    [switch]$Tray,
    [int]$Duration = 0
)

function Set-LidAction([int]$action) {
    # 0 = Do Nothing (Keep Awake), 1 = Sleep (Default)
    powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION $action
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION $action
    powercfg /setactive SCHEME_CURRENT
}

function Enable-AwayMode {
    $code = @"
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint SetThreadExecutionState(uint esFlags);
"@
    $ste = Add-Type -MemberDefinition $code -Name "Power" -Namespace "OpenLid" -PassThru -ErrorAction SilentlyContinue
    if ($ste) {
        # ES_CONTINUOUS (0x80000000) | ES_SYSTEM_REQUIRED (0x00000001) | ES_AWAYMODE_REQUIRED (0x00000040)
        [OpenLid.Power]::SetThreadExecutionState(0x80000041) | Out-Null
    }
}

if ($Off) {
    Set-LidAction 1
    Write-Host "✅ OpenLid for Windows: STANDBY (Default sleep restored when lid closes)" -ForegroundColor Yellow
    exit
}

if ($Status) {
    Write-Host "================ OpenLid for Windows ================" -ForegroundColor Cyan
    Write-Host "• Platform: Windows 10 / Windows 11 (x64 / ARM64)"
    Write-Host "• Website:  https://openlid.devs.li"
    Write-Host "• Lid Sleep Action: Configured via powercfg & SetThreadExecutionState"
    Write-Host "=====================================================" -ForegroundColor Cyan
    exit
}

# Default: Turn ON
Set-LidAction 0
Enable-AwayMode

Write-Host "=====================================================" -ForegroundColor Green
Write-Host "👁️  OpenLid for Windows is ACTIVE!" -ForegroundColor Green
Write-Host "Your laptop will continue running with the lid closed." -ForegroundColor White
Write-Host "Display backlight will turn off to save power, but CPU," -ForegroundColor Gray
Write-Host "network streaming, downloads, and servers will keep alive." -ForegroundColor Gray
Write-Host "=====================================================" -ForegroundColor Green

if ($Duration -gt 0) {
    Write-Host "⏱ Running timed session for $Duration minutes..." -ForegroundColor Cyan
    Start-Sleep -Seconds ($Duration * 60)
    Set-LidAction 1
    Write-Host "⏰ Session expired. Default sleep restored." -ForegroundColor Yellow
} else {
    Write-Host "Press Ctrl+C to stop OpenLid and restore default sleep." -ForegroundColor DarkGray
    try {
        while ($true) { Start-Sleep -Seconds 1 }
    } finally {
        Set-LidAction 1
        Write-Host "`n🛑 OpenLid stopped. Default sleep restored." -ForegroundColor Yellow
    }
}

