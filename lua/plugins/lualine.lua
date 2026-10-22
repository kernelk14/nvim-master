-- Lualine: a statusline with a look of its own.
--
-- The line is calm. A thin bar on the left carries the colour of the mode,
-- everything else is text on the editor. Nothing is boxed, nothing is a pill.
-- The mode, the branch, the file, the diagnostics, the place in the file and
-- the clock are separated by a thin line.
--
--   ▎ NORMAL  │  󰊢 main  │  init.lua ●  │  󰅚 1  󰄡 1  │    │  1:1  40%  │  󰇭 14:32  ▰▰▰▱▱▱▱▱▱▱
--
-- The colours come from the colorscheme that is active, so the line keeps
-- matching the editor when the colorscheme is changed.

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

--- Mix two colours.
---@param from string
---@param to string
---@param ratio number
---@return string
local function blend(from, to, ratio)
  local function parts(hex)
    hex = hex:gsub("#", "")
    if #hex == 3 then
      hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
    end
    return tonumber(hex:sub(1, 2), 16) or 0, tonumber(hex:sub(3, 4), 16) or 0, tonumber(hex:sub(5, 6), 16) or 0
  end

  local r1, g1, b1 = parts(from)
  local r2, g2, b2 = parts(to)
  return string.format(
    "#%02x%02x%02x",
    math.floor(r1 + (r2 - r1) * ratio + 0.5),
    math.floor(g1 + (g2 - g1) * ratio + 0.5),
    math.floor(b1 + (b2 - b1) * ratio + 0.5)
  )
end

--- The icon of each mode.
local mode_icons = {
  n = "󰅊",
  no = "󰅊",
  niI = "󰅊",
  niR = "󰅊",
  niV = "󰅊",
  nt = "󰅊",
  i = "󰐒",
  ic = "󰐒",
  ix = "󰐒",
  v = "󰓩",
  vs = "󰓩",
  V = "󰓩",
  Vs = "󰓩",
  s = "󰅍",
  S = "󰅍",
  R = "󰅍",
  Rc = "󰅍",
  c = "󰘳",
  cv = "󰘳",
  ce = "󰘳",
  r = "󰗼",
  rm = "󰗼",
  ["?"] = "󰅊",
}

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

  local git_branch = color("fg", { "Directory", "Identifier" }, "#7aa2f7")
  local git_added = color("fg", { "DiffAdd", "DiagnosticOk" }, "#9ece6a")
  local git_modified = color("fg", { "DiffChange", "DiagnosticWarn" }, "#e0af68")
  local git_removed = color("fg", { "DiffDelete", "DiagnosticError" }, "#f7768e")

  local error_color = color("fg", { "DiagnosticError" }, "#f7768e")
  local warn_color = color("fg", { "DiagnosticWarn" }, "#e0af68")
  local type_color = color("fg", { "Type", "Special" }, "#7dcfff")
  local number_color = color("fg", { "Number", "Constant" }, "#bb9af7")

  --- The mode is a block of its own colour.
  ---@param accent string
  ---@return table
  local function mode_theme(accent)
    return {
      a = { fg = accent, gui = "bold" },
      b = { fg = fg },
      c = { fg = fg },
    }
  end

  return {
    normal = mode_theme(mode_normal),
    insert = mode_theme(mode_insert),
    visual = mode_theme(mode_visual),
    replace = mode_theme(mode_replace),
    command = mode_theme(mode_command),
    inactive = {
      a = { fg = dim, gui = "bold" },
      b = { fg = dim },
      c = { fg = dim },
    },
    git = {
      added = { fg = git_added },
      modified = { fg = git_modified },
      removed = { fg = git_removed },
    },
    diagnostics = {
      error = { fg = error_color },
      warn = { fg = warn_color },
      info = { fg = dim },
      hint = { fg = dim },
    },
    branch = { fg = git_branch },
    type = { fg = type_color },
    number = { fg = number_color },
  }
end

--- The groups the pieces are drawn with.
--- They are defined here so a piece of text keeps its colour.
---@param colors table
local function groups(colors)
  local set = {
    NeoworkbenchMode = { fg = colors.normal.a.fg, gui = "bold" },
    NeoworkbenchBranch = { fg = colors.branch.fg },
    NeoworkbenchFile = { fg = color("fg", { "Normal", "StatusLine" }, "#c0caf5") },
    NeoworkbenchModified = { fg = color("fg", { "DiagnosticWarn" }, "#e0af68") },
    NeoworkbenchAccent = { fg = colors.type.fg },
    NeoworkbenchNumber = { fg = colors.number.fg },
    NeoworkbenchDim = { fg = color("fg", { "Comment", "NonText" }, "#565f89") },
    NeoworkbenchDiagError = { fg = colors.diagnostics.error.fg },
    NeoworkbenchDiagWarn = { fg = colors.diagnostics.warn.fg },
    NeoworkbenchBar = { fg = colors.number.fg },
  }

  for name, spec in pairs(set) do
    pcall(vim.api.nvim_set_hl, 0, name, spec)
  end

  return set
end

--- The mode with the icon of it.
---@return table
local function mode_component()
  return {
    "mode",
    fmt = function(mode)
      local short = vim.fn.mode()
      local icon = mode_icons[short] or mode_icons[short:sub(1, 1)] or ""
      return " " .. icon .. " " .. mode:upper() .. " "
    end,
    color = function()
      local mode = vim.fn.mode()
      local accent
      if mode == "i" or mode == "ic" or mode == "ix" then
        accent = color("fg", { "DiagnosticInfo", "Function" }, "#7aa2f7")
      elseif mode == "v" or mode == "V" or mode == "Vs" or mode == "s" or mode == "S" then
        accent = color("fg", { "DiagnosticHint", "Special" }, "#bb9af7")
      elseif mode == "R" or mode == "Rc" then
        accent = color("fg", { "DiagnosticError", "Number" }, "#f7768e")
      elseif mode == "c" or mode == "cv" or mode == "ce" then
        accent = color("fg", { "DiagnosticWarn", "Identifier" }, "#e0af68")
      else
        accent = color("fg", { "DiagnosticOk", "String" }, "#9ece6a")
      end
      return { fg = accent, gui = "bold" }
    end,
  }
end

--- The file with the directory in a dim colour and the name in bold.
---@return function
local function file_component()
  return function()
    local path = vim.fn.expand("%:p")
    if path == "" then
      return "%#NeoworkbenchDim#[No Name]%*"
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
      parts[#parts + 1] = "%#NeoworkbenchDim#" .. dir .. "%*"
    end
    parts[#parts + 1] = "%#NeoworkbenchFile#" .. name .. "%*"
    if vim.bo.modified then
      parts[#parts + 1] = "%#NeoworkbenchModified# ●%*"
    end
    return table.concat(parts)
  end
end

--- The kind of the file with the icon of it.
---@return function
local function filetype_component()
  return function()
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

    return "%#NeoworkbenchAccent#" .. icon .. filetype:upper() .. "%*"
  end
end

--- The place in the file with a bar that shows how far it is.
---@return function
local function position_component()
  return function()
    local total = vim.fn.line("$")
    if total <= 0 then
      return ""
    end

    local current = vim.fn.line(".")
    local ratio = current / total
    local width = 8
    local filled = math.floor(ratio * width + 0.5)

    return string.format(
      "%%#NeoworkbenchNumber#%d:%d%%*  %%#NeoworkbenchBar#%s%s%%*",
      current,
      vim.fn.col("."),
      string.rep("▰", filled),
      string.rep("▱", width - filled)
    )
  end
end

--- The errors and the warnings, the ones that are not there are not shown.
---@return function
local function diagnostics_component()
  return function()
    local errors = #vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR })
    local warnings = #vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.WARN })

    local parts = {}
    if errors > 0 then
      parts[#parts + 1] = "%#NeoworkbenchDiagError#󰅚 " .. errors .. "%*"
    end
    if warnings > 0 then
      parts[#parts + 1] = "%#NeoworkbenchDiagWarn#󰄡 " .. warnings .. "%*"
    end
    return table.concat(parts, " ")
  end
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local colors = theme()
      groups(colors)

      return {
        theme = colors,
        options = {
          globalstatus = true,
          separator_style = "rounded",
          component_separators = { left = " │ ", right = " │ " },
          section_separators = { left = "", right = "" },
          disabled_filetypes = {
            statusline = { "help", "alpha", "dashboard", "neodash" },
          },
        },
        sections = {
          lualine_a = {
            mode_component(),
          },
          lualine_b = {
            {
              "branch",
              icon = "󰊢 ",
              color = { fg = color("fg", { "Directory", "Identifier" }, "#7aa2f7") },
            },
            {
              "diff",
              symbols = { added = " +", modified = " ~", removed = " -" },
            },
          },
          lualine_c = {
            file_component(),
          },
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
          lualine_z = {},
        },
      }
    end,
  },
}
