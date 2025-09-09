return {
  'TobinPalmer/rayso.nvim',
  keys = {
    {
      mode = 'v',
      '<leader>;r',
      ':lua require("lib.create").create_snippet()<CR>',
      desc = 'Create Snippet',
      silent = true,
    },
  },
  config = function()
    require('rayso').setup({
      open_cmd = 'firefox',
    })
  end,
}
