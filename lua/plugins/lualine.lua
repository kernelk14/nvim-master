-- Lualine: A statusline with a look of its own.
-- The colours come from the colorscheme that is active, so the line keeps
-- matching the editor when the colorscheme is changed.
--
-- The line reads like this:
--
--   NORMAL │ 󰊢 main ⎇ 2 +1 -0 │   src/lua/config.lua ● │  󰅚 3 󰄡 1 │   LUA │  12:4  100% │  󰇭 14:32
--
-- The mode is a solid block, the branch and the changes of the repository sit
-- next to it, the file is in the middle and the diagnostics, the place in the
-- file and the clock are on the right.

local M = {}

--- The colour of a highlight group, with a fallback.
---@param attr string "fg" or "bg"
---@param list string[] The groups to look at, the first one that has a colour wins.
---@param fallback string
---@return string
local function color(attr, list, fallback)
  local ok, utils = pcall(require, "lualine.utils.utils")
  if ok and utils.extract_color_from_hllist then
    local extracted = utils.extract_color_from_hllist(attr, list, fallback)
    if extracted then
      return extracted
    end
  end
  return fallback
end

--- Build the theme from the colorscheme that is active.
---@return table
local function theme()
  local bg = color("bg", { "Normal", "StatusLine" }, "#1a1b26")
  local fg = color("fg", { "Normal", "StatusLine" }, "#c0caf5")
  local dim = color("fg", { "Comment", "NonText" }, "#565f89")

  local mode_normal = color("fg", { "DiagnosticOk", "String" }, "#9ece6a")
  local mode_insert = color("fg", { "DiagnosticInfo", "Function" }, "#7aa2f7")
  local mode_visual = color("fg", { "DiagnosticHint", "Special" }, "#bb9af7")
  local mode_replace = color("fg", { "DiagnosticError", "Number" }, "#f7768e")
  local mode_command = color("fg", { "DiagnosticWarn", "Identifier" }, "#e0af68")

  local git_added = color("fg", { "DiffAdd", "DiagnosticOk" }, "#9ece6a")
  local git_modified = color("fg", { "DiffChange", "DiagnosticWarn" }, "#e0af68")
  local git_removed = color("fg", { "DiffDelete", "DiagnosticError" }, "#f7768e")

  --- The mode is a block of its own colour.
  ---@param accent string
  ---@return table
  local function mode_theme(accent)
    return {
      a = { bg = accent, fg = bg, gui = "bold" },
      b = { bg = bg, fg = fg },
      c = { bg = bg, fg = fg },
    }
  end

  return {
    normal = mode_theme(mode_normal),
    insert = mode_theme(mode_insert),
    visual = mode_theme(mode_visual),
    replace = mode_theme(mode_replace),
    command = mode_theme(mode_command),
    inactive = {
      a = { bg = dim, fg = bg, gui = "bold" },
      b = { bg = bg, fg = dim },
      c = { bg = bg, fg = dim },
    },
    git = {
      added = { fg = git_added },
      modified = { fg = git_modified },
      removed = { fg = git_removed },
    },
    diagnostics = {
      error = { fg = color("fg", { "DiagnosticError" }, "#f7768e") },
      warn = { fg = color("fg", { "DiagnosticWarn" }, "#e0af68") },
      info = { fg = dim },
      hint = { fg = dim },
    },
  }
end

--- The file with the directory in a dim colour and the name in bold.
---@return table
local function file_component()
  return {
    function()
      local path = vim.fn.expand("%:p")
      if path == "" then
        return ""
      end

      local dir, name = path:match("^(.*[/\\])([^/\\]*)$")
      if not dir then
        dir, name = "", path
      end

      local home = (vim.uv or vim.loop).os_homedir()
      if home and home ~= "" and dir:sub(1, #home) == home then
        dir = "~" .. dir:sub(#home + 1)
      end

      local parts = {}
      if dir ~= "" then
        parts[#parts + 1] = { dir, "Comment" }
      end
      parts[#parts + 1] = { name, vim.bo.modified and "Bold" or "Normal" }
      if vim.bo.modified then
        parts[#parts + 1] = { " ●", "DiagnosticWarn" }
      end
      return parts
    end,
  }
end

--- The errors and the warnings, the ones that are not there are not shown.
---@return table
local function diagnostics_component()
  return {
    function()
      local errors = #vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR })
      local warnings = #vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.WARN })

      local parts = {}
      if errors > 0 then
        parts[#parts + 1] = { " 󰅚 " .. errors, "DiagnosticError" }
      end
      if warnings > 0 then
        parts[#parts + 1] = { "󰄡 " .. warnings, "DiagnosticWarn" }
      end
      return parts
    end,
  }
end

--- The kind of the file with the icon of it.
---@return table
local function filetype_component()
  return {
    function()
      local filetype = vim.bo.filetype
      if filetype == "" then
        return ""
      end

      local icon = ""
      local ok, devicons = pcall(require, "nvim-web-devicons")
      if ok then
        icon = devicons.get_icon_by_filetype(filetype, { default = false }) or ""
        if icon ~= "" then
          icon = icon .. " "
        end
      end

      return { { icon .. filetype:upper(), "Type" } }
    end,
  }
end

--- The place in the file and how much of it is shown.
---@return table
local function position_component()
  return {
    function()
      local parts = {}
      parts[#parts + 1] = { string.format("%d:%d", vim.fn.line("."), vim.fn.col(".")), "Number" }

      local percent = 0
      local total = vim.fn.line("$")
      if total > 0 then
        percent = math.floor(vim.fn.line(".") / total * 100)
      end
      parts[#parts + 1] = { string.format(" %d%%", percent), "Comment" }
      return parts
    end,
  }
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      return {
        theme = theme(),
        options = {
          globalstatus = true, -- a single line across all the splits
          separator_style = "rounded",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = {
            statusline = { "help", "alpha", "dashboard", "neodash" },
          },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            {
              "branch",
              icon = "󰊢 ",
            },
            {
              "diff",
              symbols = { added = " +", modified = " ~", removed = " -" },
            },
          },
          lualine_c = { file_component() },
          lualine_x = {
            diagnostics_component(),
            filetype_component(),
            position_component(),
          },
          lualine_y = {
            {
              "lsp_status",
              symbols = {
                spinner = { "󰇘", "󰇙", "󰇚", "󰇛", "󰇜", "󰇝", "󰇞", "󰇟" },
                done = "󰄬",
                separator = " ",
              },
              show_name = false,
            },
            {
              "datetime",
              style = "󰇭 %H:%M",
              color = { fg = color("fg", { "Comment", "NonText" }, "#565f89") },
            },
          },
        },
      }
    end,
  },
}
