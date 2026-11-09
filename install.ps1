# ==============================================================================
# Ababil Talk (AbabilX Desktop) PowerShell Installer (Windows)
#
# Quick Run:
#   irm https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.ps1 | iex
# Check which file it would install, without installing anything:
#   $env:ABABILX_DRY_RUN = "1"; irm https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.ps1 | iex
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║               🚀  Ababil Talk Installer               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Public installer repo Releases. Assets are version-stamped
# (Ababil.Talk_0.2.1_x64-setup.exe), so the GitHub API is asked first.
$repo = if ($env:ABABILX_REPO) { $env:ABABILX_REPO } else { "AbabilX/ababilxdesktop" }
$dryRun = $env:ABABILX_DRY_RUN -eq "1"

# 1. Find the newest installer: the setup .exe first, the .msi if that is all there is.
$downloadUrls = @()
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing -ErrorAction Stop
    $apiAssets = $release.assets | Where-Object { $_.name -match 'x64.*(setup\.exe|\.msi)$' } |
        Sort-Object { if ($_.name -match 'setup\.exe$') { 0 } else { 1 } } |
        ForEach-Object { $_.browser_download_url }
    if ($apiAssets) { $downloadUrls += $apiAssets }
} catch {
    # GitHub API unreachable or rate-limited: fall through to the fixed names below.
}
$downloadUrls += @(
    "https://github.com/$repo/releases/latest/download/AbabilX_setup.exe",
    "https://github.com/$repo/releases/latest/download/AbabilX.msi"
)

if ($dryRun) {
    Write-Host "✔ Would install: $($downloadUrls[0])" -ForegroundColor Green
    return
}

# 2. Download BEFORE touching the installed app, so a failed download never
#    leaves the computer with no app at all.
Write-Host "⬇ Downloading the latest Ababil Talk for Windows..." -ForegroundColor Yellow
$uniqueId = [System.Guid]::NewGuid().ToString('N').Substring(0, 8)
$tempFile = $null
foreach ($url in $downloadUrls) {
    $ext = if ($url -match '\.msi$') { ".msi" } else { ".exe" }
    $candidate = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "AbabilX_setup_$uniqueId$ext")
    $ok = $false
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -fSL "$url" -o "$candidate" --progress-bar
        $ok = ($LASTEXITCODE -eq 0)
    } else {
        try {
            Invoke-WebRequest -Uri $url -OutFile $candidate -UseBasicParsing -ErrorAction Stop
            $ok = $true
        } catch { }
    }
    if ($ok -and (Test-Path $candidate) -and ((Get-Item $candidate).Length -gt 100000)) {
        $tempFile = $candidate
        break
    }
    Remove-Item -Path $candidate -Force -ErrorAction SilentlyContinue
}

if (-not $tempFile) {
    Write-Host "`n✘ Download failed. Check your internet connection and try again.`n" -ForegroundColor Red
    return
}

# 3. Stop the running app so its files can be replaced.
Write-Host "⏳ Stopping running Ababil Talk..." -ForegroundColor Yellow
Get-Process | Where-Object {
    $_.ProcessName -like "*AbabilX*" -or
    $_.ProcessName -like "*Ababil Talk*" -or
    $_.ProcessName -like "*ababilxdesktop*"
} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# 4. Remove an older install (AbabilX before 0.2.1) so two copies never sit side by side.
$uninstallPaths = @(
    "$env:LOCALAPPDATA\Ababil Talk",
    "$env:LOCALAPPDATA\AbabilX",
    "$env:LOCALAPPDATA\Programs\AbabilX",
    "$env:PROGRAMFILES\AbabilX"
)
$uninstallerExe = $null
$regKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($regPath in $regKeys) {
    $entry = Get-ItemProperty $regPath -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*AbabilX*" -or $_.DisplayName -like "*Ababil Talk*" -or $_.PSChildName -like "*AbabilX*" } |
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
    Write-Host "🗑️  Removing the older installation..." -ForegroundColor Yellow
    $uninstDir = Split-Path -Parent $uninstallerExe
    # NSIS uninstaller, silent; _? makes it finish before we go on.
    Start-Process -FilePath $uninstallerExe -ArgumentList "/S", "_?=$uninstDir" -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}
foreach ($p in $uninstallPaths) {
    if (Test-Path $p) {
        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 5. Install silently and launch the app.
Write-Host "🚀 Installing Ababil Talk..." -ForegroundColor Green
if ($tempFile -match '\.msi$') {
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$tempFile`"", "/qn" -Wait
} else {
    Start-Process -FilePath $tempFile -ArgumentList "/S" -Wait
}
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

# NSIS installs under the product name: "Ababil Talk" since 0.2.1, AbabilX before.
$installedExe = @(
    "$env:LOCALAPPDATA\Ababil Talk\ababilxdesktop.exe",
    "$env:LOCALAPPDATA\Ababil Talk\Ababil Talk.exe",
    "$env:LOCALAPPDATA\AbabilX\ababilxdesktop.exe",
    "$env:PROGRAMFILES\Ababil Talk\ababilxdesktop.exe",
    "$env:PROGRAMFILES\Ababil Talk\Ababil Talk.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($installedExe) {
    Write-Host "🎉 Launching Ababil Talk..." -ForegroundColor Green
    Start-Process -FilePath $installedExe
}

Write-Host "`n✔ Ababil Talk installation process completed!`n" -ForegroundColor Green
