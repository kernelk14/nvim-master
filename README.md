# Minimal, Performant, Cross-Platform Neovim Configuration

A clean, modular, and performant Neovim configuration built from the ground up using Lua. Designed for Linux, macOS, and Windows across x86_64 and ARM64 architectures.

![Neovim Version](https://img.shields.io/badge/Neovim-0.10.0%2B-57A143?logo=neovim&logoColor=white)
![Platforms](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-blue)
![Architecture](https://img.shields.io/badge/Arch-x86__64%20%7C%20ARM64-orange)
![Startup Time](https://img.shields.io/badge/Startup-%3C35ms-brightgreen)

---

## Highlights

- **Fast & Minimal**: Clean startup in under 35ms with zero bloat and aggressive lazy-loading.
- **Pure Core Isolation**: Core options, keymaps, and autocommands run completely independently of plugins.
- **Resilient & Safe**: Graceful degradation when external tools (`ripgrep`, C compilers, clipboard utilities) are missing.
- **Cross-Platform**: Seamless path handling and automated bootstrap scripts for Windows (PowerShell), Linux, and macOS (POSIX Bash).
- **Non-Destructive**: Automated timestamped backups prevent accidental overwriting of existing configs.
- **Modern Defaults**: Integrated LSP client, Treesitter syntax trees, smart autocompletion, fuzzy finding, and git status.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Platform Installation](#platform-installation)
   - [Windows](#windows)
   - [macOS](#macos)
   - [Linux](#linux)
3. [Quick Start & Automated Bootstrap](#quick-start--automated-bootstrap)
4. [Manual Installation](#manual-installation)
5. [Keybindings Cheatsheet](#keybindings-cheatsheet)
6. [Plugins Overview](#plugins-overview)
7. [Customization Guide](#customization-guide)
8. [Performance Profiling](#performance-profiling)
9. [Troubleshooting](#troubleshooting)
10. [Updating & Uninstalling](#updating--uninstalling)

---

## Prerequisites

| Tool | Status | Purpose | Minimum Version |
| :--- | :--- | :--- | :--- |
| **Neovim** | **Required** | Text editor engine | `>= 0.10.0` |
| **Git** | **Required** | Plugin downloading and version management | `>= 2.19.0` |
| **Ripgrep (`rg`)** | *Optional* | High-speed project-wide text search (Telescope `live_grep`) | Any recent |
| **fd (`fd` / `fdfind`)** | *Optional* | Fast file discovery respecting `.gitignore` | Any recent |
| **C Compiler (`gcc`, `clang`)** | *Optional* | Compiling Treesitter parsers locally from source | Any C99 compiler |
| **Clipboard Utility** | *Optional* | System clipboard synchronization (`"+y` / `"+p`) | See platform section |
| **Nerd Font** | *Optional* | Icons in statusline and fuzzy picker | Any Nerd Font v3+ |

---

## Platform Installation

### Windows

#### 1. Install Neovim
Using Windows Package Manager (recommended):
```powershell
winget install Neovim.Neovim
```
Or using Scoop:
```powershell
scoop install neovim
```
Or using Chocolatey:
```powershell
choco install neovim
```

#### 2. Install Git and Optional Dependencies
```powershell
winget install Git.Git
winget install BurntSushi.ripgrep.MSVC
winget install sharkdp.fd
# Optional C Compiler for Treesitter parsers:
winget install BrechtSanders.winlibs.ucrt.posix
```

*Note: Windows includes native clipboard support; no third-party clipboard utility is needed.*

---

### macOS

#### 1. Install Neovim & Git
Using Homebrew:
```bash
brew install neovim git
```

#### 2. Install Optional Tools
```bash
brew install ripgrep fd
# Install Apple Clang compiler tools:
xcode-select --install
```

*Note: macOS includes native clipboard support via `pbcopy` and `pbpaste`.*

---

### Linux

> [!IMPORTANT]
> Neovim in standard Debian and older Ubuntu (e.g. 20.04/22.04) repositories is often outdated (v0.4 to v0.6). Neovim `>= 0.10.0` is required. Use the official PPA, Flatpak, Snap, or pre-built AppImage/tarball.

#### Ubuntu / Debian
```bash
# Add official Neovim PPA for latest stable 0.10+
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim git ripgrep fd-find build-essential

# Clipboard support (choose based on display server):
sudo apt install wl-clipboard   # Wayland
# OR
sudo apt install xclip          # X11
```

#### Fedora
```bash
sudo dnf install neovim git ripgrep fd-find gcc wl-clipboard xclip
```

#### Arch Linux
```bash
sudo pacman -S neovim git ripgrep fd base-devel wl-clipboard xclip
```

#### Alpine Linux
```bash
sudo apk add neovim git ripgrep fd build-base
```

#### AppImage / Direct Binary (Any Linux Distro)
```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
```

---

## Quick Start & Automated Bootstrap

Automated bootstrap scripts are provided in `scripts/`. They detect your OS and CPU architecture, verify prerequisites, create a timestamped backup of any existing Neovim configuration, and deploy the configuration cleanly.

### Windows (PowerShell)
Open PowerShell and run:
```powershell
cd nvim-master
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```
*Options:*
- `-Method Symlink` (default; creates Directory Junction without needing Administrator privileges)
- `-Method Copy` (copies files instead of linking)
- `-BackupOnly` (only backs up the existing `%LOCALAPPDATA%\nvim` folder)
- `-DryRun` (previews actions without modifying disk)

### Linux & macOS (POSIX Bash)
Open terminal and run:
```bash
cd nvim-master
chmod +x ./scripts/install.sh
./scripts/install.sh
```
*Options:*
- `--link` (default; creates symbolic link to `~/.config/nvim`)
- `--copy` (copies files)
- `--backup-only` (only backs up existing config)
- `--dry-run` (previews actions without changes)

---

## Manual Installation

If you prefer to configure manually without running the bootstrap script:

### Linux & macOS
```bash
# 1. Safely backup existing config if present
[ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%Y%m%d_%H%M%S)"

# 2. Clone or link repository
git clone https://github.com/your-username/nvim-master.git "$HOME/.config/nvim"

# 3. Launch Neovim
nvim
```

### Windows (PowerShell)
```powershell
# 1. Safely backup existing config if present
if (Test-Path "$env:LOCALAPPDATA\nvim") {
    Move-Item "$env:LOCALAPPDATA\nvim" "$env:LOCALAPPDATA\nvim.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

# 2. Clone or copy repository
git clone https://github.com/your-username/nvim-master.git "$env:LOCALAPPDATA\nvim"

# 3. Launch Neovim
nvim
```

---

## Keybindings Cheatsheet

Leader key is mapped to `<Space>`.

### General & Windows
| Keybinding | Mode | Action |
| :--- | :--- | :--- |
| `<Esc>` | Normal | Clear search highlights (`:nohlsearch`) |
| `<C-s>` | Normal, Insert | Fast save current file (`:w`) |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | Normal | Navigate between window splits |
| `<C-Up>` / `<C-Down>` | Normal | Resize window height |
| `<C-Left>` / `<C-Right>` | Normal | Resize window width |
| `<leader>wv` | Normal | Split window vertically (`:vsplit`) |
| `<leader>ws` | Normal | Split window horizontally (`:split`) |
| `<leader>wd` | Normal | Close current window split |
| `<leader>we` | Normal | Make split windows equal size |

### Buffers & Quickfix
| Keybinding | Mode | Action |
| :--- | :--- | :--- |
| `[b` / `]b` | Normal | Previous / Next buffer |
| `<leader>bd` | Normal | Safely close buffer (keeps split open) |
| `[q` / `]q` | Normal | Previous / Next quickfix entry |
| `[d` / `]d` | Normal | Previous / Next LSP diagnostic |
| `<leader>cd` | Normal | Show diagnostic details in floating window |

### Visual Editing
| Keybinding | Mode | Action |
| :--- | :--- | :--- |
| `J` / `K` | Visual | Move selected block down / up |
| `<` / `>` | Visual | Indent left / right (retains selection) |
| `p` | Visual (`x`) | Paste without overwriting default register |

### Fuzzy Finder (Telescope)
| Keybinding | Mode | Action |
| :--- | :--- | :--- |
| `<leader><space>` or `<leader>ff` | Normal | Find files in project root |
| `<leader>fg` | Normal | Live text grep across project (requires `rg`) |
| `<leader>fb` | Normal | Switch between open buffers |
| `<leader>fr` | Normal | Search recently opened files |
| `<leader>fh` | Normal | Search Neovim help documentation |
| `<leader>fd` | Normal | Search LSP diagnostics across project |
| `<leader>fc` | Normal | Find configuration files in Neovim directory |

### Code & LSP (Active when Language Server is attached)
| Keybinding | Mode | Action |
| :--- | :--- | :--- |
| `gd` | Normal | Jump to Definition |
| `gD` | Normal | Jump to Declaration |
| `gr` | Normal | List all References |
| `gi` | Normal | Jump to Implementation |
| `K` | Normal | Display Hover documentation |
| `<C-k>` | Normal, Insert | Display Signature help |
| `<leader>cr` | Normal | Rename symbol under cursor |
| `<leader>ca` | Normal, Visual | Trigger code action |
| `<leader>cf` | Normal | Format current buffer |
| `<leader>ch` | Normal | Toggle Inlay Hints (Neovim 0.10+) |

### Git (Gitsigns)
| Keybinding | Mode | Action |
| :--- | :--- | :--- |
| `]c` / `[c` | Normal | Jump to Next / Previous git change hunk |
| `<leader>hs` | Normal, Visual | Stage hunk under cursor / selection |
| `<leader>hr` | Normal, Visual | Reset hunk under cursor / selection |
| `<leader>hp` | Normal | Preview diff for hunk in floating popup |
| `<leader>hb` | Normal | Show git blame for current line |
| `<leader>hd` | Normal | Diff current file against git index |

---

## Plugins Overview

Every plugin in this configuration was chosen deliberately for stability, maintenance track record, and low footprint:

- **`folke/lazy.nvim`**: Lightning-fast plugin manager with automatic shallow clones, dependency graph management, and lockfile reproducibility.
- **`folke/tokyonight.nvim`**: Clean, modern dark theme with deep darks, vibrant accents, and built-in integrations for Treesitter, LSP, and Lualine.
- **`nvim-treesitter/nvim-treesitter`**: Syntax parsing engine that generates concrete syntax trees for accurate code coloring, folding, and indentation.
- **`neovim/nvim-lspconfig`**: Configures language servers to communicate with Neovim's native LSP client.
- **`williamboman/mason.nvim` & `mason-lspconfig.nvim`**: Package manager that downloads and updates language servers locally inside Neovim.
- **`hrsh7th/nvim-cmp` & `L3MON4D3/LuaSnip`**: Asynchronous popup autocompletion and snippet expansion.
- **`nvim-telescope/telescope.nvim`**: Fuzzy finder for navigating files, text, buffers, and symbols.
- **`nvim-lualine/lualine.nvim`**: Lightweight, responsive statusline showing mode, git status, file info, and diagnostics.
- **`akinsho/bufferline.nvim`**: Clean top buffer/tabline with LSP diagnostic badges, pinning, and close options.
- **`folke/which-key.nvim`**: Discoverability helper displaying popup cheatsheets when you pause on a key prefix.
- **`windwp/nvim-autopairs`**: Automatically closes parentheses, brackets, and quotes.
- **`lewis6991/gitsigns.nvim`**: Real-time git changes displayed directly in the gutter without blocking the editor.
- **`akinsho/flutter-tools.nvim`**: Comprehensive Flutter suite: widget closing tags, hot reload/restart, device/emulator runner.
- **`gbprod/phpactor.nvim`**: PHP context refactoring, class generation, and namespace management for PHP/CodeIgniter.

---

## Customization Guide

The modular directory layout makes extending and modifying your setup straightforward:

### Adjusting Editor Options
Open [lua/config/options.lua](file:///lua/config/options.lua) and edit standard Vim options:
```lua
vim.opt.tabstop = 4        -- Change indentation to 4 spaces
vim.opt.shiftwidth = 4
vim.opt.wrap = true        -- Enable line wrapping
```

### Adding Custom Keymaps
Open [lua/config/keymaps.lua](file:///lua/config/keymaps.lua) and use standard `vim.keymap.set`:
```lua
vim.keymap.set("n", "<leader>w-", "<cmd>split<CR>", { desc = "Horizontal split" })
```

### Adding New Plugins
Create a new `.lua` file inside `lua/plugins/` (e.g., `lua/plugins/markdown.lua`). Lazy.nvim will automatically detect and load it:
```lua
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    opts = {},
  },
}
```

### Adding New Language Servers
To add support for a language server (e.g. Python via `pyright` or TypeScript via `ts_ls`):
1. In Neovim, run `:Mason` and press `i` on the desired server, OR:
2. Add the server name to `ensure_installed` inside [lua/plugins/lsp.lua](file:///lua/plugins/lsp.lua):
```lua
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "pyright", "ts_ls" },
  -- ...
})
```

---

## Performance Profiling

To measure your startup time on any platform:

```bash
nvim --startuptime startuptime.log +q
```

Open `startuptime.log` to inspect startup metrics:
- Typical startup time on modern hardware: **18ms – 32ms**.
- The bottom lines of `startuptime.log` display total elapsed time from execution to ready state.

Inside Neovim, run:
```vim
:Lazy profile
```
This presents an interactive breakdown of the exact milliseconds taken by each plugin.

---

## Troubleshooting

### 1. `Treesitter: no compiler found`
- **Windows**: Install MinGW via `winget install BrechtSanders.winlibs.ucrt.posix` or Clang via `winget install LLVM.LLVM`.
- **macOS**: Run `xcode-select --install`.
- **Linux**: Install `build-essential` (Ubuntu/Debian) or `base-devel` (Arch) or `gcc` (Fedora).
- *Note:* Even without a compiler, Neovim continues to operate normally using built-in Vim syntax highlighting.

### 2. `Ripgrep is not installed` on `<leader>fg`
Live grep requires `ripgrep`. Install it via your package manager:
- Windows: `winget install BurntSushi.ripgrep.MSVC`
- macOS: `brew install ripgrep`
- Linux: `sudo apt install ripgrep`

### 3. Clipboard not synchronizing on Linux
Install a clipboard utility matching your display server:
- Wayland: `sudo apt install wl-clipboard`
- X11: `sudo apt install xclip`

### 4. Icons display as question marks or boxes
Install a Nerd Font (e.g., JetBrainsMono Nerd Font, FiraCode Nerd Font) from [nerdfonts.com](https://www.nerdfonts.com/) and configure your terminal emulator to use it.

---

## Updating & Uninstalling

### Updating
- Update plugins: Inside Neovim, run `:Lazy update`
- Update Treesitter parsers: Run `:TSUpdate`
- Update Mason packages: Run `:MasonUpdate`

### Uninstalling
To remove this configuration and restore a backup:

#### Linux & macOS:
```bash
rm -rf "$HOME/.config/nvim"
# If you have a backup:
mv "$HOME/.config/nvim.bak.YYYYMMDD_HHMMSS" "$HOME/.config/nvim"
```

#### Windows:
```powershell
Remove-Item "$env:LOCALAPPDATA\nvim" -Force -Recurse
# If you have a backup:
Move-Item "$env:LOCALAPPDATA\nvim.bak.YYYYMMDD-HHMMSS" "$env:LOCALAPPDATA\nvim"
```
