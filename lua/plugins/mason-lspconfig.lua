return {
  'williamboman/mason-lspconfig.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  cond = function()
    return not require('core.vscode').is_vscode() -- VSCode manages its own LSP servers
  end,
  dependencies = {
    'saghen/blink.cmp',
    'jay-babu/mason-nvim-dap.nvim',
    'mfussenegger/nvim-dap',
    'neovim/nvim-lspconfig',
    'williamboman/mason.nvim',
  },
  opts = {
    servers = {
      lua_ls = {
        filetypes = { 'lua' },
        root_dir = require('lspconfig.util').root_pattern('.git', vim.fn.getcwd()),
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
      -- shfmt = {},
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

    local lspconfig = require('lspconfig')
    for server, config in pairs(opts.servers) do
      -- passing config.capabilities to blink.cmp merges with the capabilities in your
      -- `opts[server].capabilities, if you've defined it
      config.capabilities = require('blink.cmp').get_lsp_capabilities(config.capabilities)
      -- config.on_attach = function(client, bufnr)
      --   require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
      -- end
      lspconfig[server].setup(config)
    end

  end,
}
