return {
  'gelguy/wilder.nvim',
  keys = { '/', '?', ':' },
  config = function()
    local wilder = require('wilder')
    wilder.setup({ modes = { ':', '/', '?' } })

    local palette = require('catppuccin.palettes').get_palette('mocha')
    if not palette then return end

    vim.api.nvim_set_hl(0, 'WilderBorder', { fg = palette.overlay0, bg = palette.mantle })
    vim.api.nvim_set_hl(0, 'WilderDefault', { fg = palette.text, bg = palette.mantle })
    vim.api.nvim_set_hl(0, 'WilderSelected', { fg = palette.text, bg = palette.surface0 })
    vim.api.nvim_set_hl(0, 'WilderAccent', { fg = palette.mauve, bg = palette.mantle })
    vim.api.nvim_set_hl(0, 'WilderSelectedAccent', { fg = palette.mauve, bg = palette.surface0 })

    wilder.set_option('pipeline', {
      wilder.branch(
        wilder.cmdline_pipeline({ fuzzy = 1 }),
        wilder.search_pipeline()
      ),
    })

    wilder.set_option(
      'renderer',
      wilder.popupmenu_border_theme({
        border = 'rounded',
        highlights = {
          border = 'WilderBorder',
          default = 'WilderDefault',
          selected = 'WilderSelected',
          accent = 'WilderAccent',
          selected_accent = 'WilderSelectedAccent',
        },
        pumblend = 0,
        min_width = '100%',
        min_height = '25%',
        max_height = '25%',
        reverse = 0,
        left = { ' ', wilder.popupmenu_devicons() },
        right = { ' ', wilder.popupmenu_scrollbar() },
      })
    )
  end,
}
