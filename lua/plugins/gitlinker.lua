return {
  'ruifm/gitlinker.nvim',
  dependencies = 'nvim-lua/plenary.nvim',
  keys = {
    { '<leader>ul', mode = 'n' },
    { '<leader>ul', mode = 'v' },
  },
  config = function()
    require('gitlinker').setup({
      mappings = '<leader>gL',
    })
  end,
}
