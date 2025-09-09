return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  cond = function()
    return not require('core.vscode').is_vscode() -- VSCode has its own formatters
  end,
  opts = {},
  config = function()
    require('conform').setup({
      format_after_save = {
        lsp_format = 'fallback',
        async = true,
        timeout_ms = 10000,
      },
      formatters_by_ft = {
        python = { 'black', 'isort' },
        go = { 'goimports', 'gofmt' },
        dart = { 'dartfmt' },
        java = { 'google-java-format' },
        lua = { 'stylua' },

        javascript = { 'eslint' },
        javascriptreact = { 'eslint' },
        typescript = { 'eslint' },
        typescriptreact = { 'eslint' },

        json = { 'prettier' },
        jsonc = { 'prettier' },
        html = { 'prettier ' },
        css = { 'prettier' },
        -- markdown = { "prettier" },
        xhtml = { 'prettier' },
        xml = { 'prettier' },
        yaml = { 'prettier' },

        -- bash = { "shfmt" },
        -- sh = { "shfmt" },
      },
    })
  end,
}
