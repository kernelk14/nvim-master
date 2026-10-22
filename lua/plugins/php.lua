-- AI-generated configuration (Antigravity). See README.md for the authorship disclosure.
-- PHP & Web Development Tooling
-- Integrates PhpActor for context actions, class generation, and refactoring

return {
  {
    "gbprod/phpactor.nvim",
    ft = { "php" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    keys = {
      { "<leader>pm", "<cmd>PhpActor context_menu<cr>", desc = "PHP Context Menu" },
      { "<leader>pn", "<cmd>PhpActor class_new<cr>", desc = "PHP New Class" },
      { "<leader>pt", "<cmd>PhpActor transform<cr>", desc = "PHP Transform / Refactor" },
      { "<leader>pi", "<cmd>PhpActor import_class<cr>", desc = "PHP Import Class" },
      { "<leader>pv", "<cmd>PhpActor class_move<cr>", desc = "PHP Move Class" },
    },
    opts = {
      install = {
        check_on_startup = "none",
        -- Never ask about installing the server. The binary comes from
        -- Mason, it is installed in the background when it is missing.
        confirm = false,
        bin = vim.fn.stdpath("data") .. "/mason/bin/phpactor.cmd",
      },
      lspconfig = {
        enabled = false, -- Intelephense is our primary LSP; PhpActor provides refactoring & actions
      },
    },
  },
}
