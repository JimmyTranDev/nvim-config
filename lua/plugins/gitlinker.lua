return {
  'ruifm/gitlinker.nvim',
  dependencies = 'nvim-lua/plenary.nvim',
  keys = {
    { '<leader>gL', mode = 'n' },
    { '<leader>gL', mode = 'v' },
  },
  config = function()
    require('gitlinker').setup({
      mappings = '<leader>gL',
    })
  end,
}
