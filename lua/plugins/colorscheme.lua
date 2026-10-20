-- Colorscheme Configuration
-- Tokyo Night: Clean, modern dark theme with deep darks and vibrant accents

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,    -- Must load during startup to prevent color flickering
    priority = 1000, -- Load before all other plugins
    opts = {
      style = "night", -- Choices: "storm", "moon", "night", or "day"
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        sidebars = "dark",
        floats = "dark",
      },
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}
