-- AI-generated configuration (Antigravity). See README.md for the authorship disclosure.
-- Language Server Protocol (LSP) Configuration
-- Seamless integration with Mason for automatic server management

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim", config = true },
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Diagnostic display configuration
      local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      vim.diagnostic.config({
        virtual_text = {
          prefix = "●",
          spacing = 4,
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })

      -- Buffer-local keymaps configured only when an LSP attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          local buf = event.buf
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = "LSP: " .. desc })
          end

          map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
          map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
          map("n", "gr", vim.lsp.buf.references, "Goto References")
          map("n", "gi", vim.lsp.buf.implementation, "Goto Implementation")
          map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
          map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
          map("n", "<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("n", "<leader>cf", function()
            vim.lsp.buf.format({ async = true })
          end, "Format Document")

          -- Toggle inlay hints in Neovim 0.10+
          if vim.lsp.inlay_hint and client and client.supports_method("textDocument/inlayHint") then
            map("n", "<leader>ch", function()
              local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
              vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = buf })
              vim.notify("Inlay hints " .. (is_enabled and "disabled" or "enabled"))
            end, "Toggle Inlay Hints")
          end
        end,
      })

      -- Enhanced capabilities for autocompletion
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end

      -- Mason package manager integration
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      local lspconfig = require("lspconfig")

      require("mason-lspconfig").setup({
        -- Minimal base: ensure lua_ls and intelephense are ready
        ensure_installed = { "lua_ls", "intelephense" },
        automatic_installation = false,
        handlers = {
          -- Default handler for automatically configured servers
          function(server_name)
            lspconfig[server_name].setup({
              capabilities = capabilities,
            })
          end,
          -- Custom configuration for Lua language server
          ["lua_ls"] = function()
            lspconfig.lua_ls.setup({
              capabilities = capabilities,
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { "vim" },
                  },
                  workspace = {
                    checkThirdParty = false,
                    library = {
                      vim.env.VIMRUNTIME,
                    },
                  },
                  telemetry = { enable = false },
                },
              },
            })
          end,
          -- Custom configuration for PHP & CodeIgniter language server
          ["intelephense"] = function()
            lspconfig.intelephense.setup({
              capabilities = capabilities,
              settings = {
                intelephense = {
                  files = {
                    maxSize = 5000000,
                  },
                  environment = {
                    phpVersion = "8.2",
                  },
                  completion = {
                    insertUseDeclaration = true,
                    fullyQualifyGlobalConstantsAndFunctions = false,
                  },
                  format = {
                    enable = true,
                  },
                  stubs = {
                    "apache",
                    "bcmath",
                    "bz2",
                    "calendar",
                    "Core",
                    "curl",
                    "date",
                    "dba",
                    "dom",
                    "enchant",
                    "fileinfo",
                    "filter",
                    "ftp",
                    "gd",
                    "gettext",
                    "hash",
                    "iconv",
                    "imap",
                    "intl",
                    "json",
                    "ldap",
                    "libxml",
                    "mbstring",
                    "mcrypt",
                    "mysql",
                    "mysqli",
                    "password",
                    "pcntl",
                    "pcre",
                    "PDO",
                    "pdo_mysql",
                    "Phar",
                    "readline",
                    "recode",
                    "Reflection",
                    "regex",
                    "session",
                    "SimpleXML",
                    "soap",
                    "sockets",
                    "sodium",
                    "SPL",
                    "standard",
                    "superglobals",
                    "tokenizer",
                    "xml",
                    "xdebug",
                    "xmlreader",
                    "xmlwriter",
                    "yaml",
                    "zip",
                    "zlib",
                  },
                },
              },
            })
          end,
        },
      })
    end,
  },
}
