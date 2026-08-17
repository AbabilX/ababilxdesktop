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

$scriptDir = $null
if ($PSScriptRoot) {
    $scriptDir = $PSScriptRoot
} elseif ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$localInstaller = $null

if ($scriptDir -and (Test-Path -Path (Join-Path $scriptDir "desktopapp"))) {
    $exeCandidate = Get-ChildItem -Path (Join-Path $scriptDir "desktopapp") -Recurse -Filter "*setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    $msiCandidate = Get-ChildItem -Path (Join-Path $scriptDir "desktopapp") -Recurse -Filter "*.msi" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($exeCandidate) {
        $localInstaller = $exeCandidate.FullName
    } elseif ($msiCandidate) {
        $localInstaller = $msiCandidate.FullName
    }
}

if ($localInstaller -and (Test-Path -Path $localInstaller)) {
    Write-Host "✔ Found local installer: $localInstaller" -ForegroundColor Green
    $installerPath = $localInstaller
} else {
    Write-Host "⬇ Downloading latest AbabilX setup for Windows..." -ForegroundColor Yellow
    $tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "AbabilX_0.1.0_x64-setup.exe")
    $downloadUrl = "https://github.com/AbabilX/ababilxdesktopfile/releases/latest/download/AbabilX_0.1.0_x64-setup.exe"
    
    $downloaded = $false
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -fSL "$downloadUrl" -o "$tempFile" --progress-bar 2>$null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $tempFile) -and ((Get-Item $tempFile).Length -gt 100000)) {
            $downloaded = $true
        }
    }
    
    if (-not $downloaded) {
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
            if ((Test-Path $tempFile) -and ((Get-Item $tempFile).Length -gt 100000)) {
                $downloaded = $true
            }
        } catch {
            Write-Host "`n✘ Download failed. The release may not be published yet on GitHub." -ForegroundColor Red
            Write-Host "URL: $downloadUrl`n" -ForegroundColor Yellow
            return
        }
    }
    $installerPath = $tempFile
}

Write-Host "🚀 Launching installer..." -ForegroundColor Green
Start-Process -FilePath $installerPath -Wait
Write-Host "`n✔ AbabilX installation process completed!`n" -ForegroundColor Green
