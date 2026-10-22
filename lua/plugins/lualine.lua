-- Lualine: a statusline with a look of its own.
--
-- The line is a single continuous strip. No pills, no boxes, no arrows. Each
-- section flows into the next through a thin diagonal separator, and the
-- background of each section shifts one shade darker as you move right, like
-- light passing through a prism.
--
--   ▲  main  ╱  init.lua ●  ╱  󰅚1 󰄡1  ╱  LUA  ╱  1:1  ╱  14:32  ╱
--
-- The mode is a single coloured triangle, the colour is the mode. The file
-- path uses dots instead of slashes. The position is a vertical bar that
-- grows from the bottom. The colours come from the colorscheme that is
-- active, so the line keeps matching the editor when the colorscheme is
-- changed.

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
  n = "▲",
  no = "▲",
  niI = "▲",
  niR = "▲",
  niV = "▲",
  nt = "▲",
  i = "▼",
  ic = "▼",
  ix = "▼",
  v = "◆",
  vs = "◆",
  V = "◆",
  Vs = "◆",
  s = "●",
  S = "●",
  R = "■",
  Rc = "■",
  c = "▸",
  cv = "▸",
  ce = "▸",
  r = "▲",
  rm = "▲",
  ["?"] = "▲",
}

--- The colour of each mode.
local function mode_color()
  local mode = vim.fn.mode()
  local short = mode:sub(1, 1)
  if short == "i" then
    return color("fg", { "DiagnosticInfo", "Function" }, "#7aa2f7")
  elseif short == "v" or short == "V" or short == "s" or short == "S" then
    return color("fg", { "DiagnosticHint", "Special" }, "#bb9af7")
  elseif short == "R" then
    return color("fg", { "DiagnosticError", "Number" }, "#f7768e")
  elseif short == "c" then
    return color("fg", { "DiagnosticWarn", "Identifier" }, "#e0af68")
  else
    return color("fg", { "DiagnosticOk", "String" }, "#9ece6a")
  end
end

--- Build the theme from the colorscheme that is active.
---@return table
local function theme()
  local bg = color("bg", { "Normal", "StatusLine" }, "#1a1b26")
  local fg = color("fg", { "Normal", "StatusLine" }, "#c0caf5")
  local dim = color("fg", { "Comment", "NonText" }, "#565f89")

  local normal = color("fg", { "DiagnosticOk", "String" }, "#9ece6a")
  local insert = color("fg", { "DiagnosticInfo", "Function" }, "#7aa2f7")
  local visual = color("fg", { "DiagnosticHint", "Special" }, "#bb9af7")
  local replace = color("fg", { "DiagnosticError", "Number" }, "#f7768e")
  local command = color("fg", { "DiagnosticWarn", "Identifier" }, "#e0af68")

  local surface = blend(bg, fg, 0.06)

  ---@param accent string
  local function mode_theme(accent)
    return {
      a = { fg = accent, gui = "bold" },
      b = { fg = fg },
      c = { fg = fg },
    }
  end

  return {
    normal = mode_theme(normal),
    insert = mode_theme(insert),
    visual = mode_theme(visual),
    replace = mode_theme(replace),
    command = mode_theme(command),
    inactive = {
      a = { fg = dim, gui = "bold" },
      b = { fg = dim },
      c = { fg = dim },
    },
    git = {
      added = { fg = color("fg", { "DiffAdd", "DiagnosticOk" }, "#9ece6a") },
      modified = { fg = color("fg", { "DiffChange", "DiagnosticWarn" }, "#e0af68") },
      removed = { fg = color("fg", { "DiffDelete", "DiagnosticError" }, "#f7768e") },
    },
    diagnostics = {
      error = { fg = color("fg", { "DiagnosticError" }, "#f7768e") },
      warn = { fg = color("fg", { "DiagnosticWarn" }, "#e0af68") },
      info = { fg = dim },
      hint = { fg = dim },
    },
  }
end

--- The groups the pieces are drawn with.
--- They are defined here so a piece of text keeps its colour.
---@param surface string
local function groups(surface)
  local fg = color("fg", { "Normal", "StatusLine" }, "#c0caf5")
  local dim = color("fg", { "Comment", "NonText" }, "#565f89")
  local accent = color("fg", { "DiagnosticInfo", "Function" }, "#7aa2f7")
  local number = color("fg", { "Number", "Constant" }, "#bb9af7")
  local warn = color("fg", { "DiagnosticWarn" }, "#e0af68")
  local error_color = color("fg", { "DiagnosticError" }, "#f7768e")
  local type_color = color("fg", { "Type", "Special" }, "#7dcfff")

  local set = {
    PrismMode = { fg = mode_color(), gui = "bold" },
    PrismBranch = { fg = color("fg", { "Directory", "Identifier" }, "#7aa2f7") },
    PrismFile = { fg = fg },
    PrismDir = { fg = dim },
    PrismModified = { fg = warn },
    PrismDiagError = { fg = error_color },
    PrismDiagWarn = { fg = warn_color },
    PrismType = { fg = type_color },
    PrismNumber = { fg = number },
    PrismDim = { fg = dim },
    PrismSep = { fg = dim },
    PrismBar = { fg = accent },
  }

  for name, spec in pairs(set) do
    pcall(vim.api.nvim_set_hl, 0, name, spec)
  end
end

--- The mode with the icon of it.
---@return table
local function mode_component()
  return {
    "mode",
    fmt = function(mode)
      local short = vim.fn.mode()
      local icon = mode_icons[short] or mode_icons[short:sub(1, 1)] or ""
      return icon .. "  "
    end,
    color = function()
      return { fg = mode_color(), gui = "bold" }
    end,
  }
end

--- The file with the directory in a dim colour and the name in bold.
---@return function
local function file_component()
  return function()
    local path = vim.fn.expand("%:p")
    if path == "" then
      return "%#PrismDim#[No Name]%*"
    end

    local dir, name = path:match("^(.*[/\\])([^/\\]*)$")
    if not dir then
      dir, name = "", path
    end

    local home = (vim.uv or vim.loop).os_homedir()
    if home and home ~= "" and dir:sub(1, #home) == home then
      dir = "~" .. dir:sub(#home + 1)
    end

    -- Dots instead of slashes, the way a namespace is written.
    dir = dir:gsub("[/\\]", "·")

    local parts = {}
    if dir ~= "" then
      parts[#parts + 1] = "%#PrismDir#" .. dir .. "%*"
    end
    parts[#parts + 1] = "%#PrismFile#" .. name .. "%*"
    if vim.bo.modified then
      parts[#parts + 1] = "%#PrismModified# ●%*"
    end
    return table.concat(parts)
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
      parts[#parts + 1] = "%#PrismDiagError#󰅚" .. errors .. "%*"
    end
    if warnings > 0 then
      parts[#parts + 1] = "%#PrismDiagWarn#󰄡" .. warnings .. "%*"
    end
    return table.concat(parts, " ")
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

    return "%#PrismType#" .. icon .. filetype:upper() .. "%*"
  end
end

--- The place in the file with a vertical bar that shows how far it is.
---@return function
local function position_component()
  return function()
    local total = vim.fn.line("$")
    if total <= 0 then
      return ""
    end

    local current = vim.fn.line(".")
    local ratio = current / total
    local height = 8
    local filled = math.floor(ratio * height + 0.5)

    return string.format(
      "%%#PrismNumber#%d:%d%%*  %%#PrismBar#%s%%*%%#PrismDim#%s%%*",
      current,
      vim.fn.col("."),
      string.rep("▎", filled),
      string.rep("▎", height - filled)
    )
  end
end

--- The diagonal separator.
local sep = "%#PrismSep# ╱ %*"

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
          component_separators = { left = "", right = "" },
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
              color = { fg = color("fg", { "Directory", "Identifier" }, "#7aa2f7") },
            },
            sep,
          },
          lualine_c = {
            file_component(),
            sep,
          },
          lualine_x = {
            diagnostics_component(),
            sep,
            filetype_component(),
            sep,
            position_component(),
          },
          lualine_y = {
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
