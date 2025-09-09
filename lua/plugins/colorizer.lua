return {
  'norcalli/nvim-colorizer.lua',
  event = 'BufReadPre',
  cond = function()
    return not require('core.vscode').is_vscode() -- VSCode has built-in color highlighting
  end,
  config = function() require('colorizer').setup() end,
}
