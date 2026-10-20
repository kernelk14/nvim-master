-- Lazy.nvim Bootstrap and Configuration
-- Provides fast, declarative, and reproducible plugin management

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Bootstrap lazy.nvim if not already present
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  if vim.fn.executable("git") == 0 then
    vim.notify(
      "Git is not installed or not in PATH.\n"
        .. "Plugin management requires Git. Core Neovim configuration loaded successfully.",
      vim.log.levels.WARN,
      { title = "Plugin Bootstrap Warning" }
    )
    return
  end

  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.notify(
      "Failed to clone lazy.nvim:\n" .. out .. "\nCore Neovim configuration remains functional.",
      vim.log.levels.ERROR,
      { title = "Bootstrap Failed" }
    )
    return
  end
end

vim.opt.rtp:prepend(lazypath)

-- Configure lazy.nvim
local ok, lazy = pcall(require, "lazy")
if not ok then
  vim.notify("Could not load lazy.nvim. Continuing without plugins.", vim.log.levels.WARN)
  return
end

lazy.setup({
  spec = {
    -- Import all plugin specifications from lua/plugins/
    { import = "plugins" },
  },
  defaults = {
    lazy = true, -- Lazy-load plugins by default for maximum startup speed
  },
  install = {
    colorscheme = { "tokyonight", "habamax" },
  },
  checker = {
    enabled = false, -- Avoid background network queries on editor startup
  },
  change_detection = {
    notify = false, -- Avoid noisy popups when editing plugin files
  },
  performance = {
    rtp = {
      -- Disable unneeded standard Vim plugins to reduce startup time
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "netrwPlugin",
      },
    },
  },
})
