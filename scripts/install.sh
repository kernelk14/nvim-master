#!/usr/bin/env bash
# ==============================================================================
# Cross-Platform Automated Bootstrap Script for Linux and macOS
# Installs, backs up, and validates the minimal Neovim configuration.
# ==============================================================================

set -euo pipefail

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_step() {
  printf "\n${CYAN}==>${NC} %s\n" "$1"
}

print_success() {
  printf "  ${GREEN}[OK]${NC} %s\n" "$1"
}

print_warn() {
  printf "  ${YELLOW}[WARN]${NC} %s\n" "$1"
}

print_err() {
  printf "  ${RED}[ERROR]${NC} %s\n" "$1"
}

METHOD="link"
DRY_RUN=0
BACKUP_ONLY=0
FORCE=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --link         Deploy via symbolic link (default)
  --copy         Deploy via file copy
  --backup-only  Only backup existing Neovim config, do not deploy
  --dry-run      Simulate installation without making changes
  --force        Overwrite destination if needed
  -h, --help     Show this help message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --link)
      METHOD="link"
      shift
      ;;
    --copy)
      METHOD="copy"
      shift
      ;;
    --backup-only)
      BACKUP_ONLY=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      print_err "Unknown argument: $1"
      usage
      ;;
  esac
done

# ------------------------------------------------------------------------------
# 1. System & Architecture Detection
# ------------------------------------------------------------------------------
print_step "Detecting System Environment"

OS_NAME="$(uname -s)"
ARCH_NAME="$(uname -m)"

printf "  Operating System: %s\n" "$OS_NAME"
printf "  Architecture:     %s\n" "$ARCH_NAME"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET_DIR="$CONFIG_HOME/nvim"

printf "  Source Path:      %s\n" "$SOURCE_DIR"
printf "  Target Path:      %s\n" "$TARGET_DIR"

# ------------------------------------------------------------------------------
# 2. Prerequisite Checks
# ------------------------------------------------------------------------------
print_step "Checking Prerequisites"

# Neovim
if command -v nvim >/dev/null 2>&1; then
  NVIM_VERSION="$(nvim --version | head -n 1)"
  print_success "Found Neovim: $NVIM_VERSION"

  # Version check
  if [[ "$NVIM_VERSION" =~ v([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    if [ "$MAJOR" -eq 0 ] && [ "$MINOR" -lt 10 ]; then
      print_warn "Neovim version is older than 0.10.0. Some modern features (inlay hints, native commenting) require >= 0.10.0."
    fi
  fi
else
  print_err "Neovim ('nvim') is not installed or not in PATH."
  if [ "$OS_NAME" = "Darwin" ]; then
    printf "  Install via Homebrew: brew install neovim\n"
  else
    printf "  Install via your package manager or download AppImage / tarball from github.com/neovim/neovim/releases\n"
    printf "  Debian/Ubuntu: sudo add-apt-repository ppa:neovim-ppa/unstable && sudo apt install neovim\n"
    printf "  Arch Linux:    sudo pacman -S neovim\n"
    printf "  Fedora:        sudo dnf install neovim\n"
  fi
  exit 1
fi

# Git
if command -v git >/dev/null 2>&1; then
  GIT_VERSION="$(git --version)"
  print_success "Found Git: $GIT_VERSION"
else
  print_err "Git is required for plugin management with lazy.nvim."
  if [ "$OS_NAME" = "Darwin" ]; then
    printf "  Install via Homebrew: brew install git (or xcode-select --install)\n"
  else
    printf "  Install via: sudo apt install git / sudo dnf install git / sudo pacman -S git\n"
  fi
  exit 1
fi

# Ripgrep (Optional)
if command -v rg >/dev/null 2>&1; then
  print_success "Found Ripgrep (fast live grep enabled)"
else
  print_warn "Ripgrep ('rg') not found (optional). Live grep will notify you to install it."
  if [ "$OS_NAME" = "Darwin" ]; then
    printf "       Install via: brew install ripgrep\n"
  else
    printf "       Install via: sudo apt install ripgrep / sudo dnf install ripgrep / sudo pacman -S ripgrep\n"
  fi
fi

# C Compiler (Optional)
FOUND_CC=""
for cc in cc gcc clang zig; do
  if command -v "$cc" >/dev/null 2>&1; then
    FOUND_CC="$cc"
    break
  fi
done

if [ -n "$FOUND_CC" ]; then
  print_success "Found C Compiler: $FOUND_CC (Treesitter AST compilation enabled)"
else
  print_warn "No C compiler found (optional). Treesitter will use precompiled parsers or fallback regex."
  if [ "$OS_NAME" = "Darwin" ]; then
    printf "       Install Xcode tools via: xcode-select --install\n"
  else
    printf "       Install build-essential (Debian/Ubuntu) or base-devel (Arch) or gcc (Fedora)\n"
  fi
fi

# Clipboard Provider (Linux check)
if [ "$OS_NAME" = "Linux" ]; then
  if command -v wl-copy >/dev/null 2>&1; then
    print_success "Found Wayland clipboard provider (wl-clipboard)"
  elif command -v xclip >/dev/null 2>&1; then
    print_success "Found X11 clipboard provider (xclip)"
  elif command -v xsel >/dev/null 2>&1; then
    print_success "Found X11 clipboard provider (xsel)"
  else
    print_warn "No clipboard utility found (optional). For system clipboard sync, install: wl-clipboard (Wayland) or xclip (X11)"
  fi
elif [ "$OS_NAME" = "Darwin" ]; then
  print_success "macOS native clipboard (pbcopy/pbpaste) detected"
fi

# ------------------------------------------------------------------------------
# 3. Safe Backup of Existing Configuration
# ------------------------------------------------------------------------------
print_step "Checking Existing Neovim Configuration"

mkdir -p "$CONFIG_HOME"

if [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
  TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
  BACKUP_DIR="${CONFIG_HOME}/nvim.bak.${TIMESTAMP}"

  print_warn "Existing configuration found at: $TARGET_DIR"
  printf "  Safely creating backup at: %s\n" "$BACKUP_DIR"

  if [ "$DRY_RUN" -eq 0 ]; then
    if [ -L "$TARGET_DIR" ]; then
      # If it's a symlink, remove the link without moving source
      rm -f "$TARGET_DIR"
      print_success "Removed existing symbolic link."
    else
      mv "$TARGET_DIR" "$BACKUP_DIR"
      print_success "Backup created successfully at: $BACKUP_DIR"
    fi
  else
    printf "  [DRY RUN] Would move '%s' to '%s'\n" "$TARGET_DIR" "$BACKUP_DIR"
  fi
else
  print_success "No previous configuration conflict detected."
fi

if [ "$BACKUP_ONLY" -eq 1 ]; then
  print_success "BackupOnly flag specified. Exiting cleanly."
  exit 0
fi

# ------------------------------------------------------------------------------
# 4. Deployment
# ------------------------------------------------------------------------------
print_step "Deploying Configuration ($METHOD)"

if [ "$DRY_RUN" -eq 0 ]; then
  if [ "$METHOD" = "link" ]; then
    ln -s "$SOURCE_DIR" "$TARGET_DIR"
    print_success "Created symbolic link: $TARGET_DIR -> $SOURCE_DIR"
  else
    cp -r "$SOURCE_DIR" "$TARGET_DIR"
    print_success "Copied configuration to: $TARGET_DIR"
  fi
else
  printf "  [DRY RUN] Would deploy source '%s' to '%s' via %s\n" "$SOURCE_DIR" "$TARGET_DIR" "$METHOD"
fi

# ------------------------------------------------------------------------------
# 5. Validation Check
# ------------------------------------------------------------------------------
print_step "Validating Neovim Configuration"

if [ "$DRY_RUN" -eq 0 ]; then
  if nvim --headless "+lua print('Neovim configuration loaded successfully!')" +q 2>&1; then
    print_success "Neovim successfully parsed and executed configuration!"
  else
    print_warn "Neovim exited with a non-zero code during validation."
  fi
fi

# ------------------------------------------------------------------------------
# 6. Completion Summary
# ------------------------------------------------------------------------------
printf "\n${GREEN}========================================================${NC}\n"
printf "${GREEN} Installation Complete!${NC}\n"
printf "${GREEN}========================================================${NC}\n"
printf "Next steps:\n"
printf "  1. Start Neovim:        nvim\n"
printf "  2. Lazy will install:   Plugins automatically on first launch\n"
printf "  3. Check health status: :checkhealth\n"
printf "  4. Measure start time:  nvim --startuptime startuptime.log +q\n\n"
printf "Enjoy your minimal, blazingly fast Neovim setup!\n\n"
