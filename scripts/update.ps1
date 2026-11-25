<#
.SYNOPSIS
    Cross-platform plugin update script for Windows (PowerShell).
    Pulls latest repo changes and restores Neovim plugins to lazy-lock.json.

.NOTES
    AI-generated configuration (Antigravity). Audit before running.
    See README.md for the full AI-authorship disclosure.

.DESCRIPTION
    1. Detects prerequisites (Git, Neovim).
    2. Optionally runs git pull --ff-only to fetch the latest commit.
    3. Restores Lazy plugins to the versions pinned in lazy-lock.json.
    4. Reports whether lazy-lock.json changed.

.PARAMETER DryRun
    Simulate steps without running git pull or Neovim restore.

.PARAMETER NoPull
    Skip git pull; restore plugins to the currently checked-out lazy-lock.json.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$NoPull
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step([string]$message) {
    Write-Host "`n==> " -ForegroundColor Cyan -NoNewline
    Write-Host $message -ForegroundColor White
}

function Write-Success([string]$message) {
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host $message
}

function Write-Warn([string]$message) {
    Write-Host "  [WARN] " -ForegroundColor Yellow -NoNewline
    Write-Host $message
}

function Write-Failure([string]$message) {
    Write-Host "  [ERROR] " -ForegroundColor Red -NoNewline
    Write-Host $message
}

# -----------------------------------------------------------------------------
# 1. Environment & Prerequisites
# -----------------------------------------------------------------------------
Write-Step "Detecting Environment"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceDir = Resolve-Path (Join-Path $scriptDir "..")
$targetConfigDir = Join-Path $env:LOCALAPPDATA "nvim"
$lockFile = Join-Path $sourceDir "lazy-lock.json"

Write-Host "  Source Path: $sourceDir"
Write-Host "  Target Path: $targetConfigDir"

if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Failure "Git was not found in PATH. Git is required to pull latest changes."
    exit 1
}
Write-Success "Found Git"

if (-not (Get-Command "nvim" -ErrorAction SilentlyContinue)) {
    Write-Failure "Neovim ('nvim') was not found in PATH."
    exit 1
}
$nvimVersionRaw = & nvim --version 2>&1 | Select-Object -First 1
Write-Success "Found Neovim: $nvimVersionRaw"

if (-not (Test-Path (Join-Path $sourceDir ".git"))) {
    Write-Failure "Source directory is not a git repository: $sourceDir"
    exit 1
}

if (-not (Test-Path $lockFile)) {
    Write-Failure "lazy-lock.json not found at: $lockFile"
    exit 1
}

# Warn if deployed config is a copy that may diverge from repo lockfile
if (Test-Path $targetConfigDir) {
    $item = Get-Item $targetConfigDir -Force
    $isLink = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    if (-not $isLink) {
        $resolvedTarget = (Resolve-Path $targetConfigDir).Path.TrimEnd('\')
        $resolvedSource = $sourceDir.Path.TrimEnd('\')
        if ($resolvedTarget -ne $resolvedSource) {
            Write-Warn "Target config is a copied directory, not a symlink/junction."
            Write-Host "       Pulled lockfile changes may not affect the deployed config until you redeploy/copy." -ForegroundColor DarkGray
        }
    }
}

Push-Location $sourceDir
try {
    $dirty = & git status --porcelain 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "git status failed: $dirty"
        exit 1
    }
    if ($dirty) {
        Write-Warn "Working tree has local changes; git pull --ff-only may fail if they conflict."
    }

    # -------------------------------------------------------------------------
    # 2. Pull latest commit
    # -------------------------------------------------------------------------
    if ($NoPull) {
        Write-Step "Skipping git pull (-NoPull)"
    } else {
        Write-Step "Pulling latest commit (git pull --ff-only)"
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would run: git pull --ff-only" -ForegroundColor DarkYellow
        } else {
            & git pull --ff-only
            if ($LASTEXITCODE -ne 0) {
                Write-Failure "git pull --ff-only failed. Resolve git state and retry, or rerun with -NoPull."
                exit $LASTEXITCODE
            }
            Write-Success "Repository is up to date."
        }
    }

    # -------------------------------------------------------------------------
    # 3. Restore plugins from lockfile
    # -------------------------------------------------------------------------
    Write-Step "Restoring plugins from lazy-lock.json"
    $restoreCmd = 'nvim --headless "+Lazy! restore" +qa'
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would run: $restoreCmd" -ForegroundColor DarkYellow
    } else {
        Write-Host "  Running: $restoreCmd" -ForegroundColor DarkGray
        & nvim --headless "+Lazy! restore" +qa 2>&1 | ForEach-Object { Write-Host "  $_" }
        $nvimExit = $LASTEXITCODE
        if ($nvimExit -ne 0) {
            Write-Failure "Neovim Lazy restore exited with code $nvimExit."
            exit $nvimExit
        }
        Write-Success "Lazy restore completed."
    }

    # -------------------------------------------------------------------------
    # 4. Lockfile status
    # -------------------------------------------------------------------------
    Write-Step "Checking lazy-lock.json status"
    $lockStatus = & git status --short -- lazy-lock.json 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Could not check lazy-lock.json status: $lockStatus"
    } elseif ($lockStatus) {
        Write-Warn "lazy-lock.json has changes after restore:"
        $lockStatus | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        Write-Host "  This script only restores to the lockfile; investigate unexpected lockfile changes." -ForegroundColor DarkGray
    } else {
        Write-Success "lazy-lock.json is unchanged."
    }
} finally {
    Pop-Location
}

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " Update Complete!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Notes:"
Write-Host "  - Plugins restored to versions pinned in lazy-lock.json"
Write-Host "  - To update plugin pins upstream: :Lazy update (then commit lazy-lock.json)"
Write-Host "  - To update Mason/TS: :MasonUpdate / :TSUpdate"
