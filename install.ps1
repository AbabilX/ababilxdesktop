# ==============================================================================
# AbabilX Desktop PowerShell Installer (Windows)
#
# Quick Run:
#   irm https://raw.githubusercontent.com/AbabilX/ababilxdesktopfile/main/install.ps1 | iex
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║             🚀  AbabilX Desktop Installer             ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path 2>$null
$localInstaller = $null

if ($scriptDir) {
    $exeCandidate = Get-ChildItem -Path (Join-Path $scriptDir "desktopapp") -Recurse -Filter "*setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    $msiCandidate = Get-ChildItem -Path (Join-Path $scriptDir "desktopapp") -Recurse -Filter "*.msi" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($exeCandidate) {
        $localInstaller = $exeCandidate.FullName
    } elseif ($msiCandidate) {
        $localInstaller = $msiCandidate.FullName
    }
}

if ($localInstaller) {
    Write-Host "✔ Found local installer: $localInstaller" -ForegroundColor Green
    $installerPath = $localInstaller
} else {
    Write-Host "⬇ Downloading latest AbabilX setup for Windows..." -ForegroundColor Yellow
    $tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "AbabilX_0.1.0_x64-setup.exe")
    $downloadUrl = "https://github.com/AbabilX/ababilxdesktopfile/releases/latest/download/AbabilX_0.1.0_x64-setup.exe"
    
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
    $installerPath = $tempFile
}

Write-Host "🚀 Launching installer..." -ForegroundColor Green
Start-Process -FilePath $installerPath -Wait
Write-Host "`n✔ AbabilX installation process completed!`n" -ForegroundColor Green
