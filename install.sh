#!/usr/bin/env bash
set -e

# ==============================================================================
# Ababil Talk (AbabilX Desktop) cross-platform installer
# macOS (Apple Silicon) | Linux (x86_64) | Windows (Git Bash / WSL)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.sh | bash
# Check which file it would install, without installing anything:
#   curl -fsSL https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.sh | ABABILX_DRY_RUN=1 bash
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${BOLD}${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║               🚀  Ababil Talk Installer               ║${NC}"
echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════╝${NC}\n"

OS_NAME="$(uname -s)"
ARCH="$(uname -m)"
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo "")"
fi

cleanup() {
  [ -n "${MOUNT_DIR:-}" ] && [ -d "$MOUNT_DIR" ] && hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
  [ -n "${MOUNT_DIR:-}" ] && rm -rf "$MOUNT_DIR" 2>/dev/null || true
  # Only clean temp file on non-Windows to avoid removing active installer binary
  case "$OS_NAME" in
    Darwin*)
      [ -n "${TEMP_FILE:-}" ] && rm -f "$TEMP_FILE" 2>/dev/null || true
      ;;
    Linux*)
      if [ ! -f /proc/version ] || ! grep -qi microsoft /proc/version; then
        [ -n "${TEMP_FILE:-}" ] && rm -f "$TEMP_FILE" 2>/dev/null || true
      fi
      ;;
  esac
}
trap cleanup EXIT INT TERM

download_pkg() {
  local url="$1" dest="$2"
  [ -z "$dest" ] && return 1
  if [ "${ABABILX_DRY_RUN:-0}" = "1" ]; then
    curl -fsIL "$url" -o /dev/null 2>/dev/null || return 1
    echo -e "${GREEN}✔  Would install:${NC} $url"
    exit 0
  fi
  if command -v curl >/dev/null 2>&1; then
    curl -fSL "$url" -o "$dest" --progress-bar || return 1
  elif command -v wget >/dev/null 2>&1; then
    wget --show-progress "$url" -O "$dest" || return 1
  else
    echo -e "${RED}✘ curl or wget required.${NC}"
    return 1
  fi
  [ -s "$dest" ] || return 1
}

# Public installer repo Releases. Assets are version-stamped
# (Ababil.Talk_0.2.1_aarch64.dmg), so the GitHub API is asked first.
REPO="${ABABILX_REPO:-AbabilX/ababilxdesktop}"

# Bundled installers under desktopapp/ are for offline installs only. They are
# opt-in because they go stale the moment a new release ships: preferring them
# by default would make `./install.sh` from a clone reinstall the old build and
# leave the app stuck on "update available" forever.
use_local() { [ "${ABABILX_LOCAL:-0}" = "1" ]; }

# Resolves a download URL from the newest GitHub release, so a renamed or
# version-stamped asset (AbabilX_0.2.0_aarch64.dmg) still installs without the
# script knowing the version. $1 is an extended-regex matched against the URL.
gh_latest_asset() {
  local pattern="$1"
  curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
    | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | sed 's/.*"\(https[^"]*\)".*/\1/' \
    | grep -iE "$pattern" \
    | head -n 1
}

# Tries each URL in order and stops at the first that downloads.
download_first() {
  local dest="$1"; shift
  local url
  for url in "$@"; do
    [ -z "$url" ] && continue
    download_pkg "$url" "$dest" && return 0
  done
  return 1
}

install_macos() {
  echo -e "${BLUE}ℹ  Target Platform:${NC} macOS ($ARCH)"
  # Only an Apple Silicon build is published; an Intel Mac cannot run it, so
  # stop here instead of installing an app that will not open.
  if [ "$ARCH" != "arm64" ]; then
    echo -e "${RED}✘ Ababil Talk for macOS needs an Apple Silicon Mac (M1 or newer). Intel Macs are not supported yet.${NC}"
    exit 1
  fi
  local suffix="aarch64"

  local local_dmg=""
  if use_local && [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/desktopapp" ]; then
    local_dmg="$(find "$SCRIPT_DIR/desktopapp" -name "*${suffix}*.dmg" -o -name "AbabilX*.dmg" -o -name "Macos*.dmg" 2>/dev/null | head -n 1 || true)"
  fi

  local dmg_path="$local_dmg"
  if [ -z "$dmg_path" ] || [ ! -f "$dmg_path" ]; then
    echo -e "${YELLOW}⬇  Downloading Ababil Talk for macOS ($ARCH)...${NC}"
    TEMP_FILE="$(mktemp /tmp/AbabilX_XXXXXX.dmg)"
    # Newest release only. A pinned old URL here would reinstall the old build
    # forever and leave the app stuck on "update available".
    download_first "$TEMP_FILE" \
      "$(gh_latest_asset "${suffix}[^/]*\\.dmg$")" \
      "https://github.com/$REPO/releases/latest/download/AbabilX_${suffix}.dmg" || {
        echo -e "${RED}✘ Download failed. Please check your internet connection.${NC}"; exit 1;
      }
    dmg_path="$TEMP_FILE"
  else
    echo -e "${GREEN}✔  Using local installer:${NC} $dmg_path"
  fi

  echo -e "${BLUE}📦 Mounting disk image...${NC}"
  MOUNT_DIR="$(mktemp -d /tmp/ababilx_mount_XXXXXX)"
  hdiutil attach "$dmg_path" -nobrowse -mountpoint "$MOUNT_DIR"

  # The app is "Ababil Talk" since 0.2.1; older DMGs still carry AbabilX.app.
  local app_src="$(find "$MOUNT_DIR" -maxdepth 2 \( -name "Ababil Talk.app" -o -name "AbabilX.app" -o -name "ababilxdesktop.app" \) | head -n 1 || true)"
  [ -z "$app_src" ] && { echo -e "${RED}✘ App not found in DMG.${NC}"; exit 1; }

  echo -e "${YELLOW}⏳ Stopping running instances...${NC}"
  pkill -f "Ababil Talk.app" || true
  pkill -f "AbabilX.app" || true
  sleep 0.5

  local target="/Applications/$(basename "$app_src")"
  echo -e "${BLUE}📂 Copying to /Applications...${NC}"
  rm -rf "$target" && cp -R "$app_src" "$target"
  # Renamed app: the old bundle would stay beside it as a second, stale copy.
  [ "$target" != "/Applications/AbabilX.app" ] && rm -rf "/Applications/AbabilX.app"
  xattr -cr "$target" || true

  if [ -f "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister" ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$target" || true
  fi

  echo -e "\n${BOLD}${GREEN}✔  Ababil Talk installed to $target!${NC}\n"
  if [ -t 0 ]; then
    read -r -p "Launch Ababil Talk now? [Y/n] " prompt_launch || prompt_launch="y"
    case "$prompt_launch" in [nN]*) ;; *) open "$target" ;; esac
  else
    open "$target"
  fi
}

install_linux() {
  echo -e "${BLUE}ℹ  Target Platform:${NC} Linux ($ARCH)"
  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"
  local target_bin="$bin_dir/ababilx"

  local local_app=""
  use_local && [ -n "$SCRIPT_DIR" ] && local_app="$(find "$SCRIPT_DIR/desktopapp" -name "AbabilX*.AppImage" -o -name "*.AppImage" | head -n 1 || true)"

  if [ -n "$local_app" ] && [ -f "$local_app" ]; then
    echo -e "${GREEN}✔  Using local installer:${NC} $local_app"
    cp -f "$local_app" "$target_bin"
  else
    # Only an x86_64 build is published; an arm64 machine cannot run it.
    case "$ARCH" in
      x86_64|amd64) ;;
      *) echo -e "${RED}✘ Ababil Talk for Linux needs an x86_64 (64-bit Intel/AMD) machine. $ARCH is not supported yet.${NC}"; exit 1 ;;
    esac
    echo -e "${YELLOW}⬇  Downloading Ababil Talk AppImage...${NC}"
    download_first "$target_bin" \
      "$(gh_latest_asset "amd64[^/]*\\.AppImage$")" \
      "https://github.com/$REPO/releases/latest/download/AbabilX_amd64.AppImage" || {
        echo -e "${RED}✘ Download failed. The latest release may not have a Linux build yet, or check your internet connection.${NC}"; exit 1;
      }
  fi

  chmod +x "$target_bin"
  echo -e "\n${BOLD}${GREEN}✔  Ababil Talk installed to $target_bin${NC}"
  echo -e "${BLUE}Tip: Ensure $bin_dir is in your PATH to run 'ababilx'.${NC}\n"
  [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] && "$target_bin" &
}

install_windows() {
  echo -e "${BLUE}ℹ  Target Platform:${NC} Windows ($ARCH)"
  local local_setup=""
  if use_local && [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/desktopapp" ]; then
    local_setup="$(find "$SCRIPT_DIR/desktopapp" -type f \( -name "AbabilX*.exe" -o -name "AbabilX*.msi" -o -name "*setup*.exe" \) 2>/dev/null | head -n 1 || true)"
  fi

  local installer="$local_setup"
  if [ -z "$installer" ] || [ ! -f "$installer" ]; then
    echo -e "${YELLOW}⬇  Downloading Windows setup...${NC}"
    local rand_id
    rand_id="$(head -c 8 /dev/urandom 2>/dev/null | xxd -p 2>/dev/null || echo $$)"
    
    local tmp_base="${TEMP:-${TMP:-/tmp}}"
    [ -d "$tmp_base" ] || tmp_base="/tmp"

    TEMP_FILE="$(mktemp "${tmp_base}/AbabilX_setup_${rand_id}_XXXXXX.exe" 2>/dev/null || echo "${tmp_base}/AbabilX_setup_${rand_id}.exe")"
    download_first "$TEMP_FILE" \
      "$(gh_latest_asset "x64[^/]*setup\\.exe$")" \
      "$(gh_latest_asset "setup\\.exe$")" \
      "https://github.com/$REPO/releases/latest/download/AbabilX_setup.exe" \
      "https://github.com/$REPO/releases/latest/download/AbabilX.exe" || {
        echo -e "${RED}✘ Download failed. Please check your internet connection.${NC}"; exit 1;
      }
    installer="$TEMP_FILE"
  else
    echo -e "${GREEN}✔  Using local installer:${NC} $installer"
  fi

  # Convert path to Windows format if running under WSL or Cygwin/MSYS/Git Bash
  local win_installer="$installer"
  if command -v cygpath >/dev/null 2>&1; then
    win_installer="$(cygpath -w "$installer")"
  elif command -v wslpath >/dev/null 2>&1; then
    win_installer="$(wslpath -w "$installer")"
  fi

  echo -e "${GREEN}🚀 Launching setup: $win_installer...${NC}"
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "Start-Process -FilePath '$win_installer' -Wait" || powershell.exe -NoProfile -Command "Start-Process -FilePath '$win_installer'"
  elif command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /c start "" "$win_installer"
  else
    "$installer" &
  fi
  echo -e "${GREEN}✔  Ababil Talk installation process completed!${NC}\n"
}

case "$OS_NAME" in
  Darwin*) install_macos ;;
  Linux*)
    if grep -qi microsoft /proc/version && command -v cmd.exe >/dev/null 2>&1; then
      echo -e "${BLUE}ℹ  WSL detected. Forwarding to Windows installer...${NC}"
      install_windows
    else
      install_linux
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows*) install_windows ;;
  *) echo -e "${RED}✘ Unsupported OS: $OS_NAME${NC}"; exit 1 ;;
esac
