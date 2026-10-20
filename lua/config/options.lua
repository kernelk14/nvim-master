-- AI-generated configuration (Antigravity). See README.md for the authorship disclosure.
-- Core Neovim Options
-- Sensible, cross-platform defaults with zero plugin dependencies

local opt = vim.opt

-- Line numbers
opt.number = true          -- Show line numbers
opt.relativenumber = true  -- Relative line numbers for efficient jumping

-- Indentation & Tabs (2 spaces standard, easily adjustable per project)
opt.tabstop = 2            -- Number of visual spaces per TAB
opt.shiftwidth = 2         -- Number of spaces to use for each step of (auto)indent
opt.softtabstop = 2        -- Number of spaces that a <Tab> counts for while editing
opt.expandtab = true       -- Use spaces instead of tabs
opt.smartindent = true     -- Insert indents automatically
opt.shiftround = true      -- Round indent to multiple of 'shiftwidth'

-- Line wrapping
opt.wrap = false           -- Disable line wrap by default for clean code reading

-- Search behavior
opt.ignorecase = true      -- Ignore case in search patterns
opt.smartcase = true       -- Override ignorecase if search pattern contains uppercase
opt.hlsearch = true        -- Highlight search matches
opt.incsearch = true       -- Show matches as you type

-- Cursor & Scrolling
opt.cursorline = true      -- Highlight the text line of the cursor
opt.scrolloff = 8          -- Minimal number of screen lines to keep above and below cursor
opt.sidescrolloff = 8      -- Minimal number of screen columns to keep to the left and right

-- Splits
opt.splitright = true      -- Put new windows right of current
opt.splitbelow = true      -- Put new windows below current

-- Visuals & Colors
opt.termguicolors = true   -- True color support in terminals
opt.signcolumn = "yes"     -- Always show signcolumn (avoids text shifting on diagnostic icons)
opt.pumheight = 10       -- Maximum number of items in popup menu
opt.showmode = false       -- Mode is displayed in the statusline, no need for -- INSERT --

-- Undo & Persistence
opt.undofile = true        -- Save undo history to an undo file across sessions
opt.swapfile = false       -- Disable swapfile (undo and git handle history)
opt.backup = false         -- Do not create backup files

-- Timing & Responsiveness
opt.updatetime = 250       -- Faster completion and git gutter updates (default 4000ms)
opt.timeoutlen = 300       -- Faster key sequence completion time

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- Safety & Usability
opt.confirm = true         -- Confirm to save changes before exiting modified buffer
opt.mouse = "a"            -- Enable mouse support in all modes

-- System Clipboard
-- Attempt to sync with system clipboard safely; fails gracefully if no clipboard provider exists
local has_clipboard, _ = pcall(function()
  opt.clipboard = "unnamedplus"
end)
if not has_clipboard then
  vim.notify_once("Clipboard sync disabled: no system clipboard provider detected.", vim.log.levels.INFO)
end
