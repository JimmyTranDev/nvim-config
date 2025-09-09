local M = {}

function M.getInputFromUser(prompt, text)
  local input = vim.fn.input(prompt, text or '')
  if input == '' then return M.getInputFromUser(prompt) end

  if input == ' ' then return '' end

  return input
end

function M.getSelectedText()
  vim.cmd('normal! y')
  local selectedText = vim.fn.getreg('"')
  return selectedText:gsub('"', ''):gsub(':', '')
end

function M.getSelectedTextPure()
  vim.cmd('normal! y')
  return vim.fn.getreg('"')
end

function M.get_selected_text()
  -- Store current register content
  local old_reg = vim.fn.getreg('"')
  -- Yank selected text to default register
  vim.cmd('normal! ""y')
  -- Get yanked text
  local selected = vim.fn.getreg('"')
  -- Restore original register content
  vim.fn.setreg('"', old_reg)
  return selected
end

function M.get_current_buffer_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, '\n')
end

function M.replace_current_buffer_content(new_content)
  -- Get the current buffer number
  local bufnr = vim.api.nvim_get_current_buf()
  -- Set the new content for the buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(new_content, '\n'))
end

return M
