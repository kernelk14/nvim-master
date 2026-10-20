-- AI-generated configuration (Antigravity). See README.md for the authorship disclosure.
-- Bufferline: Tabs / Buffer management across the top of the editor
-- Seamless integration with nvim-web-devicons, LSP diagnostics, and Tokyo Night

return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Toggle Pin" },
      { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Delete Other Buffers" },
      { "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Delete Buffers to Right" },
      { "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Delete Buffers to Left" },
    },
    opts = {
      options = {
        mode = "buffers",
        separator_style = "thin", -- "thin" | "slant" | "slope" | "thick"
        always_show_bufferline = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(count, level)
          local icon = level:match("error") and " " or (level:match("warning") and " " or "ℹ ")
          return " " .. icon .. count
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            highlight = "Directory",
            text_align = "left",
          },
        },
      },
    },
  },
}
