-- File Explorer: oil.nvim (stevearc/oil.nvim)
-- The workbench hands its explorer pane over to oil, both of them render into
-- the window that is current when they are opened.
--
-- Oil is a dependency of the workbench, so it is always loaded and configured
-- by lazy.nvim before the pane needs it.

return {
  {
    "stevearc/oil.nvim",
    name = "oil.nvim",
    -- The repository is called oil.nvim, the module inside is called oil.
    main = "oil",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      -- The workbench provides the explorer pane, oil does not need to take
      -- over the file commands as well.
      default_file_explorer = false,
      view_options = {
        show_hidden = true,
        -- oil calls this with the name of the entry and the buffer it is
        -- rendered in.
        is_hidden_file = function(name)
          return name:match("^%.") ~= nil
        end,
        natural_order = true,
      },
    },
  },
}
