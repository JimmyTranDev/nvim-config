-- =============================================================================
-- Vim Utility Functions
-- =============================================================================

local inputUtils = require('custom.utils.input')

local M = {}

-- =============================================================================
-- Visual Mode Utilities
-- =============================================================================

--- Get selected text if currently in visual mode
---@return string selected_text The selected text, or empty string if not in visual mode
function M.getSelectedTextIfVisualMode()
  local mode = vim.api.nvim_get_mode().mode
  local value = ''

  if mode == 'v' or mode == 'V' or mode == '\22' then -- \22 is visual block mode
    value = inputUtils.getSelectedTextPure()
  end

  return value
end

return M
