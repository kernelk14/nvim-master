-- AI-generated configuration (Antigravity). See README.md for the authorship disclosure.
-- Dashboard: Custom Start Screen (kernelk14/nvim-dashboard)
-- A dependency-free welcome screen with a responsive card layout, gradient
-- wordmark and live project information. The palette is derived from the
-- active colorscheme, so it always matches the rest of the configuration.

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------

-- Resolve <leader> at runtime so the cheat sheet stays accurate
local function expand_leader(keys)
  local leader = vim.g.mapleader or " "
  return (keys:gsub("<[lL]eader>", function()
    return leader
  end))
end

-- The most recent real file buffer (the dashboard buffer is never listed)
local function file_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buflisted
      and vim.bo[buf].filetype ~= "neodash"
      and vim.api.nvim_buf_get_name(buf) ~= ""
    then
      return buf
    end
  end
  return nil
end

-- Leave the dashboard, restore the last real file buffer, then run `fn`
local function leave(fn)
  local target = file_buffer()
  require("neodash").close()
  local current = vim.api.nvim_get_current_buf()
  if target and vim.api.nvim_buf_is_valid(target) then
    vim.api.nvim_set_current_buf(target)
    if
      current ~= target
      and vim.api.nvim_buf_get_name(current) == ""
      and not vim.bo[current].modified
    then
      pcall(vim.api.nvim_buf_delete, current, { force = true })
    end
  end
  fn()
end

-- Send a key sequence to Neovim exactly as if the user had typed it
local function feed(keys)
  local termcodes = vim.api.nvim_replace_termcodes(expand_leader(keys), true, false, true)
  leave(function()
    vim.schedule(function()
      vim.api.nvim_feedkeys(termcodes, "x", false)
    end)
  end)
end

-- Human readable platform name
local function platform()
  local uname = (vim.uv or vim.loop).os_uname()
  local name = uname.sysname or "unknown"
  if name == "Darwin" then
    name = "macOS"
  else
    name = name:gsub("_.*", "")
  end
  return name .. " " .. (uname.machine or "")
end

-- Number of installed plugins
local function plugin_count()
  local dir = vim.fn.stdpath("data") .. "/lazy"
  if vim.fn.isdirectory(dir) == 0 then
    return 0
  end
  local count = 0
  for _, name in ipairs(vim.fn.readdir(dir)) do
    if vim.fn.isdirectory(dir .. "/" .. name) == 1 then
      count = count + 1
    end
  end
  return count
end

-- ----------------------------------------------------------------------------
-- Actions
-- ----------------------------------------------------------------------------

local function live_grep()
  if vim.fn.executable("rg") == 0 then
    vim.notify(
      "Ripgrep ('rg') is not installed or not in PATH.\n"
        .. "Live grep requires ripgrep.\n"
        .. "Install via:\n"
        .. "  - Windows: winget install BurntSushi.ripgrep.MSVC\n"
        .. "  - macOS:   brew install ripgrep\n"
        .. "  - Linux:   sudo apt install ripgrep (or dnf/pacman)",
      vim.log.levels.WARN,
      { title = "Ripgrep Missing" }
    )
    return
  end
  require("telescope.builtin").live_grep()
end

local function code_action()
  local buf = file_buffer()
  leave(function()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.lsp.buf.code_action()
    end
  end)
end

local function toggle_theme()
  vim.o.background = vim.o.background == "light" and "dark" or "light"
  vim.cmd.colorscheme("tokyonight")
end

-- Open the workbench, the dashboard is left behind and the layout takes over.
-- The workbench is a lazy plugin, the keys are fed so lazy.nvim can load it
-- and run the mapping, the same way the shortcut sheet does it.
local function workbench()
  feed("<leader>W")
end

-- True when a language server is attached to the current file
local function lsp_available()
  local buf = file_buffer()
  if not buf then
    return false
  end
  local ok, clients = pcall(vim.lsp.get_clients, { bufnr = buf })
  return ok and #clients > 0
end

-- True when gitsigns is tracking the current file
local function gitsigns_available()
  local buf = file_buffer()
  if not buf then
    return false
  end
  return vim.b[buf].gitsigns_status ~= nil
end

-- The configuration's own keybindings, shown as a live cheat sheet
local shortcuts = {
  { icon = "󰈞", label = "Find files", keys = "<leader>ff" },
  { icon = "󰍉", label = "Live grep", keys = "<leader>fg" },
  { icon = "󰒓", label = "Find config", keys = "<leader>fc" },
  { icon = "󰌣", label = "Code actions", keys = "<leader>ca", enabled = lsp_available },
  { icon = "󰋢", label = "Rename symbol", keys = "<leader>cr", enabled = lsp_available },
  { icon = "󰊢", label = "Stage hunk", keys = "<leader>hs", enabled = gitsigns_available },
  { icon = "󰉋", label = "Workbench", keys = "<leader>W" },
}

return {
  {
    "kernelk14/nvim-dashboard",
    name = "nvim-dashboard",
    main = "neodash",
    lazy = false, -- must be configured before VimEnter so the screen auto-opens
    priority = 900, -- load after the colorscheme so the derived palette matches
    keys = {
      { "<leader>d", "<cmd>Neodash<CR>", desc = "Dashboard" },
    },
    opts = {
      -- The workbench is the start screen, the dashboard is opened with
      -- <leader>d or from the menu of the workbench.
      auto_open = false,
      theme = "auto", -- derive the palette from the active colorscheme
      transparent = false,
      max_width = 110,
      padding = 2,
      gap = 3,
      two_column = true,
      picker = "auto", -- use telescope.nvim when it is installed
      header = {
        style = "auto",
        tagline = "minimal · performant · cross-platform",
        gradient = true,
      },
      footer = {
        enabled = true,
        show_date = true,
        show_time = true,
        show_version = true,
        show_hint = true,
        live = true,
        update_interval = 15000,
      },
      menu = {
        title = "Actions",
        icon = "󰘳",
        items = {
          { icon = "󰈞", label = "Find file", key = "f", action = "find_files" },
          { icon = "󰝒", label = "New file", key = "n", action = "new_file" },
          { icon = "󰋚", label = "Recent files", key = "r", action = "recent_files" },
          { icon = "󰍉", label = "Live grep", key = "g", action = live_grep },
          { icon = "󰉋", label = "Workbench", key = "w", action = workbench },
          {
            icon = "󰌣",
            label = "Code actions",
            key = "a",
            action = code_action,
            enabled = lsp_available,
          },
          { icon = "󰒓", label = "Open config", key = "c", action = "edit_config" },
          { icon = "󰒲", label = "Plugins", key = "p", action = "lazy" },
          { icon = "󰳈", label = "Toggle theme", key = "t", action = toggle_theme },
          { icon = "󰅚", label = "Quit Neovim", key = "Q", action = "quit" },
        },
      },
      recent = {
        title = "Recent",
        icon = "󰋚",
        limit = 5,
        show_time = true,
        show_parent = true,
      },
      project = {
        title = "Project",
        icon = "󰉋",
        show_path = true,
      },
      sections = {
        left = { "menu", "shortcuts" },
        right = { "project", "recent", "environment" },
        bottom = {},
        custom = {},
      },
    },
    config = function(_, opts)
      local neodash = require("neodash")
      local util = require("neodash.util")

      -- Live cheat sheet of the configuration's own keybindings
      neodash.register_section("shortcuts", {
        title = "Shortcuts",
        icon = "󰄲",
        render = function(ctx)
          local lines = {}
          for _, entry in ipairs(shortcuts) do
            local item = entry -- capture per iteration (LuaJIT shares the loop variable)
            if item.enabled == nil or item.enabled() then
              local left = {
                { text = item.icon, hl = "NeodashIcon" },
                { text = "  " },
                { text = item.label, hl = "NeodashText" },
              }
              local right = { { text = " " .. item.keys .. " ", hl = "NeodashKey" } }
              lines[#lines + 1] = {
                segs = util.row(left, right, ctx.inner),
                action = function()
                  feed(item.keys)
                end,
              }
            end
          end
          return { title = "Shortcuts", icon = "󰄲", lines = lines }
        end,
      })

      -- Static information about the running editor
      neodash.register_section("environment", {
        title = "Environment",
        icon = "󰒲",
        render = function(ctx)
          local rows = {
            { "Platform", platform() },
            { "Plugins", tostring(plugin_count()) },
            { "ripgrep", vim.fn.executable("rg") == 1 and "installed" or "not found" },
            { "Git", vim.fn.executable("git") == 1 and "installed" or "not found" },
            { "Config", vim.fn.fnamemodify(vim.fn.stdpath("config"), ":~") },
          }
          local lines = {}
          for _, row in ipairs(rows) do
            lines[#lines + 1] = {
              segs = util.clip_segs({
                { text = string.format("%-9s", row[1]), hl = "NeodashMuted" },
                { text = "  " },
                { text = row[2], hl = "NeodashText" },
              }, ctx.inner),
            }
          end
          return { title = "Environment", icon = "󰒲", lines = lines }
        end,
      })

      neodash.setup(opts)
    end,
  },
}
