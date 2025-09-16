return {
  'folke/which-key.nvim',
  cond = function()
    return not require('core.vscode').is_vscode() -- VSCode has its own command palette
  end,
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  event = 'VeryLazy',
  config = function()
    local wk = require('which-key')

    -- =============================================================================
    -- Which-Key Setup Configuration
    -- =============================================================================
    wk.setup({
      preset = 'modern',
      delay = function(ctx) return ctx.plugin and 0 or 200 end,
      sort = { 'order', 'group', 'alphanum', 'mod' },
      expand = 1,
      replace = {
        ['<space>'] = '󱁐',
        ['<cr>'] = '↵',
        ['<tab>'] = '⇥',
        ['<bs>'] = '⌫',
      },
      icons = {
        breadcrumb = ' ',
        separator = ' ',
        group = '+',
        ellipsis = '…',
        mappings = false,
        rules = false,
        keys = {},
      },
      win = {
        border = 'rounded',
        padding = { 1, 2 },
        wo = {
          winblend = 0,
        },
      },
      layout = {
        width = { min = 20 },
        spacing = 3,
      },
      keys = {
        scroll_down = '<c-d>',
        scroll_up = '<c-u>',
      },
      triggers = {
        { '<auto>', mode = 'nixso' },
        { 's', mode = { 'n', 'v' } },
      },
      plugins = {
        marks = false,
        registers = true,
        spelling = {
          enabled = true,
          suggestions = 20,
        },
        presets = {
          operators = true,
          motions = true,
          text_objects = true,
          windows = true,
          nav = true,
          m = true,
          z = true,
          g = true,
        },
      },
    })

    -- =============================================================================
    -- Leader + Leader Groups (Secondary Commands)
    -- =============================================================================
    wk.add({
      {
        mode = { 'n', 'v' },
        { '<leader><leader>', group = '󰌌 Secondary' },
        { '<leader><leader>b', desc = '󰃤 Debugger' },
        { '<leader><leader>d', desc = '󰾆 Database' },
        { '<leader><leader>n', desc = '󰙨 Neotest' },
      },
    })

    -- =============================================================================
    -- Telescope Sub-Groups (Leader + f)
    -- =============================================================================
    wk.add({
      {
        mode = { 'n', 'v' },
        { '<leader>f', group = '󰭎 Telescope' },
        { '<leader>fb', group = '󰓩 Buffers' },
        { '<leader>fh', group = '󰋚 History' },
        { '<leader>fj', group = '󰊢 Git' },
        { '<leader>fl', group = '󰷈 Lists' },
        { '<leader>fv', group = '󰕷 Vim' },
      },
    })

    -- =============================================================================
    -- Git Sub-Groups (Leader + g)
    -- =============================================================================
    wk.add({
      {
        mode = { 'n', 'v' },
        { '<leader>g', group = '󰊢 Git' },
        { '<leader>gb', group = '󰘬 Branch' },
        { '<leader>gc', group = '󰜘 Commit' },
        { '<leader>gC', group = '󰜘 Commit & Push' },
        { '<leader>gn', group = '󰳴 Checkout' },
        { '<leader>gw', group = '󰘴 Worktree' },
        { '<leader>gy', group = '󰋫 Yolo' },
      },
    })

    -- =============================================================================
    -- Terminal Sub-Groups (Leader + t)
    -- =============================================================================
    wk.add({
      {
        mode = { 'n', 'v' },
        { '<leader>t', group = ' Terminal' },
        { '<leader>tc', group = '󱘗 Cargo' },
        { '<leader>tf', group = '󰛨 Flutter' },
        { '<leader>th', group = '󰏖 Pnpm' },
        { '<leader>tl', group = '󰀂 Live Server' },
        { '<leader>tM', group = '󰈙 MJML' },
        { '<leader>tm', group = '󰍔 Markdown' },
        { '<leader>tn', group = '󰎙 NPM' },
        { '<leader>tnu', group = '󰏔 NPM Update' },
        { '<leader>tp', group = '󰌠 Python' },
        { '<leader>tv', group = '󰫙 Maven' },
        { '<leader>tx', group = '󰅗 Close' },
      },
    })

    -- =============================================================================
    -- Utility Sub-Groups (Leader + ;)
    -- =============================================================================
    wk.add({
      {
        mode = { 'n', 'v' },
        { '<leader>;', group = '󰦥 Utilities' },
        { '<leader>;d', group = '󰠷 Development' },
        { '<leader>;f', group = '󰉋 Files & System' },
        { '<leader>;t', group = '󰦅 Text Operations' },
      },
    })

    -- =============================================================================
    -- Links Sub-Groups (Leader + l)
    -- =============================================================================
    wk.add({
      {
        mode = { 'n', 'v' },
        { '<leader>l', group = '󰌷 Links' },
        { '<leader>ls', group = '󰒋 Servers' },
      },
    })

    -- =============================================================================
    -- Main Leader Key Groups
    -- =============================================================================
    wk.add({
      {
        mode = { 'n', 'v' },
        { '<leader>', group = '󱁐 Leader' },
        { '<leader>a', group = '󰚩 Avante AI' },
        { '<leader>c', group = '󰛦 TypeScript Tools' },
        { '<leader>d', group = '󱉏 Dropbar' },
        { '<leader>e', group = '󰇥 File Manager' },
        { '<leader>E', group = '󰇥 File Manager (Root)' },
        { '<leader>h', group = '󰋖 Help & Lookup' },
        { '<leader>i', desc = '󰘻 Jump In' },
        { '<leader>j', group = '󰊢 Git Signs' },
        { '<leader>k', group = '󰘦 Copilot Chat' },
        { '<leader>m', desc = '󰊢 Lazygit' },
        { '<leader>o', desc = '󰘶 Jump Out' },
        { '<leader>p', group = '󰏖 Package Info' },
        { '<leader>q', desc = '󰩈 Quit' },
        { '<leader>Q', desc = '󰩈 Force Quit All' },
        { '<leader>r', group = '󰌱 Logging' },
        { '<leader>s', group = '󰒺 Sort' },
        { '<leader>u', group = '󰦥 Locator' },
        { '<leader>v', group = '󰯲 Diff View' },
        { '<leader>w', desc = '󰆓 Write File' },
        { '<leader>W', desc = '󰆓 Write All Files' },
        { '<leader>y', group = '󰋫 WTF' },
        { '<leader>z', group = '󰒲 Lazy Package Manager' },
        { '<leader><space>', desc = '󱁐 Extra Space' },
      },
    })

    -- =============================================================================
    -- Non-Leader Key Groups
    -- =============================================================================
    wk.add({
      {
        mode = { 'n', 'v' },
        { 'g', group = '󰬴 Go/Goto' },
        { ']', group = '󰮰 Next' },
        { '[', group = '󰮲 Previous' },
        { '<c-w>', group = '󰖲 Windows' },
        { 'z', group = '󰀂 Fold' },
      },
    })

    -- =============================================================================
    -- Empty Lowercase Letter Keymaps (show as "_" in which-key)
    -- =============================================================================
    wk.add({
      {
        mode = { 'n', 'v' },
        { 'a', desc = '_' },
        { 'b', desc = '_' },
        { 'c', desc = '_' },
        { 'd', desc = '_' },
        { 'e', desc = '_' },
        { 'f', desc = '_' },
        { 'h', desc = '_' },
        { 'i', desc = '_' },
        { 'j', desc = '_' },
        { 'k', desc = '_' },
        { 'l', desc = '_' },
        { 'm', desc = '_' },
        { 'n', desc = '_' },
        { 'o', desc = '_' },
        { 'p', desc = '_' },
        { 'q', desc = '_' },
        { 'r', desc = '_' },
        { 's', desc = '_' },
        { 't', desc = '_' },
        { 'u', desc = '_' },
        { 'v', desc = '_' },
        { 'w', desc = '_' },
        { 'x', desc = '_' },
        { 'y', desc = '_' },
      },
    })
  end,
}
