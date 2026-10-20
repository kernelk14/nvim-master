-- AI-generated configuration (Antigravity). See README.md for the authorship disclosure.
-- Core configuration entry point
-- Loads pure Neovim settings (options, keymaps, autocommands)
-- followed by the lazy.nvim plugin ecosystem.

-- Ensure the directory containing init.lua is in runtimepath
-- (ensures portability whether installed in stdpath('config') or run directly with nvim -u)
local config_dir = vim.fn.fnamemodify(vim.fn.resolve(debug.getinfo(1, "S").source:sub(2)), ":p:h")
if not vim.tbl_contains(vim.opt.rtp:get(), config_dir) then
  vim.opt.rtp:prepend(config_dir)
end

-- Set leader keys early to ensure mappings register correctly
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load core settings (works completely independently of plugins)
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Bootstrap and initialize plugins
require("config.lazy")

