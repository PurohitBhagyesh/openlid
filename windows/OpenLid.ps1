# OpenLid for Windows — Native Dual App & System Tray Clamshell Sleep Prevention
# Usage: .\OpenLid.ps1 [-On | -Off | -Status | -App | -Welcome | -Tray | -Install | -Uninstall | -Mode <tray|app|both>]

param (
    [switch]$On,
    [switch]$Off,
    [switch]$Status,
    [switch]$App,
    [switch]$Gui,
    [switch]$Welcome,
    [switch]$Tray,
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$MoveToApplications,
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

function Get-CscCompiler {
    $candidates = @(
        (Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) "csc.exe"),
        "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
        "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Launch-OpenLidGUI([string]$flag = "") {
    $csFile = Join-Path $scriptDir "OpenLidTray.cs"
    $exeFile = Join-Path $scriptDir "OpenLid.exe"
    $icoFile = Join-Path $scriptDir "OpenLid.ico"
    
    if (-not (Test-Path $exeFile) -and (Test-Path $csFile)) {
        $csc = Get-CscCompiler
        if ($csc) {
            Write-Host "🔨 Compiling OpenLid for Windows with native csc.exe..." -ForegroundColor Cyan
            $iconArg = if (Test-Path $icoFile) { "/win32icon:`"$icoFile`"" } else { "" }
            $compileCmd = "& `"$csc`" /target:winexe /optimize+ /out:`"$exeFile`" $iconArg /r:System.Windows.Forms.dll,System.Drawing.dll,Microsoft.CSharp.dll `"$csFile`""
            Invoke-Expression $compileCmd | Out-Null
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

function Install-OpenLid {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  🚀 Installing OpenLid for Windows to Programs Folder   " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $targetDir = Join-Path $env:LOCALAPPDATA "Programs\OpenLid"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # Copy all essential files
    $files = @("OpenLidTray.cs", "OpenLid.ps1", "Launch-OpenLid.cmd", "Install-OpenLid.cmd", "Uninstall-OpenLid.cmd", "openlid.cmd", "README.txt", "OpenLid.ico")
    foreach ($f in $files) {
        $src = Join-Path $scriptDir $f
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $targetDir -Force
        }
    }
    
    # Pre-compile the executable in target directory
    $targetExe = Join-Path $targetDir "OpenLid.exe"
    $targetCs = Join-Path $targetDir "OpenLidTray.cs"
    $targetIco = Join-Path $targetDir "OpenLid.ico"
    $csc = Get-CscCompiler
    if ($csc -and (Test-Path $targetCs)) {
        $iconArg = if (Test-Path $targetIco) { "/win32icon:`"$targetIco`"" } else { "" }
        Invoke-Expression "& `"$csc`" /target:winexe /optimize+ /out:`"$targetExe`" $iconArg /r:System.Windows.Forms.dll,System.Drawing.dll,Microsoft.CSharp.dll `"$targetCs`"" | Out-Null
    }
    
    # Create Desktop & Start Menu Shortcuts via WScript.Shell
    try {
        $wscript = New-Object -ComObject WScript.Shell
        
        # Desktop Shortcut
        $desktopDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
        $deskShortcut = $wscript.CreateShortcut((Join-Path $desktopDir "OpenLid.lnk"))
        $deskShortcut.TargetPath = if (Test-Path $targetExe) { $targetExe } else { Join-Path $targetDir "Launch-OpenLid.cmd" }
        $deskShortcut.WorkingDirectory = $targetDir
        if (Test-Path $targetIco) { $deskShortcut.IconLocation = "$targetIco,0" }
        $deskShortcut.Description = "OpenLid - Keep your laptop running with lid closed"
        $deskShortcut.Save()
        
        # Start Menu Shortcut
        $startMenuDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)
        $startShortcut = $wscript.CreateShortcut((Join-Path $startMenuDir "OpenLid.lnk"))
        $startShortcut.TargetPath = if (Test-Path $targetExe) { $targetExe } else { Join-Path $targetDir "Launch-OpenLid.cmd" }
        $startShortcut.WorkingDirectory = $targetDir
        if (Test-Path $targetIco) { $startShortcut.IconLocation = "$targetIco,0" }
        $startShortcut.Description = "OpenLid - Keep your laptop running with lid closed"
        $startShortcut.Save()
    } catch {
        Write-Warning "Could not create Windows shell shortcuts: $_"
    }
    
    # Initialize configuration
    $appDataDir = Join-Path $env:APPDATA "OpenLid"
    if (-not (Test-Path $appDataDir)) { New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null }
    $configFile = Join-Path $appDataDir "config.ini"
    if (-not (Test-Path $configFile)) {
        "Mode=both`nOnboarded=False" | Set-Content $configFile
    }
    
    Write-Host "✅ Installation successful!" -ForegroundColor Green
    Write-Host "📍 Application Directory: $targetDir" -ForegroundColor White
    Write-Host "📍 Desktop Shortcut:      $desktopDir\OpenLid.lnk" -ForegroundColor White
    Write-Host "📍 Start Menu Shortcut:   $startMenuDir\OpenLid.lnk" -ForegroundColor White
    Write-Host "`n🚀 Launching OpenLid..." -ForegroundColor Cyan
    
    if (Test-Path $targetExe) {
        Start-Process $targetExe -ArgumentList "--app"
    } else {
        Start-Process (Join-Path $targetDir "Launch-OpenLid.cmd")
    }
}

function Uninstall-OpenLid {
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  🛑 Uninstalling OpenLid for Windows                     " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    
    # Restore default power settings
    Set-LidAction 1
    
    # Terminate running OpenLid instances
    Get-Process "OpenLid" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Remove shortcuts
    $desktopShortcut = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)) "OpenLid.lnk"
    if (Test-Path $desktopShortcut) { Remove-Item -Path $desktopShortcut -Force -ErrorAction SilentlyContinue }
    
    $startMenuShortcut = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)) "OpenLid.lnk"
    if (Test-Path $startMenuShortcut) { Remove-Item -Path $startMenuShortcut -Force -ErrorAction SilentlyContinue }
    
    # Remove program folder
    $targetDir = Join-Path $env:LOCALAPPDATA "Programs\OpenLid"
    if (Test-Path $targetDir) {
        Remove-Item -Path $targetDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "✅ OpenLid has been cleanly uninstalled." -ForegroundColor Green
    Write-Host "Normal Windows lid-close sleep behavior has been restored." -ForegroundColor White
}

if ($Install -or $MoveToApplications) {
    Install-OpenLid
    exit
}

if ($Uninstall) {
    Uninstall-OpenLid
    exit
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
