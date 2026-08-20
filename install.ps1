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

# Bundled installers under desktopapp/ are for offline installs only, and are
# opt-in: preferring them by default would make a clone reinstall the old build
# and leave the app stuck on "update available" forever.
$useLocal = $env:ABABILX_LOCAL -eq "1"

if ($useLocal -and $scriptDir -and (Test-Path -Path (Join-Path $scriptDir "desktopapp"))) {
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
    
    $repo = if ($env:ABABILX_REPO) { $env:ABABILX_REPO } else { "AbabilX/ababilxdesktop" }

    # Newest release first. A pinned v0.1 URL ahead of these would reinstall the
    # old build every time and leave the app stuck on "update available".
    $downloadUrls = @(
        "https://github.com/$repo/releases/latest/download/AbabilX_setup.exe",
        "https://github.com/$repo/releases/latest/download/AbabilX.exe"
    )

    # Version-stamped assets (AbabilX_0.2.0_x64-setup.exe) are resolved from the
    # release API so the script never needs to know the version number.
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing -ErrorAction Stop
        $apiAssets = $release.assets | Where-Object { $_.name -match '\.(exe|msi)$' } |
            Sort-Object { if ($_.name -match 'setup\.exe$') { 0 } elseif ($_.name -match '\.exe$') { 1 } else { 2 } } |
            ForEach-Object { $_.browser_download_url }
        if ($apiAssets) { $downloadUrls += $apiAssets }
    } catch {
        # Offline or rate-limited — the direct latest/download URLs above still apply.
    }

    $downloadUrls += @(
        "https://github.com/$repo/releases/latest/download/AbabilX.msi",
        "https://github.com/$repo/releases/download/v0.1/AbabilX.exe"
    )

    $downloaded = $false
    foreach ($url in $downloadUrls) {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            & curl.exe -fSL "$url" -o "$tempFile" --progress-bar
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
