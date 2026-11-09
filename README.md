# 🚀 Ababil Talk — AbabilX Desktop

> The AbabilX desktop app: end-to-end encrypted chat, voice and video calls, channels, Spaces and team boards.

[![Release](https://img.shields.io/github/v/release/AbabilX/ababilxdesktop?color=blue&label=Latest%20Version)](https://github.com/AbabilX/ababilxdesktop/releases/latest)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Windows%20%7C%20Linux-brightgreen)](#quick-install)
[![License](https://img.shields.io/badge/License-Proprietary-orange)](#)

---

## ⚡ Quick One-Line Install (Terminal / Shell)

Install or update Ababil Talk directly from your terminal with a single command:

### 🍎 macOS & 🐧 Linux
```bash
curl -fsSL https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.sh | bash
```
*Auto-detects macOS (Apple Silicon M1 or newer; no Intel build yet) and Linux (x86_64; no arm64 build yet), installs the app, removes Gatekeeper quarantine flags, and registers system URL deep links.*

Add `ABABILX_DRY_RUN=1` before `bash` to see which file it would install without installing anything.

### 🪟 Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.ps1 | iex
```
*Downloads the installer and runs the setup wizard automatically.*

### 🔄 Update an existing install

Run the **same command again**. It downloads the newest release, quits the running app,
replaces `/Applications/Ababil Talk.app` (macOS; an old `AbabilX.app` is removed) and reopens it. Nothing else to uninstall first.

Verify the installed version afterwards:

```bash
# macOS
defaults read "/Applications/Ababil Talk.app/Contents/Info" CFBundleShortVersionString
```

---

## 📦 Direct Downloads

Download the standalone package for your operating system:

File names carry the version (`Ababil.Talk_0.2.1_aarch64.dmg`), so take them from the
[latest release page](https://github.com/AbabilX/ababilxdesktop/releases/latest):

| **Platform** | Architecture | File |
| :--- | :--- | :--- |
| **macOS** | Apple Silicon (`arm64`) | `Ababil.Talk_<version>_aarch64.dmg` |
| **Windows** | 64-bit (`x64`) | `Ababil.Talk_<version>_x64-setup.exe` (or the `.msi`) |
| **Linux** | 64-bit (`x86_64`) | `.AppImage`, `.deb` or `.rpm`, when the release includes them |

Prefer the one-liner installers above: they find the newest file through the GitHub API.

---

## 🛠️ Manual Installation & Security Permissions

### macOS (Gatekeeper Bypass)
If macOS shows *"Ababil Talk cannot be opened because Apple cannot check it for malicious software"*:
1. Run this command in Terminal to un-quarantine the application:
   ```bash
   xattr -cr "/Applications/Ababil Talk.app"
   # older builds were named AbabilX.app:
   xattr -cr /Applications/AbabilX.app
   ```
2. Or open **System Settings → Privacy & Security → Click "Open Anyway"**.

### Windows (SmartScreen Bypass)
If Windows SmartScreen prompts on first launch:
1. Click **More info**.
2. Click **Run anyway**.

### Linux (AppImage Permissions)
```bash
chmod +x Ababil.Talk_*_amd64.AppImage
./Ababil.Talk_*_amd64.AppImage
```

---

## 🔄 Updates

Ababil Talk checks for a newer version on startup and every 6 hours. When one exists, a dialog
shows the install command for your OS:

| Platform | Command |
| :--- | :--- |
| macOS / Linux | `curl -fsSL https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.sh \| bash` |
| Windows | `irm https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.ps1 \| iex` |

Press **Copy command & quit**: the app copies the command and closes itself (closing the
window alone only hides it to the tray, and the installer cannot replace a running app).
Paste the command into a terminal; the installer downloads the newest release, replaces the
app, and reopens it.

The app does **not** replace itself in the background. Updating is always a deliberate,
user-run step.
