-- AI-generated configuration (Antigravity). See README.md for the authorship disclosure.
-- UI Enhancements: Discoverable Keymaps & Statusline
-- Lightweight components that provide high visual feedback with minimal overhead

return {
  -- Which-Key: Interactive keymap discovery
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      spec = {
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code / LSP" },
        { "<leader>d", group = "Dashboard" },
        { "<leader>f", group = "Find / Telescope" },
        { "<leader>F", group = "Flutter" },
        { "<leader>g", group = "Git" },
        { "<leader>p", group = "PHP / CodeIgniter" },
        { "<leader>w", group = "Window / Splits" },
        { "<leader>x", group = "Diagnostics / Quickfix" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer local keymaps (which-key)",
      },
    },
  },

  -- Icons (optional, degrades cleanly if terminal font lacks glyphs)
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = {
      default = true,
    },
  },

  -- Lualine: Clean, fast statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
        globalstatus = true, -- Single statusline across all splits
        component_separators = { left = "|", right = "|" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {
          statusline = { "help", "alpha", "dashboard", "neodash" },
        },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
}
