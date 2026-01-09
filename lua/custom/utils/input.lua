local M = {}

function M.get_input(prompt, default_text, allow_empty)
  local input = vim.fn.input(prompt, default_text or '')

  if input == ' ' then return '' end

  if input == '' and not allow_empty then return M.get_input(prompt, default_text, allow_empty) end

  return input
end

function M.getInputFromUser(prompt, text) return M.get_input(prompt, text, false) end

function M.get_selected_text()
  local old_reg = vim.fn.getreg('"')
  vim.cmd('normal! ""y')
  local selected = vim.fn.getreg('"')
  vim.fn.setreg('"', old_reg)
  return selected
end

function M.getSelectedText()
  vim.cmd('normal! y')
  local selected_text = vim.fn.getreg('"')
  return selected_text:gsub('"', ''):gsub(':', '')
end

function M.getSelectedTextPure()
  vim.cmd('normal! y')
  return vim.fn.getreg('"')
end

function M.get_buffer_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, '\n')
end

function M.replace_buffer_content(new_content)
  if not new_content or type(new_content) ~= 'string' then error('New content must be a string') end

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.split(new_content, '\n')
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

return M
