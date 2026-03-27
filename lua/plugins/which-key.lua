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
      { '<leader><leader>', '󰌌 Secondary' },
      { '<leader><leader>d', '󰠷 Development' },
      { '<leader><leader>f', '󰉋 Files' },
      { '<leader><leader>t', '󰦅 Text' },
      { '<leader><leader>r', '󰛔 Replace' },
      { '<leader><leader>m', '󰈙 Manual' },
      { '<leader>l', '󰌷 Links & Quick Access' },
      { '<leader>v', '󰉋 Analysis' },
      { '<leader>f', '󰭎 Find' },
      { '<leader>fb', '󰓩 Buffers' },
      { '<leader>fc', '󰘖 Commands' },
      { '<leader>fd', '󰈙 Diagnostics' },
      { '<leader>fg', '󰊢 Git Files' },
      { '<leader>fh', '󰋚 History' },
      { '<leader>fj', '󰊢 Git' },
      { '<leader>fl', '󰷈 Lists' },
      { '<leader>fm', '󰈙 Marks' },
      { '<leader>fo', '󰈙 Options' },
      { '<leader>fr', '󰋚 Recent' },
      { '<leader>fs', '󰛔 Symbols' },
      { '<leader>fv', '󰕷 Vim' },
      { '<leader>fw', '󰬴 Words' },
      { '<leader>g', '󰊢 Git' },
      { '<leader>gb', '󰘬 Branch' },
      { '<leader>gc', '󰜘 Commit' },
      { '<leader>gC', '󰜘 Commit & Push' },
      { '<leader>gd', '󰆼 Diff' },
      { '<leader>gf', '󰈞 Files' },
      { '<leader>gh', '󰊤 GitHub' },
      { '<leader>gl', '󰋫 Log' },
      { '<leader>gn', '󰳴 Checkout' },
      { '<leader>gp', '󰏫 Push/Pull' },
      { '<leader>gr', '󰑓 Reset' },
      { '<leader>gs', '󰘻 Stash' },
      { '<leader>gt', '󰓩 Tags' },
      { '<leader>gw', '󰘴 Worktree' },
      { '<leader>gy', '󰋫 Quick' },
      { '<leader>h', '󰓩 Tab Operations' },
      { '<leader>t', ' Terminal' },
      { '<leader>tb', '󰃤 Build' },
      { '<leader>tc', '󱘗 Cargo' },
      { '<leader>td', '󰈇 Docker' },
      { '<leader>te', '󰙅 Exec' },
      { '<leader>tf', '󰛨 Flutter' },
      { '<leader>tg', '󰊢 Git' },
      { '<leader>th', '󰏖 Pnpm' },
      { '<leader>ti', '󰐱 Install' },
      { '<leader>tj', '󰌢 Java' },
      { '<leader>tk', '󰘳 Kill' },
      { '<leader>tl', '󰀂 Server' },
      { '<leader>tM', '󰈙 MJML' },
      { '<leader>tm', '󰍔 Markdown' },
      { '<leader>tn', '󰎙 NPM' },
      { '<leader>tnu', '󰏔 Updates' },
      { '<leader>to', '󰏊 Open' },
      { '<leader>tp', '󰌠 Python' },
      { '<leader>tq', '󰿅 Quick' },
      { '<leader>tr', '󰑓 Run' },
      { '<leader>ts', '󰓦 Scripts' },
      { '<leader>tt', '󰙨 Test' },
      { '<leader>tu', '󰚰 Utils' },
      { '<leader>tv', '󰫙 Java' },
      { '<leader>tw', '󰖲 Watch' },
      { '<leader>tx', '󰅗 Close' },
      { '<leader>ty', '󰛢 Yarn' },
      { '<leader>tz', '󰘳 Zone' },
      { '<leader>b', '󰓩 Buffer Management' },
      { '<leader>bc', '󰅗 Close Buffers' },
      { '<leader>bs', '󰒺 Sort Buffers' },
      { '<leader>', '󱁐 Leader' },
      { '<leader>a', '󰚩 AI' },
      { '<leader>d', '󱉏 Dropbar' },
      { '<leader>e', '󰇥 Explorer' },
      { '<leader>E', '󰇥 Explorer (Root)' },
      { '<leader>j', '󰊢 Git Hunks' },
      { '<leader>k', '󰌌 Keymaps' },
      { '<leader>n', '󰖲 Window Splits' },
      { '<leader>p', '󰏖 Packages' },
      { '<leader>r', '󰌱 Todoist' },
      { '<leader>s', '󰒺 Sort' },
      { '<leader>tl', '󰞷 LeetCode' },
      { '<leader>u', '󰦥 Locator' },
      { '<leader>V', '󰯲 Diff' },
      { '<leader>x', '󰅗 Close' },
      { '<leader>y', '󰋫 WTF' },
      { '<leader>z', '󰒲 Lazy' },
      { 'g', '󰬴 Goto' },
      { ']', '󰮯 Next' },
      { '[', '󰮲 Previous' },
      { '<c-w>', '󰖲 Windows' },
      { 'z', '󰀂 Fold' },
    }

    local descs = {
      { '<leader>F', '󰙂 Floating Terminal' },
      { '<leader>i', '󰘻 Jump In' },
      { '<leader>m', '󰊢 Lazygit' },
      { '<leader>o', '󰘶 Jump Out' },
      { '<leader>q', '󰩈 Quit' },
      { '<leader>Q', '󰩈 Force Quit' },
      { '<leader>w', '󰆓 Save' },
      { '<leader>W', '󰆓 Save All' },
      { '<leader><space>', '󱁐 Extra' },
    }

    local mappings = {}
    for _, g in ipairs(groups) do
      table.insert(mappings, { g[1], group = g[2], mode = { 'n', 'v' } })
    end
    for _, d in ipairs(descs) do
      table.insert(mappings, { d[1], desc = d[2], mode = { 'n', 'v' } })
    end
    for _, c in ipairs({ 'a', 'b', 'c', 'd', 'e', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y' }) do
      table.insert(mappings, { c, desc = '_', mode = { 'n', 'v' } })
    end

    wk.add(mappings)
  end,
}
