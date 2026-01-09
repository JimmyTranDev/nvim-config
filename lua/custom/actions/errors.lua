local errors_utils = require('custom.utils.errors')

local M = {}

function M.copy_diagnostic_under_cursor()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = cursor_pos[1] - 1 -- Convert to 0-indexed
  local col = cursor_pos[2]

  local bufnr = vim.api.nvim_get_current_buf()
  local line_diagnostics = vim.diagnostic.get(bufnr, { lnum = line })

  for _, diagnostic in ipairs(line_diagnostics) do
    local start_col = diagnostic.col
    local end_col = diagnostic.end_col or diagnostic.col

    if col >= start_col and col <= end_col then
      local diagnostic_text = errors_utils.getDiagnosticTextsUnderCursor()
      vim.fn.setreg('+', diagnostic_text)
      vim.notify('Copied diagnostic to clipboard: ' .. diagnostic.message, vim.log.levels.INFO)
      return
    end
  end

  vim.notify('No diagnostic found under cursor', vim.log.levels.WARN)
end

function M.copy_all_buffer_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr)

  if #diagnostics == 0 then
    vim.notify('No diagnostics found in current buffer', vim.log.levels.INFO)
    return
  end

  local diagnostic_lines = {}
  for i, diagnostic in ipairs(diagnostics) do
    local severity = vim.diagnostic.severity[diagnostic.severity] or 'Unknown'
    local line_num = diagnostic.lnum + 1 -- Convert to 1-indexed for display
    local message = string.format('%d. Line %d [%s]: %s', i, line_num, severity, diagnostic.message)
    table.insert(diagnostic_lines, message)
  end

  local combined_text = table.concat(diagnostic_lines, '\n')
  vim.fn.setreg('+', combined_text)
  vim.notify(string.format('Copied %d diagnostics to clipboard', #diagnostics), vim.log.levels.INFO)
end

function M.jump_and_copy_next_diagnostic()
  vim.diagnostic.goto_next()

  vim.defer_fn(function() M.copy_diagnostic_under_cursor() end, 50)
end

function M.jump_and_copy_prev_diagnostic()
  vim.diagnostic.goto_prev()

  vim.defer_fn(function() M.copy_diagnostic_under_cursor() end, 50)
end

M.copyDiagnosticUnderCursor = M.copy_diagnostic_under_cursor

return M
