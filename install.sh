#!/usr/bin/env bash
set -e

# ==============================================================================
# AbabilX Desktop Cross-Platform Installer
# macOS (Apple Silicon / Intel) | Linux (x86_64 / arm64) | Windows (Git Bash / MSYS)
#
# Quick Run:
#   curl -fsSL https://raw.githubusercontent.com/AbabilX/ababilxdesktop/main/install.sh | bash
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
  if [ -n "${MOUNT_DIR:-}" ] && [ -d "$MOUNT_DIR" ]; then
    hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
    rm -rf "$MOUNT_DIR"
  fi
  if [ -n "${TEMP_FILE:-}" ] && [ -f "$TEMP_FILE" ]; then
    rm -f "$TEMP_FILE"
  fi
}
trap cleanup EXIT INT TERM

download_file() {
  local url="$1"
  local dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fSL "$url" -o "$dest" --progress-bar
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress "$url" -O "$dest"
  else
    echo -e "${RED}✘ Error: curl or wget is required to download.${NC}"
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# macOS Flow
# ------------------------------------------------------------------------------
install_macos() {
  echo -e "${BLUE}ℹ  Target Platform:${NC} macOS ($ARCH)"
  local dmg_suffix="aarch64"
  if [ "$ARCH" = "x86_64" ]; then
    dmg_suffix="x64"
  fi

  local local_dmg=""
  if [ -n "$SCRIPT_DIR" ]; then
    local_dmg="$(find "$SCRIPT_DIR/desktopapp" -name "*${dmg_suffix}*.dmg" -o -name "AbabilX*.dmg" 2>/dev/null | head -n 1 || true)"
  fi

  local dmg_path=""
  if [ -n "$local_dmg" ] && [ -f "$local_dmg" ]; then
    echo -e "${GREEN}✔  Found local installer:${NC} $local_dmg"
    dmg_path="$local_dmg"
  else
    echo -e "${YELLOW}⬇  Downloading AbabilX for macOS ($ARCH)...${NC}"
    TEMP_FILE="$(mktemp /tmp/AbabilX_installer_XXXXXX.dmg)"
    local download_url="https://github.com/AbabilX/ababilxdesktopfile/releases/latest/download/AbabilX_0.1.0_${dmg_suffix}.dmg"
    download_file "$download_url" "$TEMP_FILE" || {
      # Fallback to default dmg if arch-specific not found
      download_file "https://github.com/AbabilX/ababilxdesktopfile/releases/latest/download/AbabilX_0.1.0_aarch64.dmg" "$TEMP_FILE"
    }
    dmg_path="$TEMP_FILE"
  fi

  echo -e "${BLUE}📦 Mounting disk image...${NC}"
  MOUNT_DIR="$(mktemp -d /tmp/ababilx_mount_XXXXXX)"
  hdiutil attach "$dmg_path" -nobrowse -mountpoint "$MOUNT_DIR" -quiet

  local app_src="$(find "$MOUNT_DIR" -maxdepth 2 -name "AbabilX.app" -o -name "ababilxdesktop.app" | head -n 1 || true)"
  if [ -z "$app_src" ] || [ ! -d "$app_src" ]; then
    echo -e "${RED}✘ Error: AbabilX.app not found inside disk image.${NC}"
    exit 1
  fi

  echo -e "${YELLOW}⏳ Stopping existing app instance...${NC}"
  pkill -f "AbabilX" 2>/dev/null || true
  pkill -f "ababilxdesktop" 2>/dev/null || true
  sleep 0.5

  local target="/Applications/AbabilX.app"
  echo -e "${BLUE}📂 Copying to /Applications...${NC}"
  rm -rf "$target"
  cp -R "$app_src" "$target"

  echo -e "${BLUE}🔓 Removing Gatekeeper quarantine flags...${NC}"
  xattr -cr "$target" 2>/dev/null || true

  echo -e "${BLUE}🔗 Registering deep links & system integration...${NC}"
  if [ -f "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister" ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$target" 2>/dev/null || true
  fi

  echo -e "\n${BOLD}${GREEN}✔  AbabilX successfully installed to /Applications/AbabilX.app!${NC}\n"
  
  if [ -t 0 ]; then
    read -r -p "Launch AbabilX now? [Y/n] " prompt_launch || prompt_launch="y"
    case "$prompt_launch" in
      [nN][oO]|[nN]) ;;
      *) open "$target" ;;
    esac
  else
    open "$target"
  fi
}

# ------------------------------------------------------------------------------
# Linux Flow
# ------------------------------------------------------------------------------
install_linux() {
  echo -e "${BLUE}ℹ  Target Platform:${NC} Linux ($ARCH)"
  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"
  local target_bin="$bin_dir/ababilx"

  local local_appimage=""
  if [ -n "$SCRIPT_DIR" ]; then
    local_appimage="$(find "$SCRIPT_DIR/desktopapp" -name "AbabilX*.AppImage" 2>/dev/null | head -n 1 || true)"
  fi

  if [ -n "$local_appimage" ] && [ -f "$local_appimage" ]; then
    echo -e "${GREEN}✔  Found local installer:${NC} $local_appimage"
    cp -f "$local_appimage" "$target_bin"
  else
    echo -e "${YELLOW}⬇  Downloading AbabilX AppImage for Linux...${NC}"
    local download_url="https://github.com/AbabilX/ababilxdesktopfile/releases/latest/download/AbabilX_amd64.AppImage"
    download_file "$download_url" "$target_bin"
  fi

  chmod +x "$target_bin"
  echo -e "\n${BOLD}${GREEN}✔  AbabilX successfully installed to $target_bin${NC}"
  echo -e "${BLUE}Tip: Add $bin_dir to your PATH to run 'ababilx' anywhere.${NC}\n"

  if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    "$target_bin" &
  fi
}

# ------------------------------------------------------------------------------
# Windows Flow (Git Bash, MSYS, MINGW, Cygwin, or WSL)
# ------------------------------------------------------------------------------
install_windows() {
  echo -e "${BLUE}ℹ  Target Platform:${NC} Windows ($ARCH)"

  local local_setup=""
  if [ -n "$SCRIPT_DIR" ]; then
    local_setup="$(find "$SCRIPT_DIR/desktopapp" -name "AbabilX*setup.exe" -o -name "AbabilX*.msi" 2>/dev/null | head -n 1 || true)"
  fi

  local installer_path=""
  if [ -n "$local_setup" ] && [ -f "$local_setup" ]; then
    echo -e "${GREEN}✔  Found local installer:${NC} $local_setup"
    installer_path="$local_setup"
  else
    echo -e "${YELLOW}⬇  Downloading AbabilX Windows Installer (.exe)...${NC}"
    TEMP_FILE="$(mktemp /tmp/AbabilX_setup_XXXXXX.exe)"
    local download_url="https://github.com/AbabilX/ababilxdesktopfile/releases/latest/download/AbabilX_0.1.0_x64-setup.exe"
    download_file "$download_url" "$TEMP_FILE"
    installer_path="$TEMP_FILE"
  fi

  echo -e "${GREEN}🚀 Running Windows Installer...${NC}"
  if command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /c start "" "$installer_path"
  elif command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -Command "Start-Process '$installer_path'"
  else
    "$installer_path" &
  fi
  echo -e "${GREEN}✔  Installer launched. Please follow the setup wizard.${NC}\n"
}

# ------------------------------------------------------------------------------
# Dispatcher
# ------------------------------------------------------------------------------
case "$OS_NAME" in
  Darwin*)
    install_macos
    ;;
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null && command -v cmd.exe >/dev/null 2>&1; then
      # WSL with Windows host access
      echo -e "${BLUE}ℹ  WSL detected. Running Windows installer...${NC}"
      install_windows
    else
      install_linux
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows*)
    install_windows
    ;;
  *)
    echo -e "${RED}✘ Unsupported OS: $OS_NAME. Please download manually from GitHub Releases.${NC}"
    exit 1
    ;;
esac
