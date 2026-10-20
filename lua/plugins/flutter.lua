-- AI-generated configuration (Antigravity). See README.md for the authorship disclosure.
-- Flutter & Dart Development
-- Powered by flutter-tools.nvim: hot reload/restart, widget closing tags, device management

return {
  {
    "akinsho/flutter-tools.nvim",
    ft = { "dart" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    keys = {
      { "<leader>Fs", "<cmd>FlutterRun<cr>", desc = "Flutter Run" },
      { "<leader>Fr", "<cmd>FlutterReload<cr>", desc = "Flutter Hot Reload" },
      { "<leader>FR", "<cmd>FlutterRestart<cr>", desc = "Flutter Hot Restart" },
      { "<leader>Fq", "<cmd>FlutterQuit<cr>", desc = "Flutter Quit" },
      { "<leader>Fd", "<cmd>FlutterDevices<cr>", desc = "Flutter Devices" },
      { "<leader>Fe", "<cmd>FlutterEmulators<cr>", desc = "Flutter Emulators" },
      { "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", desc = "Flutter Outline Toggle" },
      { "<leader>FD", "<cmd>FlutterDevTools<cr>", desc = "Flutter DevTools" },
      { "<leader>Fp", "<cmd>FlutterCopyProfilerUrl<cr>", desc = "Flutter Copy Profiler URL" },
      { "<leader>FL", "<cmd>FlutterLogToggle<cr>", desc = "Flutter Toggle Log" },
    },
    opts = {
      ui = {
        border = "rounded",
        notification_style = "native",
      },
      decorations = {
        statusline = {
          app_version = true,
          device = true,
        },
      },
      widget_guides = {
        enabled = true,
      },
      closing_tags = {
        highlight = "Comment",
        prefix = "// ",
        enabled = true,
      },
      dev_tools = {
        autostart = false,
        auto_open_browser = false,
      },
      outline = {
        open_cmd = "30vnew",
        auto_open = false,
      },
      lsp = {
        color = {
          enabled = true,
        },
        settings = {
          showTodos = true,
          completeFunctionCalls = true,
          renameFilesWithClasses = "prompt",
          enableSnippets = true,
          updateImportsOnRename = true,
        },
      },
    },
  },
}
