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
      lua_ls = {
        filetypes = { 'lua' },
        -- root_dir will be set in the config function
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
      -- Set root_dir for lua_ls specifically
      if server == 'lua_ls' then
        config.root_dir = require('lspconfig.util').root_pattern('.git', vim.fn.getcwd())
      end
      
      -- Performance optimizations
      config.flags = {
        debounce_text_changes = 300, -- Increased for better performance (was 150)
        allow_incremental_sync = true, -- Enable incremental sync for better performance
        exit_timeout = 2000, -- Faster LSP shutdown
      }
      
      -- Ensure LSP starts properly on buffer attach
      local original_on_attach = config.on_attach
      config.on_attach = function(client, bufnr)
        -- Call original on_attach if it exists
        if original_on_attach then
          original_on_attach(client, bufnr)
        end
        
        -- Ensure buffer is ready for LSP features
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(bufnr) then
            -- Trigger any additional setup needed
            vim.api.nvim_exec_autocmds('LspAttach', { 
              buffer = bufnr,
              data = { client_id = client.id }
            })
          end
        end)
      end
      
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
