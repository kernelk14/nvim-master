#!/usr/bin/env bash
# ==============================================================================
# Cross-Platform Plugin Update Script for Linux and macOS
# Pulls latest repo changes and restores Neovim plugins to lazy-lock.json.
#
# AI-generated configuration (Antigravity). Audit before running.
# See README.md for the full AI-authorship disclosure.
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() { printf "\n${CYAN}==>${NC} %s\n" "$1"; }
print_success() { printf "  ${GREEN}[OK]${NC} %s\n" "$1"; }
print_warn() { printf "  ${YELLOW}[WARN]${NC} %s\n" "$1"; }
print_err() { printf "  ${RED}[ERROR]${NC} %s\n" "$1"; }

DRY_RUN=0
NO_PULL=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Pull latest git commit (ff-only) and restore Lazy plugins to lazy-lock.json.

Options:
  --no-pull    Skip git pull; restore to currently checked-out lazy-lock.json
  --dry-run    Simulate steps without making changes
  -h, --help   Show this help message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pull) NO_PULL=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage ;;
    *) print_err "Unknown argument: $1"; usage ;;
  esac
done

# ------------------------------------------------------------------------------
# 1. Environment & Prerequisites
# ------------------------------------------------------------------------------
print_step "Detecting Environment"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET_DIR="$CONFIG_HOME/nvim"
LOCK_FILE="$SOURCE_DIR/lazy-lock.json"

printf "  Source Path: %s\n" "$SOURCE_DIR"
printf "  Target Path: %s\n" "$TARGET_DIR"

if ! command -v git >/dev/null 2>&1; then
  print_err "Git is not installed or not in PATH."
  exit 1
fi
print_success "Found Git: $(git --version)"

if ! command -v nvim >/dev/null 2>&1; then
  print_err "Neovim ('nvim') is not installed or not in PATH."
  exit 1
fi
print_success "Found Neovim: $(nvim --version | head -n 1)"

if [ ! -d "$SOURCE_DIR/.git" ]; then
  print_err "Source directory is not a git repository: $SOURCE_DIR"
  exit 1
fi

if [ ! -f "$LOCK_FILE" ]; then
  print_err "lazy-lock.json not found at: $LOCK_FILE"
  exit 1
fi

# Warn if deployed config is a copy that may diverge from repo lockfile
if [ -e "$TARGET_DIR" ] && [ ! -L "$TARGET_DIR" ]; then
  RESOLVED_TARGET="$(cd "$TARGET_DIR" && pwd -P)"
  RESOLVED_SOURCE="$(cd "$SOURCE_DIR" && pwd -P)"
  if [ "$RESOLVED_TARGET" != "$RESOLVED_SOURCE" ]; then
    print_warn "Target config is a copied directory, not a symbolic link."
    printf "       Pulled lockfile changes may not affect the deployed config until you redeploy/copy.\n"
  fi
fi

cd "$SOURCE_DIR"

if [ -n "$(git status --porcelain)" ]; then
  print_warn "Working tree has local changes; git pull --ff-only may fail if they conflict."
fi

# ------------------------------------------------------------------------------
# 2. Pull latest commit
# ------------------------------------------------------------------------------
if [ "$NO_PULL" -eq 1 ]; then
  print_step "Skipping git pull (--no-pull)"
else
  print_step "Pulling latest commit (git pull --ff-only)"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  [DRY RUN] Would run: git pull --ff-only\n"
  else
    git pull --ff-only
    print_success "Repository is up to date."
  fi
fi

# ------------------------------------------------------------------------------
# 3. Restore plugins from lockfile
# ------------------------------------------------------------------------------
print_step "Restoring plugins from lazy-lock.json"
RESTORE_CMD='nvim --headless "+Lazy! restore" +qa'
if [ "$DRY_RUN" -eq 1 ]; then
  printf "  [DRY RUN] Would run: %s\n" "$RESTORE_CMD"
else
  printf "  Running: %s\n" "$RESTORE_CMD"
  nvim --headless "+Lazy! restore" +qa
  print_success "Lazy restore completed."
fi

# ------------------------------------------------------------------------------
# 4. Lockfile status
# ------------------------------------------------------------------------------
print_step "Checking lazy-lock.json status"
LOCK_STATUS="$(git status --short -- lazy-lock.json || true)"
if [ -n "$LOCK_STATUS" ]; then
  print_warn "lazy-lock.json has changes after restore:"
  printf "%s\n" "$LOCK_STATUS" | sed 's/^/  /'
  printf "  This script only restores to the lockfile; investigate unexpected lockfile changes.\n"
else
  print_success "lazy-lock.json is unchanged."
fi

printf "\n${GREEN}========================================================${NC}\n"
printf "${GREEN} Update Complete!${NC}\n"
printf "${GREEN}========================================================${NC}\n"
printf "Notes:\n"
printf "  - Plugins restored to versions pinned in lazy-lock.json\n"
printf "  - To update plugin pins upstream: :Lazy update (then commit lazy-lock.json)\n"
printf "  - To update Mason/TS: :MasonUpdate / :TSUpdate\n"
