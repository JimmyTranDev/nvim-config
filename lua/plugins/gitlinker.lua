return {
  'ruifm/gitlinker.nvim',
  dependencies = 'nvim-lua/plenary.nvim',
  keys = { '<leader>gY' },
  config = function()
    require('gitlinker').setup({
      mappings = 'gL',
    })
  end,
}
