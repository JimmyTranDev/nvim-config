local M = {}

function M.get_input(prompt, default_text, allow_empty)
  local input = vim.fn.input(prompt, default_text or '')
  if input == ' ' then return '' end
  if input == '' and not allow_empty then
    return M.get_input(prompt, default_text, allow_empty)
  end
  return input
end

M.getInputFromUser = M.get_input

function M.get_selected_text(clean)
  local old_reg = vim.fn.getreg('"')
  vim.cmd('normal! ""y')
  local selected = vim.fn.getreg('"')
  vim.fn.setreg('"', old_reg)
  if clean then
    return selected:gsub('"', ''):gsub(':', '')
  end
  return selected
end

M.getSelectedText = function() return M.get_selected_text(true) end
M.getSelectedTextPure = function() return M.get_selected_text(false) end

function M.get_buffer_content()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
end

function M.replace_buffer_content(new_content)
  if type(new_content) ~= 'string' then error('New content must be a string') end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(new_content, '\n'))
end

return M
