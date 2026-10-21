# Architecture & Design Rationale

This document describes the architectural philosophy, directory layout, lifecycle execution sequence, and cross-platform design decisions of this Neovim configuration.

> [!IMPORTANT]
> **This entire configuration was written by an AI coding agent (Antigravity).**
> The architecture described below — the directory layout, the startup sequence, the plugin selections, and the cross-platform rationale — was designed and implemented by AI using [Google Antigravity](https://antigravity.google/). It is a generated design document, not a human-written engineering spec, and it has not been peer-reviewed. Treat it as a starting point and verify it against the actual code.

---

## 1. Design Philosophy

1. **Zero Hard Failure (Graceful Degradation)**:
   Neovim should function as a world-class text editor even if network connectivity is absent, Git is missing, external CLI utilities (`ripgrep`, `fd`) are not yet installed, or a C compiler is unavailable. Core options, keymaps, and autocommands run in pure Lua without external plugin dependencies.
2. **Predictable & Discoverable Keymaps**:
   Mappings follow consistent prefixes under `<Space>` (Leader):
   - `<leader>f` - Find / File operations (Telescope)
   - `<leader>c` - Code intelligence, formatting, actions (LSP)
   - `<leader>w` - Window splits and management
   - `<leader>b` - Buffer navigation and deletion
   - `<leader>d` - Dashboard / start screen
   - `<leader>g` / `<leader>h` - Git hunk inspection and staging (Gitsigns)
   - `<leader>x` - Diagnostics and quickfix
3. **Sub-50ms Startup Footprint**:
   Non-essential plugins (syntax highlighters, LSP servers, statuslines, completion menus) are lazy-loaded on appropriate events (`BufReadPost`, `InsertEnter`, `VeryLazy`). Redundant legacy Vim plugins (`netrw`, `tutor`, `tarPlugin`, `zipPlugin`) are disabled from the runtime path.
4. **Platform & Architecture Agnostic**:
   Strict portability across Linux (glibc and musl), macOS (Intel and Apple Silicon ARM64), and Windows (x86_64 and ARM64). Absolute paths, shell-specific idioms, and platform-exclusive tools are avoided.

---

## 2. Directory Layout

```
nvim/
├── init.lua                   # Lightweight entry point (< 25 lines)
├── lua/
│   ├── config/
│   │   ├── init.lua           # Module loader & version compatibility checks
│   │   ├── options.lua        # Editor options (indentation, splits, undo, UI)
│   │   ├── keymaps.lua        # Core keymaps (window, buffer, visual mode)
│   │   ├── autocmds.lua       # Autocommands (highlight yank, resize, close utility)
│   │   └── lazy.lua           # Lazy.nvim bootstrapper & performance profile
│   └── plugins/
│       ├── colorscheme.lua    # Tokyo Night theme (priority: 1000, eager-loaded)
│       ├── treesitter.lua     # AST syntax highlighting (lazy-loaded on BufReadPost)
│       ├── lsp.lua            # LSP client, Mason installer, buffer-local keymaps
│       ├── cmp.lua            # Popup completion & snippets (lazy-loaded on InsertEnter)
│       ├── telescope.lua      # Fuzzy finder with safe fallback when rg is missing
│       ├── ui.lua             # Lualine statusline & Which-Key helper (VeryLazy)
│       ├── dashboard.lua      # Start screen: gradient header, cards & keybinding cheat sheet
│       ├── bufferline.lua     # Bufferline tab/buffer header (VeryLazy)
│       ├── flutter.lua        # Flutter & Dart tooling (closing tags, hot reload/restart)
│       ├── php.lua            # PHP & CodeIgniter refactoring and context actions
│       └── coding.lua         # Autopairs and Gitsigns (gutter status & hunks)
├── scripts/
│   ├── install.sh             # POSIX / macOS bootstrap script (safe backup, symlink/copy)
│   └── install.ps1            # Windows PowerShell bootstrap script (safe backup, junction/copy)
├── .editorconfig              # Consistent whitespace and line ending rules
├── .gitignore                 # Excludes caches, swapfiles, and runtime artifacts
├── ARCHITECTURE.md            # Architectural specification (this document)
├── VALIDATION.md              # Automated validation records & verification commands
└── README.md                  # Comprehensive user and administrator guide
```

---

## 3. Startup Sequence & Execution Lifecycle

```
[Neovim Launch]
       │
       ▼
[init.lua]
  ├─> Ensure config directory is in runtimepath (rtp)
  ├─> Define vim.g.mapleader = " " and maplocalleader = " "
  ├─> require("config.options")   ──> Pure Lua, 0ms overhead, sets vim.opt
  ├─> require("config.keymaps")   ──> Binds universal navigation & window controls
  ├─> require("config.autocmds")  ──> Configures yank highlights, split resizing
  └─> require("config.lazy")
            │
            ├─> Check if lazy.nvim exists in stdpath("data")/lazy/lazy.nvim
            │     └─ If missing: shallow-clone via Git (if git exists)
            │
            ├─> Prepend lazy.nvim to rtp
            │
            └─> lazy.setup("plugins", { defaults = { lazy = true } })
                      │
                      ├── [Phase 1: Startup (Eager)]
                      │     ├─ tokyonight (priority 1000) -> eliminates visual flicker
                      │     └─ nvim-dashboard (priority 900) -> renders the start screen on VimEnter
                      │
                      ├── [Phase 2: File Open (BufReadPost / BufReadPre)]
                      │     ├─ nvim-treesitter (activates parser & syntax tree)
                      │     ├─ nvim-lspconfig (attaches language servers)
                      │     └─ gitsigns.nvim (renders gutter indicators)
                      │
                      ├── [Phase 3: Interactive Editing (InsertEnter)]
                      │     ├─ nvim-cmp (activates completion engine)
                      │     └─ nvim-autopairs (enables pair auto-closing)
                      │
                      └── [Phase 4: Idle UI (VeryLazy)]
                            ├─ which-key.nvim (registers keymap cheat sheets)
                            └─ lualine.nvim (initializes statusline)
```

---

## 4. Cross-Platform Rationale & Limitations

| Aspect | Linux | macOS | Windows | Architecture Nuance |
| :--- | :--- | :--- | :--- | :--- |
| **Config Location** | `~/.config/nvim` (`$XDG_CONFIG_HOME`) | `~/.config/nvim` (`$XDG_CONFIG_HOME`) | `%LOCALAPPDATA%\nvim` | Universal resolution via `vim.fn.stdpath("config")`. |
| **Data / Plugins** | `~/.local/share/nvim` | `~/.local/share/nvim` | `%LOCALAPPDATA%\nvim-data` | Universal resolution via `vim.fn.stdpath("data")`. |
| **Clipboard Provider** | `wl-clipboard` (Wayland) or `xclip` / `xsel` (X11) | Built-in `pbcopy` / `pbpaste` | Built-in clipboard | Protected with `pcall` so missing clipboard tools do not abort startup. |
| **Path Separators** | `/` forward slash | `/` forward slash | `\` or `/` | Lua code uses `/` throughout; Neovim standard library handles normalization. |
| **Directory Linking** | Symbolic link (`ln -s`) | Symbolic link (`ln -s`) | Directory Junction (`New-Item -ItemType Junction`) | Junctions avoid Windows Administrator or Developer Mode privilege requirements. |
| **C Compilers for Treesitter** | `gcc`, `clang`, `zig` | Apple Clang (`xcode-select --install`) | MinGW-w64 (`gcc`), Clang, or MSVC (`cl`) | `auto_install` dynamically checks for compiler executables before attempting parser builds. |
| **Fuzzy Searcher** | `ripgrep` (`rg`) | `ripgrep` (`rg`) | `ripgrep` (`rg.exe`) | Telescope uses Pure Lua fuzzy matching; checks `executable('rg')` before running live grep. |
| **ARM64 vs x86_64** | Full native support across x86_64 and aarch64 | Full native support (Apple Silicon M1-M4 & Intel) | Full native support (x64 and Surface ARM64) | Mason installs platform-appropriate pre-compiled binaries per target architecture. |

---

## 5. Plugin Selection Rationale

| Plugin | Purpose | Why This Choice? |
| :--- | :--- | :--- |
| **folke/lazy.nvim** | Plugin Manager | Modern standard: lockfile support, automatic shallow git cloning, lazy-loading engine, zero boilerplate. |
| **folke/tokyonight.nvim** | Colorscheme | Clean contrast, zero startup lag, vibrant accents, comprehensive integration with Treesitter, LSP, Telescope, and Lualine. |
| **nvim-treesitter/nvim-treesitter** | Syntax Highlighting | Concrete syntax tree parsing replaces slow regex parsing; provides accurate indentation and folding. |
| **neovim/nvim-lspconfig** | LSP Client Configurations | Official Neovim repository for language server setups; minimal wrapper over Neovim's built-in LSP client. |
| **williamboman/mason.nvim** | Tool / LSP Installer | Self-contained package manager for LSPs, DAP servers, linters, and formatters directly inside Neovim. |
| **hrsh7th/nvim-cmp** + **LuaSnip** | Autocompletion & Snippets | Modular completion framework with low latency; supports LSP, buffer words, and file system paths. |
| **nvim-telescope/telescope.nvim** | Fuzzy Finder | High extensibility, pure Lua fallback without hard C dependencies, intuitive preview window. |
| **nvim-lualine/lualine.nvim** | Statusline | Blazingly fast, negligible overhead, automatically reflects git branch, file format, and LSP diagnostics. |
| **akinsho/bufferline.nvim** | Bufferline / Tabs | Snappy top-of-window bufferline with LSP diagnostic badges and pinning support. |
| **folke/which-key.nvim** | Keymap Discovery | Instant popup guidance when typing prefix keys; eliminates need to memorize uncommon shortcuts. |
| **kernelk14/nvim-dashboard** | Start Screen | Dependency-free welcome screen whose palette is derived from the active colorscheme, so it never drifts from the Tokyo Night theme. |
| **windwp/nvim-autopairs** | Bracket / Quote Matching | Lightweight auto-closing pairs with intelligent Treesitter context detection and `nvim-cmp` integration. |
| **lewis6991/gitsigns.nvim** | Git Gutter & Hunks | Written in pure Lua using Neovim's extmarks; non-blocking asynchronous git diff tracking. |
| **akinsho/flutter-tools.nvim** | Flutter & Dart Development | Widget closing labels, outline, hot reload/restart, device/emulator runner. |
| **gbprod/phpactor.nvim** | PHP & CodeIgniter Refactoring | Class generation, namespace import, contextual refactoring for PHP projects. |
