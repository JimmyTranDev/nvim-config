return {
  'williamboman/mason-lspconfig.nvim',
  dependencies = {
    'saghen/blink.cmp',
    'jay-babu/mason-nvim-dap.nvim',
    'mfussenegger/nvim-dap',
    'neovim/nvim-lspconfig',
    'williamboman/mason.nvim',
  },
  lazy = false,
  opts = {
    servers = {
      jdtls = {},
      lua_ls = {
        filetypes = { 'lua' },
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' },
            },
            workspace = {
              checkThirdParty = false,
            },
          },
        },
      },
      gopls = {
        settings = {
          completions = {
            completeFunctionCalls = true,
          },
        },
      },
      cssls = {},
      eslint = {},
      html = {},
      jsonls = {},
      marksman = {},
      pyright = {},
      rust_analyzer = {},
      ts_ls = {
        init_options = {
          preferences = {
            importModuleSpecifierPreference = 'relative',
            importModuleSpecifierEnding = 'minimal',
          },
        },
      },
      kotlin_language_server = {},
      sqls = {},
    },
  },
  config = function(_, opts)
    require('mason').setup()
    require('mason-nvim-dap').setup({
      ensure_installed = {
        'stylua',
      },
      automatic_installation = true,
    })

    local servers = {}
    for server, _ in pairs(opts.servers) do
      table.insert(servers, server)
    end

    require('mason-lspconfig').setup({
      automatic_installation = true,
      ensure_installed = servers,
    })

    for server, config in pairs(opts.servers) do
      if server == 'lua_ls' then
        local lspconfig_util = require('lspconfig.util')
        config.root_dir = lspconfig_util.root_pattern('.git', vim.fn.getcwd())
      end

      config.flags = {
        debounce_text_changes = 300,
        allow_incremental_sync = true,
        exit_timeout = 2000,
      }

      local original_on_attach = config.on_attach
      config.on_attach = function(client, bufnr)
        if original_on_attach then original_on_attach(client, bufnr) end

        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_exec_autocmds('LspAttach', {
              buffer = bufnr,
              data = { client_id = client.id },
            })
          end
        end)
      end

      config.capabilities = require('blink.cmp').get_lsp_capabilities(config.capabilities)
      vim.lsp.config(server, config)
    end
  end,
}
