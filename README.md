# 🚀 AbabilX Desktop App

> Official cross-platform desktop application for **AbabilX** — GitHub + Slack automation, real-time voice calls, team boards, chat, and CRM.

[![Release](https://img.shields.io/github/v/release/AbabilX/ababilxdesktop?color=blue&label=Latest%20Version)](https://github.com/AbabilX/ababilxdesktop/releases/latest)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Windows%20%7C%20Linux-brightgreen)](#quick-install)
[![License](https://img.shields.io/badge/License-Proprietary-orange)](#)

---

## ⚡ Quick One-Line Install (Terminal / Shell)

Install or update AbabilX directly from your terminal with a single command:

### 🍎 macOS & 🐧 Linux
```bash
curl -fsSL https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.sh | bash
```
*Auto-detects macOS (Apple Silicon M1/M2/M3/M4 or Intel) and Linux (x86_64 / arm64), installs the app, removes Gatekeeper quarantine flags, and registers system URL deep links.*

### 🪟 Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.ps1 | iex
```
*Downloads the installer and runs the setup wizard automatically.*

---

## 📦 Direct Downloads

Download the standalone package for your operating system:

| Platform | Architecture | Installer Type | Download Link |
| :--- | :--- | :--- | :--- |
| **macOS** | Apple Silicon (`arm64`) | `.dmg` | [Download DMG](https://github.com/AbabilX/ababilxdesktop/releases/download/v0.1/Macos_Relased.dmg) |
| **macOS** | Intel (`x86_64`) | `.dmg` | [Download DMG](https://github.com/AbabilX/ababilxdesktop/releases/download/v0.1/Macos_Relased.dmg) |
| **Windows** | 64-bit (`x64`) | Setup `.exe` | [Download EXE](https://github.com/AbabilX/ababilxdesktop/releases/download/v0.1/AbabilX.exe) |
| **Windows** | 64-bit (`x64`) | Enterprise `.msi` | [Download MSI](https://github.com/AbabilX/ababilxdesktop/releases/download/v0.1/AbabilX.msi) |
| **Linux** | 64-bit (`x86_64`) | `.AppImage` | [Download AppImage](https://github.com/AbabilX/ababilxdesktop/releases/latest/download/AbabilX_amd64.AppImage) |
| **Linux** | 64-bit (`x86_64`) | `.deb` package | [Download DEB](https://github.com/AbabilX/ababilxdesktop/releases/latest/download/AbabilX_amd64.deb) |

---

## 🛠️ Manual Installation & Security Permissions

### macOS (Gatekeeper Bypass)
If macOS shows *"AbabilX cannot be opened because Apple cannot check it for malicious software"*:
1. Run this command in Terminal to un-quarantine the application:
   ```bash
   xattr -cr /Applications/AbabilX.app
   # or if named ababilxdesktop.app:
   xattr -cr /Applications/ababilxdesktop.app
   ```
2. Or open **System Settings → Privacy & Security → Click "Open Anyway"**.

### Windows (SmartScreen Bypass)
If Windows SmartScreen prompts on first launch:
1. Click **More info**.
2. Click **Run anyway**.

### Linux (AppImage Permissions)
```bash
chmod +x AbabilX_amd64.AppImage
./AbabilX_amd64.AppImage
```

---

## 🔄 Updates

AbabilX checks for a newer version on startup and every 6 hours. When one exists, a dialog
shows the install command for your OS:

| Platform | Command |
| :--- | :--- |
| macOS / Linux | `curl -fsSL https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.sh \| bash` |
| Windows | `irm https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.ps1 \| iex` |

Press **Copy command & quit** — AbabilX copies the command and closes itself (closing the
window alone only hides it to the tray, and the installer cannot replace a running app).
Paste the command into a terminal; the installer downloads the newest release, replaces the
app, and reopens it.

The app does **not** replace itself in the background. Updating is always a deliberate,
user-run step.
