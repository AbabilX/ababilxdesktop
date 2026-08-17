# ==============================================================================
# AbabilX Desktop PowerShell Installer (Windows)
#
# Quick Run:
#   irm https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.ps1 | iex
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║             🚀  AbabilX Desktop Installer             ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Stop any previous hanging installer instances to release file locks
Get-Process | Where-Object { $_.ProcessName -like "*AbabilX*setup*" } | Stop-Process -Force -ErrorAction SilentlyContinue

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
    $uniqueId = [System.Guid]::NewGuid().ToString('N').Substring(0, 8)
    $tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "AbabilX_setup_$uniqueId.exe")
    
    $downloadUrls = @(
        "https://github.com/AbabilX/ababilxdesktop/releases/download/v0.1/AbabilX_0.1.0_x64-setup.exe",
        "https://github.com/AbabilX/ababilxdesktop/releases/latest/download/AbabilX_0.1.0_x64-setup.exe",
        "https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/desktopapp/v0.1/AbabilX_0.1.0_x64-setup.exe"
    )
    
    $downloaded = $false
    foreach ($url in $downloadUrls) {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            & curl.exe -fSL "$url" -o "$tempFile" --progress-bar 2>$null
            if ($LASTEXITCODE -eq 0 -and (Test-Path $tempFile) -and ((Get-Item $tempFile).Length -gt 100000)) {
                $downloaded = $true
                break
            }
        }
        
        try {
            Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
            if ((Test-Path $tempFile) -and ((Get-Item $tempFile).Length -gt 100000)) {
                $downloaded = $true
                break
            }
        } catch {
            # Continue to next mirror
        }
    }
    
    if (-not $downloaded) {
        Write-Host "`n✘ Download failed. Unable to fetch installer binary from any release mirror.`n" -ForegroundColor Red
        return
    }
    
    $installerPath = $tempFile
}

Write-Host "🚀 Launching installer..." -ForegroundColor Green
Start-Process -FilePath $installerPath -Wait
Write-Host "`n✔ AbabilX installation process completed!`n" -ForegroundColor Green
