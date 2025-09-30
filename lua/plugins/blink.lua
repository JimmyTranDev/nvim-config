return {
  'saghen/blink.cmp',
  event = 'InsertEnter',
  dependencies = {
    'echasnovski/mini.nvim',
  },
  version = '*',
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    cmdline = {
      enabled = false,
    },
    -- keymap = { preset = 'enter' },
    keymap = {
      ['<CR>'] = { 'select_and_accept', 'fallback' },
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<S-PageDown>'] = { 'scroll_documentation_down' },
      ['<S-PageUp>'] = { 'scroll_documentation_up' },
      ['<C-n>'] = { 'show', 'show_documentation', 'hide_documentation' },
      -- ["<S-Tab>"] = { "select_prev", "fallback" },
      -- ["<Tab>"] = { "select_next", "fallback" },
      -- ['<C-b>'] = {},
      -- ['<C-e>'] = {},
      -- ['<C-f>'] = {},
      -- ['<C-p>'] = {},
      -- ['<C-space>'] = {},
      -- ['<C-y>'] = {},
    },
    -- appearance = {
    --   use_nvim_cmp_as_default = true,
    --   nerd_font_variant = 'mono'
    -- },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
    signature = { enabled = true },
    completion = {
      accept = { auto_brackets = { enabled = false } },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 100,
      },
      menu = {
        draw = {
          components = {
            kind_icon = {
              ellipsis = false,
              text = function(ctx)
                local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
                return kind_icon
              end,
              highlight = function(ctx)
                local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                return hl
              end,
            },
          },
        },
      },
    },
  },
  opts_extend = { 'sources.default' },
}
