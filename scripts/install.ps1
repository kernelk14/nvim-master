<#
.SYNOPSIS
    Cross-platform automated bootstrap script for Windows (PowerShell).
    Installs, backs up, and validates the minimal Neovim configuration.

.NOTES
    AI-generated configuration (Antigravity). This script was written by an AI
    coding agent. Audit it before running. See README.md for the full
    AI-authorship disclosure.

.DESCRIPTION
    1. Detects OS architecture and system prerequisites (Neovim >= 0.10.0, Git, ripgrep, compilers).
    2. Safely creates a timestamped backup of any existing Neovim configuration.
    3. Deploys the configuration to $env:LOCALAPPDATA\nvim via directory junction/symlink or copy.
    4. Validates the installation using headless Neovim execution.

.PARAMETER Method
    Deployment method: 'Symlink' (default, uses Directory Junction which does not require Admin) or 'Copy'.

.PARAMETER BackupOnly
    If set, only backs up the existing Neovim configuration and exits.

.PARAMETER DryRun
    Simulate steps without writing changes to disk.

.PARAMETER Force
    Overwrites the destination without prompting if a non-backup folder conflict exists.
#>

[CmdletBinding()]
param(
    [ValidateSet("Symlink", "Copy")]
    [string]$Method = "Symlink",

    [switch]$BackupOnly,
    [switch]$DryRun,
    [switch]$Force
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
# 1. System & Architecture Detection
# -----------------------------------------------------------------------------
Write-Step "Detecting System Environment"

$osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$osDesc = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
Write-Host "  OS:           $osDesc"
Write-Host "  Architecture: $osArch"
Write-Host "  PowerShell:   $($PSVersionTable.PSVersion)"

# Resolve repository source root (directory containing this script's parent)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceDir = Resolve-Path (Join-Path $scriptDir "..")
Write-Host "  Source Path:  $sourceDir"

$targetConfigDir = Join-Path $env:LOCALAPPDATA "nvim"
Write-Host "  Target Path:  $targetConfigDir"

# -----------------------------------------------------------------------------
# 2. Prerequisite Checks
# -----------------------------------------------------------------------------
Write-Step "Checking Prerequisites"

# Neovim Check
$nvimCmd = Get-Command "nvim" -ErrorAction SilentlyContinue
if (-not $nvimCmd) {
    Write-Failure "Neovim ('nvim') was not found in your PATH."
    Write-Host "  Install Neovim via winget: winget install Neovim.Neovim" -ForegroundColor Cyan
    Write-Host "  Or via Scoop:              scoop install neovim" -ForegroundColor Cyan
    Write-Host "  Or via Chocolatey:         choco install neovim" -ForegroundColor Cyan
    exit 1
}

$nvimVersionRaw = & nvim --version 2>&1 | Select-Object -First 1
Write-Success "Found Neovim: $nvimVersionRaw"

# Extract version numbers to ensure >= 0.10.0
if ($nvimVersionRaw -match "v(\d+)\.(\d+)\.(\d+)") {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    if ($major -eq 0 -and $minor -lt 10) {
        Write-Warn "Neovim version is older than 0.10.0. While basic editing works, modern features (inlay hints, native commenting) require >= 0.10.0."
    }
}

# Git Check
$gitCmd = Get-Command "git" -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    Write-Failure "Git was not found in your PATH. Plugin management (lazy.nvim) requires Git."
    Write-Host "  Install Git via winget: winget install Git.Git" -ForegroundColor Cyan
    exit 1
}
$gitVersionRaw = & git --version 2>&1
Write-Success "Found Git: $gitVersionRaw"

# Optional: Ripgrep
$rgCmd = Get-Command "rg" -ErrorAction SilentlyContinue
if ($rgCmd) {
    Write-Success "Found Ripgrep (fast file and text search enabled)"
} else {
    Write-Warn "Ripgrep ('rg') not found (optional). Live grep will notify you to install it."
    Write-Host "       Install via: winget install BurntSushi.ripgrep.MSVC" -ForegroundColor DarkGray
}

# Optional: C Compiler (for treesitter parser compilation)
$compilers = @("gcc", "clang", "cl", "zig")
$foundCompiler = $null
foreach ($comp in $compilers) {
    if (Get-Command $comp -ErrorAction SilentlyContinue) {
        $foundCompiler = $comp
        break
    }
}
if ($foundCompiler) {
    Write-Success "Found C Compiler: $foundCompiler (Treesitter AST compilation enabled)"
} else {
    Write-Warn "No C compiler found (optional). Neovim will use precompiled parsers or fallback regex syntax."
    Write-Host "       Install MinGW via: winget install BrechtSanders.winlibs.ucrt.posix" -ForegroundColor DarkGray
}

# -----------------------------------------------------------------------------
# 3. Safe Backup of Existing Configuration
# -----------------------------------------------------------------------------
Write-Step "Checking Existing Neovim Configuration"

if (Test-Path $targetConfigDir) {
    $timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $backupDir = Join-Path $env:LOCALAPPDATA "nvim.bak.$timestamp"

    Write-Warn "Existing configuration detected at: $targetConfigDir"
    Write-Host "  Safely creating backup at: $backupDir" -ForegroundColor Cyan

    if (-not $DryRun) {
        # Check if target is a symlink / junction
        $item = Get-Item $targetConfigDir
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            # Target is a symlink/junction, remove the link without touching source
            Write-Host "  Existing target is a symbolic link or junction. Removing reparse point..."
            Remove-Item $targetConfigDir -Force -Recurse
        } else {
            # Target is an actual folder, move it to backup
            Move-Item -Path $targetConfigDir -Destination $backupDir
            Write-Success "Backup created successfully at: $backupDir"
        }
    } else {
        Write-Host "  [DRY RUN] Would move '$targetConfigDir' to '$backupDir'" -ForegroundColor DarkYellow
    }
} else {
    Write-Success "No previous configuration conflict detected."
}

if ($BackupOnly) {
    Write-Success "BackupOnly flag specified. Exiting cleanly."
    exit 0
}

# -----------------------------------------------------------------------------
# 4. Deployment (Junction / Symlink or Copy)
# -----------------------------------------------------------------------------
Write-Step "Deploying Configuration ($Method)"

if (-not $DryRun) {
    if ($Method -eq "Symlink") {
        try {
            # Use Directory Junction (requires no admin privileges on Windows)
            $null = New-Item -ItemType Junction -Path $targetConfigDir -Target $sourceDir -ErrorAction Stop
            Write-Success "Created Directory Junction from '$targetConfigDir' -> '$sourceDir'"
        } catch {
            Write-Warn "Failed to create Directory Junction: $($_.Exception.Message)"
            Write-Host "  Falling back to file copy method..." -ForegroundColor Cyan
            Copy-Item -Path $sourceDir -Destination $targetConfigDir -Recurse -Force
            Write-Success "Configuration copied to '$targetConfigDir'"
        }
    } else {
        Copy-Item -Path $sourceDir -Destination $targetConfigDir -Recurse -Force
        Write-Success "Configuration copied to '$targetConfigDir'"
    }
} else {
    Write-Host "  [DRY RUN] Would deploy source '$sourceDir' to '$targetConfigDir' via $Method" -ForegroundColor DarkYellow
}

# -----------------------------------------------------------------------------
# 5. Validation Check
# -----------------------------------------------------------------------------
Write-Step "Validating Neovim Configuration"

if (-not $DryRun) {
    try {
        $valOutput = & nvim --headless "+lua print('Neovim configuration loaded successfully!')" +q 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Neovim successfully parsed and executed configuration!"
        } else {
            Write-Warn "Neovim exited with code $LASTEXITCODE. Output: $valOutput"
        }
    } catch {
        Write-Warn "Could not run headless check: $($_.Exception.Message)"
    }
}

# -----------------------------------------------------------------------------
# 6. Completion Summary
# -----------------------------------------------------------------------------
Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " Installation Complete!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "  1. Start Neovim:        nvim"
Write-Host "  2. Lazy will install:   Plugins automatically on first launch"
Write-Host "  3. Check health status: :checkhealth"
Write-Host "  4. Measure start time:  nvim --startuptime startuptime.log +q"
Write-Host "`nEnjoy your minimal, blazingly fast Neovim setup!`n"
