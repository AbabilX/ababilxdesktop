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

# 1. Stop any running instances of AbabilX or installers to release file locks
Write-Host "⏳ Stopping running AbabilX instances..." -ForegroundColor Yellow
Get-Process | Where-Object { 
    $_.ProcessName -like "*AbabilX*" -or 
    $_.ProcessName -like "*ababilxdesktop*" 
} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# 2. Check for and remove existing older installation
$uninstallPaths = @(
    "$env:LOCALAPPDATA\AbabilX",
    "$env:LOCALAPPDATA\Programs\AbabilX",
    "$env:PROGRAMFILES\AbabilX"
)

$uninstallerExe = $null

# Check registry for registered uninstaller
$regKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($regPath in $regKeys) {
    $entry = Get-ItemProperty $regPath -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -like "*AbabilX*" -or $_.PSChildName -like "*AbabilX*" } | 
        Select-Object -First 1
    if ($entry -and $entry.UninstallString) {
        $cleanString = ($entry.UninstallString -replace '"','').Trim()
        if (Test-Path $cleanString) {
            $uninstallerExe = $cleanString
            break
        }
    }
}

if (-not $uninstallerExe) {
    foreach ($p in $uninstallPaths) {
        if (Test-Path "$p\uninstall.exe") {
            $uninstallerExe = "$p\uninstall.exe"
            break
        }
    }
}

if ($uninstallerExe -and (Test-Path $uninstallerExe)) {
    Write-Host "🗑️  Removing older AbabilX installation..." -ForegroundColor Yellow
    $uninstDir = Split-Path -Parent $uninstallerExe
    # Running NSIS uninstaller silently; _? ensures synchronous wait until uninstall completes
    Start-Process -FilePath $uninstallerExe -ArgumentList "/S", "_?=$uninstDir" -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

# Ensure older installation directory is removed
foreach ($p in $uninstallPaths) {
    if (Test-Path $p) {
        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 3. Download the latest release installer
Write-Host "⬇ Downloading latest AbabilX setup for Windows..." -ForegroundColor Yellow
$uniqueId = [System.Guid]::NewGuid().ToString('N').Substring(0, 8)
$tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "AbabilX_setup_$uniqueId.exe")

$repo = if ($env:ABABILX_REPO) { $env:ABABILX_REPO } else { "AbabilX/ababilxdesktop" }

# Primary target: standard setup executable
$downloadUrls = @(
    "https://github.com/$repo/releases/latest/download/AbabilX_setup.exe",
    "https://github.com/$repo/releases/latest/download/AbabilX.exe"
)

# Fetch latest release assets from GitHub API
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing -ErrorAction Stop
    $apiAssets = $release.assets | Where-Object { $_.name -match '\.(exe|msi)$' } |
        Sort-Object { if ($_.name -match 'setup\.exe$') { 0 } elseif ($_.name -match '\.exe$') { 1 } else { 2 } } |
        ForEach-Object { $_.browser_download_url }
    if ($apiAssets) { $downloadUrls += $apiAssets }
} catch {
    # Fallback to direct latest/download URLs above
}

$downloadUrls += @(
    "https://github.com/$repo/releases/latest/download/AbabilX.msi"
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
    Write-Host "`n✘ Download failed. Unable to fetch installer binary from release mirrors.`n" -ForegroundColor Red
    return
}

# 4. Launch new installer
Write-Host "🚀 Launching AbabilX installer..." -ForegroundColor Green
Start-Process -FilePath $tempFile -Wait
Write-Host "`n✔ AbabilX installation process completed!`n" -ForegroundColor Green
