-- Core Autocommands
-- Clean, lightweight event hooks for enhanced editing ergonomics

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local core_group = augroup("CoreAutocmds", { clear = true })

-- Highlight on yank: provides immediate visual confirmation of yanked text
autocmd("TextYankPost", {
  group = core_group,
  desc = "Highlight text on yank",
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 200 })
  end,
})

-- Restore cursor position when opening a file
autocmd("BufReadPost", {
  group = core_group,
  desc = "Restore cursor to last known position",
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Automatically rebalance splits on terminal or window resize
autocmd("VimResized", {
  group = core_group,
  desc = "Auto-resize splits when window is resized",
  command = "tabdo wincmd =",
})

-- Close auxiliary windows with 'q'
autocmd("FileType", {
  group = core_group,
  pattern = {
    "qf",
    "help",
    "man",
    "notify",
    "lspinfo",
    "checkhealth",
    "startuptime",
  },
  desc = "Close auxiliary windows with 'q'",
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", {
      buffer = event.buf,
      silent = true,
      desc = "Close buffer",
    })
  end,
})

-- Check if file was modified outside of Neovim when gaining focus
autocmd({ "FocusGained", "TermLeave", "BufEnter" }, {
  group = core_group,
  desc = "Check for external file changes",
  command = "checktime",
})

-- Terminal settings: disable line numbers and enter insert mode immediately
autocmd("TermOpen", {
  group = core_group,
  desc = "Clean terminal window defaults",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd("startinsert")
  end,
})
