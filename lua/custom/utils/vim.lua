local inputUtils = require('custom.utils.input')

local M = {}

function M.getSelectedTextIfVisualMode()
  local mode = vim.api.nvim_get_mode().mode
  local value = ''

  if mode == 'v' or mode == 'V' or mode == '\22' then value = inputUtils.getSelectedTextPure() end

  return value
end

return M
