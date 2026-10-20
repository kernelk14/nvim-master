-- Telescope Fuzzy Finder
-- Fast and extensible finder for files, text, buffers, and git status
-- Gracefully handles absence of ripgrep or C compilers

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader><space>", "<cmd>Telescope find_files<CR>", desc = "Find Files (root dir)" },
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Active Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help Documentation" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Search Diagnostics" },
      {
        "<leader>fc",
        function()
          require("telescope.builtin").find_files({
            cwd = vim.fn.stdpath("config"),
          })
        end,
        desc = "Find Neovim Config Files",
      },
      {
        "<leader>fg",
        function()
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
        end,
        desc = "Live Grep (text search)",
      },
    },
    opts = {
      defaults = {
        prompt_prefix = "   ",
        selection_caret = "  ",
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
          },
          vertical = {
            mirror = false,
          },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
        file_ignore_patterns = {
          "node_modules",
          "%.git[/\\]",
          "%.cache",
          "target[/\\]",
          "build[/\\]",
          "%.lock",
        },
      },
      pickers = {
        find_files = {
          hidden = true,
          -- Avoid searching .git folder
          find_command = (function()
            if vim.fn.executable("fd") == 1 then
              return { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden", "--exclude", ".git" }
            elseif vim.fn.executable("fdfind") == 1 then
              return { "fdfind", "--type", "f", "--strip-cwd-prefix", "--hidden", "--exclude", ".git" }
            elseif vim.fn.executable("rg") == 1 then
              return { "rg", "--files", "--hidden", "--glob", "!.git/*" }
            end
            return nil
          end)(),
        },
      },
    },
  },
}
