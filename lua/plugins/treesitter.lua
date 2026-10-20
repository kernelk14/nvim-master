-- Treesitter Syntax Highlighting and Incremental Parsing
-- Provides AST-based syntax highlighting, indentation, and folding

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    opts = {
      -- Core parsers to ensure consistent highlighting across platforms
      ensure_installed = {
        "c",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "bash",
        "python",
        "json",
        "yaml",
      },
      -- Only auto-install parsers if a C compiler is detected
      auto_install = (function()
        local compilers = { "cc", "gcc", "clang", "cl", "zig" }
        for _, comp in ipairs(compilers) do
          if vim.fn.executable(comp) == 1 then
            return true
          end
        end
        return false
      end)(),
      highlight = {
        enable = true,
        -- Disable treesitter highlighting for huge files to prevent lag
        disable = function(_, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
