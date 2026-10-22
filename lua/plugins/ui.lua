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
        { "<leader>W", group = "Workbench" },
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
}
