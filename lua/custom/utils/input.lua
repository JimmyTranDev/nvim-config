local M = {}

function M.get_input(prompt, default_text, allow_empty)
  local input = vim.fn.input(prompt, default_text or '')
  if input == ' ' then return '' end
  if input == '' and not allow_empty then return nil end
  return input
end

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

return M
