-- Lualine: a statusline with a look of its own.
--
-- The line is a row of pills. Every group of things sits on a surface that is
-- a shade lighter than the editor, the gaps between them are the editor
-- itself. The mode is a solid block of its own colour on the left, the file
-- with a bar that shows where in it you are in the middle, and the clock on the
-- right.
--
--   NORMAL   main   src/lua/config.lua   3  1   LUA   12:4  ▰▰▰▱▱▱▱▱▱▱  40%   14:32
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

  -- The pills sit a little above the editor.
  local surface = blend(bg, fg, 0.07)
  local surface_raised = blend(bg, fg, 0.12)

  local mode_normal = color("fg", { "DiagnosticOk", "String" }, "#9ece6a")
  local mode_insert = color("fg", { "DiagnosticInfo", "Function" }, "#7aa2f7")
  local mode_visual = color("fg", { "DiagnosticHint", "Special" }, "#bb9af7")
  local mode_replace = color("fg", { "DiagnosticError", "Number" }, "#f7768e")
  local mode_command = color("fg", { "DiagnosticWarn", "Identifier" }, "#e0af68")

  --- The mode is a block of its own colour.
  ---@param accent string
  ---@return table
  local function mode_theme(accent)
    return {
      a = { bg = accent, fg = bg, gui = "bold" },
      b = { bg = surface, fg = fg },
      c = { bg = surface, fg = fg },
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
      b = { bg = surface, fg = dim },
      c = { bg = surface, fg = dim },
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
  }
end

--- The groups the pieces of the pills are drawn with.
--- They are defined here so a piece of text keeps the background of its pill.
---@param surface string
---@return table
local function groups(surface)
  local dim = color("fg", { "Comment", "NonText" }, "#565f89")
  local fg = color("fg", { "Normal", "StatusLine" }, "#c0caf5")
  local accent = color("fg", { "DiagnosticInfo", "Function" }, "#7dcfff")
  local number = color("fg", { "Number", "Constant" }, "#bb9af7")
  local warn = color("fg", { "DiagnosticWarn" }, "#e0af68")

  local set = {
    NeoworkbenchDim = { fg = dim, bg = surface },
    NeoworkbenchName = { fg = fg, bg = surface, bold = true },
    NeoworkbenchModified = { fg = warn, bg = surface },
    NeoworkbenchAccent = { fg = accent, bg = surface },
    NeoworkbenchNumber = { fg = number, bg = surface },
  }

  for name, spec in pairs(set) do
    pcall(vim.api.nvim_set_hl, 0, name, spec)
  end

  return set
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
    parts[#parts + 1] = "%#NeoworkbenchName#" .. name .. "%*"
    if vim.bo.modified then
      parts[#parts + 1] = "%#NeoworkbenchModified# ●%*"
    end
    return table.concat(parts)
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
    local width = 10
    local filled = math.floor(ratio * width + 0.5)

    return string.format(
      "%%#NeoworkbenchNumber#%d:%d%%*  %%#NeoworkbenchAccent#%s%%*%%#NeoworkbenchDim#%s%%*",
      current,
      vim.fn.col("."),
      string.rep("▰", filled),
      string.rep("▱", width - filled)
    )
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

    return icon .. filetype:upper()
  end
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local colors = theme()
      local bg = color("bg", { "Normal", "StatusLine" }, "#1a1b26")
      local fg = color("fg", { "Normal", "StatusLine" }, "#c0caf5")
      local surface = blend(bg, fg, 0.07)
      groups(surface)

      return {
        theme = colors,
        options = {
          globalstatus = true, -- a single line across all the splits
          separator_style = "rounded",
          -- A space between the pills of a section, the editor between the
          -- sections.
          component_separators = { left = "", right = " " },
          section_separators = { left = " ", right = " " },
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
              icon = "󰊢",
              color = { fg = color("fg", { "Directory", "Identifier" }, "#7aa2f7"), bg = surface },
            },
            {
              "diff",
              symbols = { added = " +", modified = " ~", removed = " -" },
              color = { bg = surface },
            },
          },
          lualine_c = {
            {
              file_component(),
              color = { bg = surface },
            },
          },
          lualine_x = {
            {
              "diagnostics",
              symbols = { error = "󰅚 ", warn = "󰄡 ", info = "󰋽 ", hint = "󰌵 " },
              colored = true,
              color = { bg = surface },
            },
            {
              filetype_component(),
              color = { fg = color("fg", { "Type", "Special" }, "#7dcfff"), bg = surface },
            },
            {
              position_component(),
              color = { bg = surface },
            },
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
              color = { bg = surface },
            },
            {
              "datetime",
              style = "󰇭 %H:%M",
              color = { fg = color("fg", { "Comment", "NonText" }, "#565f89"), bg = surface },
            },
          },
          -- The place in the file is in the right section already, the one of
          -- the defaults would show it twice.
          lualine_z = {},
        },
      }
    end,
  },
}
