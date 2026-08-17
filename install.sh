#!/usr/bin/env bash
set -e

# ==============================================================================
# AbabilX Desktop Universal Cross-Platform Installer
# macOS (Apple Silicon / Intel) | Linux (x86_64 / arm64) | Windows (Bash / WSL)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AbabilX/ababilxdesktopfile/main/install.sh | bash
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${BOLD}${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║             🚀  AbabilX Desktop Installer             ║${NC}"
echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════╝${NC}\n"

OS_NAME="$(uname -s)"
ARCH="$(uname -m)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"

cleanup() {
  [ -n "${MOUNT_DIR:-}" ] && [ -d "$MOUNT_DIR" ] && hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
  [ -n "${MOUNT_DIR:-}" ] && rm -rf "$MOUNT_DIR" 2>/dev/null || true
  [ -n "${TEMP_FILE:-}" ] && rm -f "$TEMP_FILE" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

download_pkg() {
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fSL "$url" -o "$dest" --progress-bar
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress "$url" -O "$dest"
  else
    echo -e "${RED}✘ curl or wget required.${NC}"; exit 1
  fi
}

install_macos() {
  echo -e "${BLUE}ℹ  Target Platform:${NC} macOS ($ARCH)"
  local suffix="aarch64"
  [ "$ARCH" = "x86_64" ] && suffix="x64"

  local local_dmg=""
  [ -n "$SCRIPT_DIR" ] && local_dmg="$(find "$SCRIPT_DIR/desktopapp" -name "*${suffix}*.dmg" -o -name "AbabilX*.dmg" 2>/dev/null | head -n 1 || true)"

  local dmg_path="$local_dmg"
  if [ -z "$dmg_path" ] || [ ! -f "$dmg_path" ]; then
    echo -e "${YELLOW}⬇  Downloading AbabilX for macOS ($ARCH)...${NC}"
    TEMP_FILE="$(mktemp /tmp/AbabilX_XXXXXX.dmg)"
    download_pkg "https://github.com/AbabilX/ababilxdesktopfile/releases/latest/download/AbabilX_0.1.0_${suffix}.dmg" "$TEMP_FILE" || \
      download_pkg "https://github.com/AbabilX/ababilxdesktopfile/releases/latest/download/AbabilX_0.1.0_aarch64.dmg" "$TEMP_FILE"
    dmg_path="$TEMP_FILE"
  else
    echo -e "${GREEN}✔  Using local installer:${NC} $dmg_path"
  fi

  echo -e "${BLUE}📦 Mounting disk image...${NC}"
  MOUNT_DIR="$(mktemp -d /tmp/ababilx_mount_XXXXXX)"
  hdiutil attach "$dmg_path" -nobrowse -mountpoint "$MOUNT_DIR" -quiet

  local app_src="$(find "$MOUNT_DIR" -maxdepth 2 -name "AbabilX.app" -o -name "ababilxdesktop.app" | head -n 1 || true)"
  [ -z "$app_src" ] && { echo -e "${RED}✘ App not found in DMG.${NC}"; exit 1; }

  echo -e "${YELLOW}⏳ Stopping running instances...${NC}"
  pkill -f "AbabilX" 2>/dev/null || true
  sleep 0.5

  local target="/Applications/AbabilX.app"
  echo -e "${BLUE}📂 Copying to /Applications...${NC}"
  rm -rf "$target" && cp -R "$app_src" "$target"
  xattr -cr "$target" 2>/dev/null || true

  if [ -f "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister" ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$target" 2>/dev/null || true
  fi

  echo -e "\n${BOLD}${GREEN}✔  AbabilX installed to /Applications/AbabilX.app!${NC}\n"
  if [ -t 0 ]; then
    read -r -p "Launch AbabilX now? [Y/n] " prompt_launch || prompt_launch="y"
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
  [ -n "$SCRIPT_DIR" ] && local_app="$(find "$SCRIPT_DIR/desktopapp" -name "AbabilX*.AppImage" -o -name "*.AppImage" 2>/dev/null | head -n 1 || true)"

  if [ -n "$local_app" ] && [ -f "$local_app" ]; then
    echo -e "${GREEN}✔  Using local installer:${NC} $local_app"
    cp -f "$local_app" "$target_bin"
  else
    echo -e "${YELLOW}⬇  Downloading AbabilX AppImage...${NC}"
    download_pkg "https://github.com/AbabilX/ababilxdesktopfile/releases/latest/download/AbabilX_amd64.AppImage" "$target_bin"
  fi

  chmod +x "$target_bin"
  echo -e "\n${BOLD}${GREEN}✔  AbabilX installed to $target_bin${NC}"
  echo -e "${BLUE}Tip: Ensure $bin_dir is in your PATH to run 'ababilx'.${NC}\n"
  [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] && "$target_bin" &
}

install_windows() {
  echo -e "${BLUE}ℹ  Target Platform:${NC} Windows ($ARCH)"
  local local_setup=""
  [ -n "$SCRIPT_DIR" ] && local_setup="$(find "$SCRIPT_DIR/desktopapp" -name "AbabilX*setup.exe" -o -name "AbabilX*.msi" 2>/dev/null | head -n 1 || true)"

  local installer="$local_setup"
  if [ -z "$installer" ] || [ ! -f "$installer" ]; then
    echo -e "${YELLOW}⬇  Downloading Windows setup...${NC}"
    TEMP_FILE="$(mktemp /tmp/AbabilX_setup_XXXXXX.exe)"
    download_pkg "https://github.com/AbabilX/ababilxdesktopfile/releases/latest/download/AbabilX_0.1.0_x64-setup.exe" "$TEMP_FILE"
    installer="$TEMP_FILE"
  fi

  # Convert path to Windows format if running under WSL or Cygwin/MSYS
  local win_installer="$installer"
  if command -v wslpath >/dev/null 2>&1; then
    win_installer="$(wslpath -w "$installer")"
  elif command -v cygpath >/dev/null 2>&1; then
    win_installer="$(cygpath -w "$installer")"
  fi

  echo -e "${GREEN}🚀 Launching setup wizard...${NC}"
  if command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /c start "" "$win_installer"
  elif command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -Command "Start-Process '$win_installer'"
  else
    "$installer" &
  fi
  echo -e "${GREEN}✔  Installer launched.${NC}\n"
}

case "$OS_NAME" in
  Darwin*) install_macos ;;
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null && command -v cmd.exe >/dev/null 2>&1; then
      echo -e "${BLUE}ℹ  WSL detected. Forwarding to Windows installer...${NC}"
      install_windows
    else
      install_linux
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows*) install_windows ;;
  *) echo -e "${RED}✘ Unsupported OS: $OS_NAME${NC}"; exit 1 ;;
esac
