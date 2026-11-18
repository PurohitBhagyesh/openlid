# OpenLid for Windows -- Native App, System Tray & CLI Clamshell Manager
# Usage: .\app\OpenLid.ps1 [-App | -Tray | -Welcome | -Install | -Uninstall | -On | -Off | -Status | -Duration <mins> | -Mode <tray|app|both>]

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

$ErrorActionPreference = "Stop"
$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$packageRoot = Split-Path -Parent $appDir
if (-not (Test-Path (Join-Path $packageRoot "OpenLid.cmd"))) {
    $packageRoot = $appDir
}

function Set-LidAction([int]$action) {
    # 0 = Do Nothing (Keep Awake), 1 = Sleep (Default)
    & powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION $action | Out-Null
    & powercfg.exe /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION $action | Out-Null
    & powercfg.exe /setactive SCHEME_CURRENT | Out-Null
}

function Enable-AwayMode {
    $code = @"
using System;
using System.Runtime.InteropServices;
namespace OpenLidNative {
    public static class Power {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern uint SetThreadExecutionState(uint esFlags);
    }
}
"@
    try {
        if (-not ("OpenLidNative.Power" -as [type])) {
            Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue | Out-Null
        }
        [OpenLidNative.Power]::SetThreadExecutionState(0x80000041) | Out-Null
    } catch { }
}

function Get-CscCompiler {
    $candidates = @(
        (Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) "csc.exe"),
        "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
        "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    )
    foreach ($p in $candidates) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    return $null
}

function Show-ErrorPopup([string]$title, [string]$message) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } catch {
        Write-Host "[ERROR] ${title}: $message" -ForegroundColor Red
    }
}

function Build-OpenLidExe([string]$sourceDir) {
    $csFile = Join-Path $sourceDir "OpenLidTray.cs"
    $exeFile = Join-Path $sourceDir "OpenLid.exe"
    $icoFile = Join-Path $sourceDir "OpenLid.ico"

    if (-not (Test-Path $csFile)) {
        throw "OpenLidTray.cs not found in $sourceDir"
    }

    $needsBuild = $true
    if (Test-Path $exeFile) {
        $csTime = (Get-Item $csFile).LastWriteTimeUtc
        $exeTime = (Get-Item $exeFile).LastWriteTimeUtc
        if ($exeTime -ge $csTime) {
            $needsBuild = $false
        }
    }

    if (-not $needsBuild) {
        return $exeFile
    }

    $csc = Get-CscCompiler
    if (-not $csc) {
        return $null
    }

    $cscArgs = @(
        "/nologo",
        "/target:winexe",
        "/optimize+",
        "/out:$exeFile",
        "/r:System.Windows.Forms.dll",
        "/r:System.Drawing.dll"
    )
    if (Test-Path $icoFile) {
        $cscArgs += "/win32icon:$icoFile"
    }
    $cscArgs += $csFile

    $buildOutput = & $csc @cscArgs 2>&1
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $exeFile)) {
        $logPath = Join-Path $env:TEMP "OpenLid-build.log"
        ($buildOutput | Out-String) | Set-Content -Path $logPath -Encoding UTF8
        throw "Native compilation failed (exit code $LASTEXITCODE). Details saved to: $logPath"
    }

    return $exeFile
}

function Launch-OpenLidGUI([string]$flag = "--app") {
    try {
        $exeFile = Build-OpenLidExe -sourceDir $appDir
        if ($exeFile -and (Test-Path $exeFile)) {
            Start-Process -FilePath $exeFile -ArgumentList $flag -WorkingDirectory $packageRoot
        } else {
            # Fallback to in-process WinForms execution if csc.exe is unavailable
            $csFile = Join-Path $appDir "OpenLidTray.cs"
            Add-Type -Path $csFile -ReferencedAssemblies @("System.Windows.Forms", "System.Drawing")
            [OpenLid.Program]::Main(@($flag))
        }
    } catch {
        Show-ErrorPopup -title "OpenLid Launch Error" -message ("Could not launch OpenLid:`r`n`r`n" + $_.Exception.Message)
        exit 1
    }
}

function Install-OpenLid {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  OpenLid for Windows -- Installing to Programs Folder    " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    $targetRoot = Join-Path $env:LOCALAPPDATA "Programs\OpenLid"
    $targetApp = Join-Path $targetRoot "app"

    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $targetApp -Force | Out-Null

    # Stop any existing running instance before copying over OpenLid.exe
    Get-Process -Name "OpenLid" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 200

    # Copy top-level launchers and readme
    $topFiles = @("OpenLid.cmd", "Install OpenLid.cmd", "Uninstall OpenLid.cmd", "README.txt")
    foreach ($f in $topFiles) {
        $src = Join-Path $packageRoot $f
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $targetRoot -Force
        }
    }

    # Copy internal app engine files
    $engineFiles = @("OpenLidTray.cs", "OpenLid.ps1", "OpenLid.ico", "openlid-cli.cmd")
    foreach ($f in $engineFiles) {
        $src = Join-Path $appDir $f
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $targetApp -Force
        }
    }

    Write-Host "[1/3] Compiling native Windows executable..." -ForegroundColor White
    $targetExe = Build-OpenLidExe -sourceDir $targetApp
    $targetIco = Join-Path $targetApp "OpenLid.ico"

    Write-Host "[2/3] Creating Desktop and Start Menu shortcuts..." -ForegroundColor White
    $launchTarget = if ($targetExe -and (Test-Path $targetExe)) { $targetExe } else { Join-Path $targetRoot "OpenLid.cmd" }
    $launchArgs = if ($targetExe -and (Test-Path $targetExe)) { "--app" } else { "" }

    try {
        $wscript = New-Object -ComObject WScript.Shell

        $desktopDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
        $deskSc = $wscript.CreateShortcut((Join-Path $desktopDir "OpenLid.lnk"))
        $deskSc.TargetPath = $launchTarget
        if ($launchArgs) { $deskSc.Arguments = $launchArgs }
        $deskSc.WorkingDirectory = $targetRoot
        if (Test-Path $targetIco) { $deskSc.IconLocation = "$targetIco,0" }
        $deskSc.Description = "OpenLid - Keep your laptop running with the lid closed"
        $deskSc.Save()

        $startMenuDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)
        $startSc = $wscript.CreateShortcut((Join-Path $startMenuDir "OpenLid.lnk"))
        $startSc.TargetPath = $launchTarget
        if ($launchArgs) { $startSc.Arguments = $launchArgs }
        $startSc.WorkingDirectory = $targetRoot
        if (Test-Path $targetIco) { $startSc.IconLocation = "$targetIco,0" }
        $startSc.Description = "OpenLid - Keep your laptop running with the lid closed"
        $startSc.Save()
    } catch {
        Write-Warning "Could not create Windows shortcuts: $_"
    }

    Write-Host "[3/3] Launching OpenLid..." -ForegroundColor White
    Write-Host ""
    Write-Host "[OK] OpenLid installed successfully!" -ForegroundColor Green
    Write-Host "  Location:    $targetRoot" -ForegroundColor Gray
    Write-Host "  Start Menu:  OpenLid" -ForegroundColor Gray
    Write-Host "  Desktop:     OpenLid" -ForegroundColor Gray

    if ($targetExe -and (Test-Path $targetExe)) {
        Start-Process -FilePath $targetExe -ArgumentList "--app" -WorkingDirectory $targetRoot
    } else {
        Start-Process -FilePath (Join-Path $targetRoot "OpenLid.cmd") -WorkingDirectory $targetRoot
    }
}

function Uninstall-OpenLid {
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  OpenLid for Windows -- Uninstalling                     " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow

    Set-LidAction 1
    Get-Process -Name "OpenLid" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 250

    $desktopSc = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)) "OpenLid.lnk"
    if (Test-Path $desktopSc) { Remove-Item -Path $desktopSc -Force -ErrorAction SilentlyContinue }

    $startSc = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)) "OpenLid.lnk"
    if (Test-Path $startSc) { Remove-Item -Path $startSc -Force -ErrorAction SilentlyContinue }

    $targetRoot = Join-Path $env:LOCALAPPDATA "Programs\OpenLid"
    if (Test-Path $targetRoot) {
        Remove-Item -Path $targetRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "[OK] OpenLid has been uninstalled." -ForegroundColor Green
    Write-Host "Default Windows lid-close sleep behavior has been restored." -ForegroundColor White
}

if ($Install -or $MoveToApplications) {
    Install-OpenLid
    exit 0
}

if ($Uninstall) {
    Uninstall-OpenLid
    exit 0
}

if ($App -or $Gui) {
    Launch-OpenLidGUI "--app"
    exit 0
}

if ($Welcome) {
    Launch-OpenLidGUI "--welcome"
    exit 0
}

if ($Tray) {
    Launch-OpenLidGUI "--tray"
    exit 0
}

if ($Mode -ne "") {
    $validModes = @("tray", "app", "both")
    if ($validModes -contains $Mode.ToLower()) {
        $appDataDir = Join-Path $env:APPDATA "OpenLid"
        if (-not (Test-Path $appDataDir)) { New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null }
        $configFile = Join-Path $appDataDir "config.ini"
        "Mode=$($Mode.ToLower())`r`nOnboarded=True" | Set-Content -Path $configFile
        Write-Host "[OK] OpenLid presentation mode updated to: $Mode" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Invalid mode. Choose from: tray, app, both" -ForegroundColor Red
        exit 1
    }
    exit 0
}

if ($Off) {
    Set-LidAction 1
    Write-Host "[OK] OpenLid STANDBY: Default sleep restored when lid closes." -ForegroundColor Yellow
    exit 0
}

if ($Status) {
    Write-Host "================ OpenLid for Windows ================" -ForegroundColor Cyan
    Write-Host "  Platform: Windows 10 / Windows 11 (x64 / ARM64)"
    Write-Host "  Modes:    System Tray, App Window, or Both"
    Write-Host "  Website:  https://openlid.devs.li"
    Write-Host "=====================================================" -ForegroundColor Cyan
    exit 0
}

# Default CLI: Turn ON
Set-LidAction 0
Enable-AwayMode

Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  OpenLid for Windows is ACTIVE" -ForegroundColor Green
Write-Host "  Your laptop will stay awake with the lid closed." -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor Green

if ($Duration -gt 0) {
    Write-Host "Running timed session for $Duration minutes..." -ForegroundColor Cyan
    Start-Sleep -Seconds ($Duration * 60)
    Set-LidAction 1
    Write-Host "Session expired. Default sleep restored." -ForegroundColor Yellow
} else {
    Write-Host "Press Ctrl+C to stop OpenLid and restore default sleep." -ForegroundColor Gray
    try {
        while ($true) { Start-Sleep -Seconds 1 }
    } finally {
        Set-LidAction 1
        Write-Host "`nOpenLid stopped. Default sleep restored." -ForegroundColor Yellow
    }
}

