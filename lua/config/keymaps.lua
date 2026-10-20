-- Core Keymaps
-- Logical, discoverable, and conflict-free keybindings
-- All mappings use standard vim.keymap.set with descriptive help text

local map = vim.keymap.set

-- ----------------------------------------------------------------------------
-- General & Navigation
-- ----------------------------------------------------------------------------

-- Clear search highlights on pressing <Esc> in normal mode
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Better window navigation using Ctrl + hjkl
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Resize windows with Ctrl + Arrow keys
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Split management
map("n", "<leader>wv", "<cmd>vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>ws", "<cmd>split<CR>", { desc = "Split window horizontally" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close current window" })
map("n", "<leader>we", "<C-w>=", { desc = "Make splits equal size" })

-- Fast file saving
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<CR><esc>", { desc = "Save file" })

-- ----------------------------------------------------------------------------
-- Buffer Navigation & Management
-- ----------------------------------------------------------------------------

map("n", "[b", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })

-- Close current buffer safely without closing the split layout
map("n", "<leader>bd", function()
  local current_buf = vim.api.nvim_get_current_buf()
  if vim.bo[current_buf].modified then
    local choice = vim.fn.confirm("Buffer has unsaved changes. Save before closing?", "&Yes\n&No\n&Cancel", 1)
    if choice == 1 then
      vim.cmd("silent write")
    elseif choice == 3 or choice == 0 then
      return
    end
  end
  vim.cmd("bprevious")
  vim.cmd("bdelete! " .. current_buf)
end, { desc = "Delete current buffer" })

-- ----------------------------------------------------------------------------
-- Visual Mode Improvements
-- ----------------------------------------------------------------------------

-- Move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Stay in indent mode when indenting with < and >
map("v", "<", "<gv", { desc = "Indent left and keep selection" })
map("v", ">", ">gv", { desc = "Indent right and keep selection" })

-- Paste over selection without replacing the default register
map("x", "p", [["_dP]], { desc = "Paste without overwriting register" })

-- ----------------------------------------------------------------------------
-- Diagnostics (Built-in Neovim Diagnostics)
-- ----------------------------------------------------------------------------

map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics floating window" })
map("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "Add diagnostics to location list" })

-- ----------------------------------------------------------------------------
-- Quickfix Navigation
-- ----------------------------------------------------------------------------

map("n", "[q", "<cmd>cprev<CR>", { desc = "Previous quickfix item" })
map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix item" })

-- ----------------------------------------------------------------------------
-- Terminal Mode Escape
-- ----------------------------------------------------------------------------

-- Press <Esc><Esc> to exit terminal mode easily
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
