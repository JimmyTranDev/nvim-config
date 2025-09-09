local is_vscode = require('core.vscode').is_vscode
return {
  'gelguy/wilder.nvim',
  keys = { '/', '?', ':' },
  cond = function()
    return not is_vscode()
  end,
  config = function()
    local wilder = require('wilder')
    wilder.setup({ modes = { ':', '/', '?' } })
  end,
}
