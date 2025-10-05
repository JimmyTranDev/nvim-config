return {
  'folke/which-key.nvim',
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  event = 'VeryLazy',
  config = function()
    local wk = require('which-key')
    -- Get current Catppuccin flavor and colors
    local function get_catppuccin_colors()
      -- Default to mocha flavor since we removed theme switching
      local current_flavor = 'mocha'
      local catppuccin = require('catppuccin.palettes').get_palette(current_flavor)
      return catppuccin
    end

    -- Function to apply which-key highlights
    local function apply_which_key_highlights()
      local colors = get_catppuccin_colors()

      vim.api.nvim_set_hl(0, 'WhichKey', { fg = colors.mauve }) -- mauve
      vim.api.nvim_set_hl(0, 'WhichKeyGroup', { fg = colors.blue }) -- blue
      vim.api.nvim_set_hl(0, 'WhichKeyDesc', { fg = colors.yellow }) -- yellow
      vim.api.nvim_set_hl(0, 'WhichKeySeperator', { fg = colors.sapphire }) -- sapphire
      vim.api.nvim_set_hl(0, 'WhichKeyFloat', { bg = colors.base }) -- base
      vim.api.nvim_set_hl(0, 'WhichKeyBorder', { fg = colors.surface2 }) -- surface2
    end

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
      icons = wk.icons or {
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
    -- Which-Key Custom Highlights (Dynamic Catppuccin)
    -- =============================================================================
    -- Apply initial highlights
    apply_which_key_highlights()

    -- Auto-refresh highlights when colorscheme changes
    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = 'catppuccin*',
      callback = apply_which_key_highlights,
      desc = 'Refresh which-key highlights when Catppuccin theme changes',
    })

    -- Export refresh function for manual use
    _G.refresh_which_key_highlights = apply_which_key_highlights

    -- =============================================================================
    -- Leader + Leader Groups (Secondary Commands)
    -- =============================================================================
    -- All Which-Key Mappings
    -- =============================================================================
    wk.add({
      -- Secondary Leader Commands
      { '<leader><leader>', group = '󰌌 Secondary', mode = { 'n', 'v' } },
      { '<leader><leader>d', group = '󰠷 Development', mode = { 'n', 'v' } },
      { '<leader><leader>f', group = '󰉋 Files', mode = { 'n', 'v' } },
      { '<leader><leader>t', group = '󰦅 Text', mode = { 'n', 'v' } },
      { '<leader><leader>r', group = '󰛔 Replace', mode = { 'n', 'v' } },
      { '<leader><leader>m', group = '󰈙 Manual', mode = { 'n', 'v' } },

      -- Quick Access Commands
      { '<leader>;', group = '󰓦 Quick Access', mode = { 'n', 'v' } },

      -- Find/Search Groups (Leader + f)
      { '<leader>f', group = '󰭎 Find', mode = { 'n', 'v' } },
      { '<leader>fb', group = '󰓩 Buffers', mode = { 'n', 'v' } },
      { '<leader>fh', group = '󰋚 History', mode = { 'n', 'v' } },
      { '<leader>fj', group = '󰊢 Git', mode = { 'n', 'v' } },
      { '<leader>fl', group = '󰷈 Lists', mode = { 'n', 'v' } },
      { '<leader>fv', group = '󰕷 Vim', mode = { 'n', 'v' } },

      -- Git Operations (Leader + g)
      { '<leader>g', group = '󰊢 Git', mode = { 'n', 'v' } },
      { '<leader>gb', group = '󰘬 Branch', mode = { 'n', 'v' } },
      { '<leader>gc', group = '󰜘 Commit', mode = { 'n', 'v' } },
      { '<leader>gC', group = '󰜘 Commit & Push', mode = { 'n', 'v' } },
      { '<leader>gn', group = '󰳴 Checkout', mode = { 'n', 'v' } },
      { '<leader>gw', group = '󰘴 Worktree', mode = { 'n', 'v' } },
      { '<leader>gy', group = '󰋫 Quick', mode = { 'n', 'v' } },

      -- Terminal Commands (Leader + t)
      { '<leader>t', group = ' Terminal', mode = { 'n', 'v' } },
      { '<leader>tc', group = '󱘗 Cargo', mode = { 'n', 'v' } },
      { '<leader>tf', group = '󰛨 Flutter', mode = { 'n', 'v' } },
      { '<leader>th', group = '󰏖 Pnpm', mode = { 'n', 'v' } },
      { '<leader>tl', group = '󰀂 Server', mode = { 'n', 'v' } },
      { '<leader>tM', group = '󰈙 MJML', mode = { 'n', 'v' } },
      { '<leader>tm', group = '󰍔 Markdown', mode = { 'n', 'v' } },
      { '<leader>tn', group = '󰎙 NPM', mode = { 'n', 'v' } },
      { '<leader>tnu', group = '󰏔 Updates', mode = { 'n', 'v' } },
      { '<leader>tp', group = '󰌠 Python', mode = { 'n', 'v' } },
      { '<leader>tv', group = '󰫙 Maven', mode = { 'n', 'v' } },
      { '<leader>tx', group = '󰅗 Close', mode = { 'n', 'v' } },

      -- External Links (Leader + l)
      { '<leader>l', group = '󰌷 Links', mode = { 'n', 'v' } },
      { '<leader>ls', group = '󰒋 Servers', mode = { 'n', 'v' } },

       -- Main Leader Key Groups
       { '<leader>', group = '󱁐 Leader', mode = { 'n', 'v' } },
       { '<leader>a', group = '󰚩 AI', mode = { 'n', 'v' } },
       { '<leader>c', group = '󰛦 TypeScript', mode = { 'n', 'v' } },
       { '<leader>d', group = '󱉏 Dropbar', mode = { 'n', 'v' } },
       { '<leader>e', group = '󰇥 Explorer', mode = { 'n', 'v' } },
       { '<leader>E', group = '󰇥 Explorer (Root)', mode = { 'n', 'v' } },
       { '<leader>i', desc = '󰘻 Jump In', mode = { 'n', 'v' } },
       { '<leader>j', group = '󰊢 Git Hunks', mode = { 'n', 'v' } },
       { '<leader>m', desc = '󰊢 Lazygit', mode = { 'n', 'v' } },
       { '<leader>o', desc = '󰘶 Jump Out', mode = { 'n', 'v' } },
       { '<leader>p', group = '󰏖 Packages', mode = { 'n', 'v' } },
       { '<leader>q', desc = '󰩈 Quit', mode = { 'n', 'v' } },
       { '<leader>Q', desc = '󰩈 Force Quit', mode = { 'n', 'v' } },
       { '<leader>r', group = '󰌱 Todoist', mode = { 'n', 'v' } },
       { '<leader>s', group = '󰒺 Sort', mode = { 'n', 'v' } },
       { '<leader>u', group = '󰦥 Locator', mode = { 'n', 'v' } },
       { '<leader>v', group = '󰯲 Diff', mode = { 'n', 'v' } },
       { '<leader>w', desc = '󰆓 Save', mode = { 'n', 'v' } },
       { '<leader>W', desc = '󰆓 Save All', mode = { 'n', 'v' } },
       { '<leader>y', group = '󰋫 WTF', mode = { 'n', 'v' } },
       { '<leader>z', group = '󰒲 Lazy', mode = { 'n', 'v' } },
       { '<leader><space>', desc = '󱁐 Extra', mode = { 'n', 'v' } },

      -- Non-Leader Key Groups
      { 'g', group = '󰬴 Goto', mode = { 'n', 'v' } },
      { ']', group = '󰮯 Next', mode = { 'n', 'v' } },
      { '[', group = '󰮲 Previous', mode = { 'n', 'v' } },
      { '<c-w>', group = '󰖲 Windows', mode = { 'n', 'v' } },
      { 'z', group = '󰀂 Fold', mode = { 'n', 'v' } },

      -- Empty Lowercase Letter Keymaps (show as "_" in which-key)
      { 'a', desc = '_', mode = { 'n', 'v' } },
      { 'b', desc = '_', mode = { 'n', 'v' } },
      { 'c', desc = '_', mode = { 'n', 'v' } },
      { 'd', desc = '_', mode = { 'n', 'v' } },
      { 'e', desc = '_', mode = { 'n', 'v' } },
      { 'f', desc = '_', mode = { 'n', 'v' } },
      { 'h', desc = '_', mode = { 'n', 'v' } },
      { 'i', desc = '_', mode = { 'n', 'v' } },
      { 'j', desc = '_', mode = { 'n', 'v' } },
      { 'k', desc = '_', mode = { 'n', 'v' } },
      { 'l', desc = '_', mode = { 'n', 'v' } },
      { 'm', desc = '_', mode = { 'n', 'v' } },
      { 'n', desc = '_', mode = { 'n', 'v' } },
      { 'o', desc = '_', mode = { 'n', 'v' } },
      { 'p', desc = '_', mode = { 'n', 'v' } },
      { 'q', desc = '_', mode = { 'n', 'v' } },
      { 'r', desc = '_', mode = { 'n', 'v' } },
      { 's', desc = '_', mode = { 'n', 'v' } },
      { 't', desc = '_', mode = { 'n', 'v' } },
      { 'u', desc = '_', mode = { 'n', 'v' } },
      { 'v', desc = '_', mode = { 'n', 'v' } },
      { 'w', desc = '_', mode = { 'n', 'v' } },
      { 'x', desc = '_', mode = { 'n', 'v' } },
      { 'y', desc = '_', mode = { 'n', 'v' } },
    })
  end,
}
