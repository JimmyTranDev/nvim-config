return {
  'folke/which-key.nvim',
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  event = 'VeryLazy',
  config = function()
    local wk = require('which-key')

    local function apply_highlights()
      local colors = require('catppuccin.palettes').get_palette('mocha')
      local highlights = {
        WhichKey = { fg = colors.mauve },
        WhichKeyGroup = { fg = colors.blue },
        WhichKeyDesc = { fg = colors.yellow },
        WhichKeySeperator = { fg = colors.sapphire },
        WhichKeyFloat = { bg = colors.base },
        WhichKeyBorder = { fg = colors.surface2 },
      }
      for name, val in pairs(highlights) do
        vim.api.nvim_set_hl(0, name, val)
      end
    end

    wk.setup({
      preset = 'modern',
      delay = function(ctx) return ctx.plugin and 0 or 200 end,
      sort = { 'order', 'group', 'alphanum', 'mod' },
      expand = 1,
      replace = { ['<space>'] = '󱁐', ['<cr>'] = '↵', ['<tab>'] = '⇥', ['<bs>'] = '⌫' },
      icons = { breadcrumb = ' ', separator = ' ', group = '+', ellipsis = '…', mappings = false, rules = false, keys = {} },
      win = { border = 'rounded', padding = { 1, 2 }, wo = { winblend = 0 } },
      layout = { width = { min = 20 }, spacing = 3 },
      keys = { scroll_down = '<c-d>', scroll_up = '<c-u>' },
      triggers = { { '<auto>', mode = 'nixso' }, { 's', mode = { 'n', 'v' } } },
      plugins = {
        marks = false,
        registers = true,
        spelling = { enabled = true, suggestions = 20 },
        presets = { operators = true, motions = true, text_objects = true, windows = true, nav = true, m = true, z = true, g = true },
      },
    })

    apply_highlights()
    vim.api.nvim_create_autocmd('ColorScheme', { pattern = 'catppuccin*', callback = apply_highlights })
    _G.refresh_which_key_highlights = apply_highlights

    local groups = {
      { '<leader>;', '󰌌 Secondary' },
      { '<leader>;d', '󰠷 Development' },
      { '<leader>;f', '󰉋 Files' },
      { '<leader>;T', '󰦅 Text' },
      { '<leader><leader>r', '󰛔 Replace' },
      { '<leader><leader>S', '󰆓 Session' },
      { '<leader>;c', '󰑓 Cache' },
      { '<leader>;y', '󰌷 Copy & Quick Access' },
      { '<leader>;v', '󰉋 Analysis' },
      { '<leader><leader>l', '󰞷 LeetCode' },
      { '<leader><leader>t', '⌨ Typing Test' },
      { '<leader>f', '󰭎 Find' },
      { '<leader>fc', '󰘖 Commands' },
      { '<leader>fd', '󰈙 Diagnostics' },
      { '<leader>fg', '󰊢 Git Files' },

      { '<leader>fj', '󰊢 Git' },
      { '<leader>fl', '󰷈 Lists' },
      { '<leader>fm', '󰈙 Marks' },
      { '<leader>fo', '󰈙 Options' },
      { '<leader>fr', '󰋚 Recent' },

      { '<leader>fv', '󰕷 Vim' },
      { '<leader>fw', '󰬴 Words' },
      { '<leader>g', '󰊢 Git' },
      { '<leader>gb', '󰘬 Branch' },
      { '<leader>gc', '󰜘 Commit' },
      { '<leader>gC', '󰜘 Commit & Push' },

      { '<leader>gf', '󰈞 Files' },
      { '<leader>gh', '󰊤 GitHub' },
      { '<leader>gl', '󰋫 Log' },
      { '<leader>gn', '󰳴 Checkout' },
      { '<leader>gp', '󰏫 Push/Pull' },
      { '<leader>gr', '󰑓 Reset' },
      { '<leader>gs', '󰘻 Stash' },

      { '<leader>gw', '󰘴 Worktree' },
      { '<leader>gy', '󰋫 Quick' },
      { '<leader>t', ' Terminal' },
      { '<leader>tm', '󰣖 Makefile' },
      { '<leader>tn', '󰎙 NPM' },
      { '<leader>tnu', '󰏔 Updates' },
      { '<leader>tv', '󰫙 Maven' },
      { '<leader>tx', '󰅗 Close' },
      { '<leader>', '󱁐 Leader' },
      { '<leader><leader>a', '󰚩 AI & Copilot' },
      { '<leader><leader>c', '󰙨 Test' },
      { '<leader>e', '󰇥 Explorer' },
      { '<leader>E', '󰇥 Explorer (Root)' },
      { '<leader>j', '󰊢 Git Hunks' },

      { '<leader><leader>n', '󰖲 Window Splits' },
      { '<leader><leader>p', '󰏖 Packages' },
      { '<leader>r', '󰌱 Capture' },
      { '<leader><leader>s', '󰒺 Sort & Swap' },
      { '<leader>u', '󰦥 Open & Links' },
      { '<leader><leader>x', '󰅗 Close & Health' },
      { '<leader>z', '󰒲 Lazy' },
      { 'g', '󰬴 Goto' },
      { ']', '󰮯 Next' },
      { '[', '󰮲 Previous' },
      { '<c-w>', '󰖲 Windows' },
      { 'z', '󰀂 Fold' },
    }

    local descs = {
      { '<leader>;j', '󰌧 Generate this week jira tasks' },

      { '<leader>i', '󰘻 Jump In' },
      { '<leader>m', '󰊢 Lazygit' },
      { '<leader>o', '󰘶 Jump Out' },
      { '<leader>q', '󰩈 Quit' },
      { '<leader>Q', '󰩈 Force Quit' },
      { '<leader>w', '󰆓 Save' },
      { '<leader>W', '󰆓 Save All' },
    }

    local mappings = {}
    for _, g in ipairs(groups) do
      table.insert(mappings, { g[1], group = g[2], mode = { 'n', 'v' } })
    end
    for _, d in ipairs(descs) do
      table.insert(mappings, { d[1], desc = d[2], mode = { 'n', 'v' } })
    end
    for _, c in ipairs({ 'a', 'c', 'd', 'e', 'f', 'i', 'j', 'k', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x' }) do
      table.insert(mappings, { c, desc = '_', mode = { 'n', 'v' } })
    end

    wk.add(mappings)
  end,
}
