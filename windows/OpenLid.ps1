# OpenLid for Windows — Native Dual App & System Tray Clamshell Sleep Prevention
# Usage: .\OpenLid.ps1 [-On | -Off | -Status | -App | -Welcome | -Tray | -Mode <tray|app|both>]

param (
    [switch]$On,
    [switch]$Off,
    [switch]$Status,
    [switch]$App,
    [switch]$Gui,
    [switch]$Welcome,
    [switch]$Tray,
    [string]$Mode = "",
    [int]$Duration = 0
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Set-LidAction([int]$action) {
    # 0 = Do Nothing (Keep Awake), 1 = Sleep (Default)
    powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION $action | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION $action | Out-Null
    powercfg /setactive SCHEME_CURRENT | Out-Null
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

function Launch-OpenLidGUI([string]$flag = "") {
    $csFile = Join-Path $scriptDir "OpenLidTray.cs"
    $exeFile = Join-Path $scriptDir "OpenLid.exe"
    
    if (-not (Test-Path $exeFile) -and (Test-Path $csFile)) {
        Write-Host "🔨 Compiling OpenLid for Windows with csc.exe..." -ForegroundColor Cyan
        $csc = Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) "csc.exe"
        if (Test-Path $csc) {
            & $csc /target:winexe /out:"$exeFile" /r:System.Windows.Forms.dll,System.Drawing.dll "$csFile" | Out-Null
        }
    }
    
    if (Test-Path $exeFile) {
        Start-Process $exeFile -ArgumentList $flag
    } else {
        # Fallback to direct PowerShell execution with WinForms
        Add-Type -Path $csFile -ReferencedAssemblies System.Windows.Forms,System.Drawing
        [OpenLid.Program]::Main(@($flag))
    }
}

if ($App -or $Gui) {
    Launch-OpenLidGUI "--app"
    exit
}

if ($Welcome) {
    Launch-OpenLidGUI "--welcome"
    exit
}

if ($Tray) {
    Launch-OpenLidGUI "--tray"
    exit
}

if ($Mode -ne "") {
    $validModes = @("tray", "app", "both")
    if ($validModes -contains $Mode.ToLower()) {
        $appDataDir = Join-Path $env:APPDATA "OpenLid"
        if (-not (Test-Path $appDataDir)) { New-Item -ItemType Directory -Path $appDataDir | Out-Null }
        $configFile = Join-Path $appDataDir "config.ini"
        "Mode=$($Mode.ToLower())`nOnboarded=True" | Set-Content $configFile
        Write-Host "✅ OpenLid presentation mode updated to: $Mode" -ForegroundColor Green
    } else {
        Write-Host "❌ Invalid mode. Choose from: tray, app, both" -ForegroundColor Red
    }
    exit
}

if ($Off) {
    Set-LidAction 1
    Write-Host "✅ OpenLid for Windows: STANDBY (Default sleep restored when lid closes)" -ForegroundColor Yellow
    exit
}

if ($Status) {
    Write-Host "================ OpenLid for Windows ================" -ForegroundColor Cyan
    Write-Host "• Platform: Windows 10 / Windows 11 (x64 / ARM64)"
    Write-Host "• Presentation Modes: System Tray, App Window, or Both"
    Write-Host "• Website:  https://openlid.devs.li"
    Write-Host "• Lid Sleep Action: Configured via powercfg & SetThreadExecutionState"
    Write-Host "=====================================================" -ForegroundColor Cyan
    exit
}

# Default CLI: Turn ON
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
