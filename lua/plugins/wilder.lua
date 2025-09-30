return {
  'gelguy/wilder.nvim',
  keys = { '/', '?', ':' },
  config = function()
    local wilder = require('wilder')
    wilder.setup({ modes = { ':', '/', '?' } })
  end,
}
