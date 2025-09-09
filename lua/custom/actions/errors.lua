local errorsUtils = require('custom.utils.errors')
local M = {}

function M.copyDiagnosticUnderCursor()
  local diagnosticsText = errorsUtils.getDiagnosticTextsUnderCursor()
  local diagnostics = vim.diagnostic.get()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = cursor_pos[1] - 1 -- 0-indexed
  local col = cursor_pos[2]

  for _, diag in ipairs(diagnostics) do
    if diag.lnum == line and col >= diag.col and col <= diag.end_col then
      vim.fn.setreg('+', diagnosticsText) -- Copy to system clipboard
      vim.notify('Copied diagnostic to clipboard: ' .. diag.message, vim.log.levels.INFO)
      return
    end
  end

  vim.notify('No diagnostic message under cursor.', vim.log.levels.WARN)
end

return M
