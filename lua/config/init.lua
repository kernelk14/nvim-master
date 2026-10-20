-- AI-generated configuration (Antigravity). See README.md for the authorship disclosure.
-- Config module entry point
-- Ensures compatible Neovim version and loads core modules

local M = {}

function M.setup()
  -- Neovim 0.10.0+ brings native comment support, inlay hints, diagnostic improvements,
  -- and enhanced Lua standard libraries.
  if vim.fn.has("nvim-0.10") ~= 1 then
    vim.notify_once(
      "Warning: This configuration is optimized for Neovim >= 0.10.0.\n"
        .. "Some modern features (inlay hints, native commenting) may not function as expected.",
      vim.log.levels.WARN,
      { title = "Neovim Version Check" }
    )
  end

  require("config.options")
  require("config.keymaps")
  require("config.autocmds")
end

return M
