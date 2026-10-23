-- Workbench: Declarative IDE Layout (kernelk14/nvim-workbench)
-- A dependency free workbench that turns a layout tree into real windows.
-- The palette is derived from the active colorscheme, so it matches the rest
-- of the configuration.
--
-- The workbench opens when the editor is up, so the plugin is loaded when the
-- VimEnter event fires. That keeps the startup of the editor fast, the layout
-- appears right after the first frame.
--
-- The keymaps are declared here so lazy.nvim can load the plugin on demand.

return {
  {
    "kernelk14/nvim-workbench",
    name = "nvim-workbench",
    -- The repository is called nvim-workbench, the module inside is called
    -- neoworkbench, lazy.nvim needs to be told.
    main = "neoworkbench",
    -- The workbench opens on startup, the plugin is loaded when the editor is
    -- up so the startup of the editor itself stays fast.
    event = "VimEnter",
    priority = 900, -- load after the colorscheme so the derived palette matches
    -- Oil serves the explorer pane, it has to be loaded and configured before
    -- the workbench hands the pane over to it.
    dependencies = { "oil.nvim" },
    keys = {
      { "<leader>W", "<cmd>WorkbenchToggle<CR>", desc = "Workbench" },
      {
        "<leader>Wh",
        function()
          require("neoworkbench").move("left")
        end,
        desc = "Workbench focus left",
      },
      {
        "<leader>Wj",
        function()
          require("neoworkbench").move("down")
        end,
        desc = "Workbench focus down",
      },
      {
        "<leader>Wk",
        function()
          require("neoworkbench").move("up")
        end,
        desc = "Workbench focus up",
      },
      {
        "<leader>Wl",
        function()
          require("neoworkbench").move("right")
        end,
        desc = "Workbench focus right",
      },
      { "<leader>Wi", "<cmd>WorkbenchFocus explorer<CR>", desc = "Workbench explorer" },
      { "<leader>Wp", "<cmd>WorkbenchPanel<CR>", desc = "Workbench panel" },
      { "<leader>Wt", "<cmd>WorkbenchPanel terminal<CR>", desc = "Workbench terminal" },
      { "<leader>Wx", "<cmd>WorkbenchPanel problems<CR>", desc = "Workbench problems" },
      { "<leader>Wo", "<cmd>WorkbenchPanel output<CR>", desc = "Workbench output" },
      { "<leader>Wq", "<cmd>WorkbenchPanel quickfix<CR>", desc = "Workbench quickfix" },
      { "<leader>WL", "<cmd>WorkbenchLayout<CR>", desc = "Workbench layout" },
      { "<leader>Ws", "<cmd>WorkbenchSave<CR>", desc = "Workbench save session" },
      { "<leader>Wc", "<cmd>WorkbenchClose<CR>", desc = "Workbench close" },
    },
    opts = {
      layout = "default",
      -- Open the workbench when the editor is up. A file on the command line
      -- still wins, the workbench does not get in the way of opening it.
      auto_open = true,
      title = true,
      panel = "problems",
      panels = { "problems", "quickfix", "output", "terminal" },
      -- Which implementation serves a pane. "auto" prefers an installed
      -- plugin and falls back to the built in one, the explorer understands
      -- "oil", "neo-tree" and "builtin".
      providers = {
        -- The built in file tree, it works everywhere. Change this to "oil"
        -- to let oil.nvim serve the pane instead.
        explorer = "builtin",
      },
      session = {
        enabled = true,
        autosave = true,
        restore = true,
      },
      -- The keymaps are declared above, lazy.nvim needs them to load the
      -- plugin on the first press.
      keys = false,
    },
    config = function(plugin, opts)
      require("neoworkbench").setup(opts)

      -- A lone dot on the command line opens the file picker instead of the
      -- workbench. The workbench would have nothing to show.
      if vim.fn.argc() == 1 and vim.fn.argv(0) == "." then
        vim.schedule(function()
          local ok, telescope = pcall(require, "telescope.builtin")
          if ok then
            telescope.find_files()
          else
            -- Fall back to the built in picker.
            vim.cmd("edit .")
          end
        end)
      end
    end,
  },
}
