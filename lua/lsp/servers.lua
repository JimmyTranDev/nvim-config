local M = {}

M.servers = {
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
  ts_ls = {
    init_options = {
      preferences = {
        importModuleSpecifierPreference = 'relative',
        importModuleSpecifierEnding = 'minimal',
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
  kotlin_language_server = {},
  sqls = {},
}

return M
