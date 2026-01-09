local M = {}

local CONFIG = {
  checked_char = 'x',
  unchecked_char = ' ',
}

local function get_checkbox_patterns()
  return {
    checked = '%[' .. CONFIG.checked_char .. '%]',
    unchecked = '%[' .. CONFIG.unchecked_char .. '%]',
  }
end

local function has_unchecked_checkbox(line)
  if not line or type(line) ~= 'string' then return false end
  return line:find(get_checkbox_patterns().unchecked) ~= nil
end

local function has_checked_checkbox(line)
  if not line or type(line) ~= 'string' then return false end
  return line:find(get_checkbox_patterns().checked) ~= nil
end

local function has_any_checkbox(line)
  if not line or type(line) ~= 'string' then return false end

  local patterns = get_checkbox_patterns()

  local list_checked = '^%s*- ' .. patterns.checked
  local list_unchecked = '^%s*- ' .. patterns.unchecked

  local num_checked = '^%s*%d%. ' .. patterns.checked
  local num_unchecked = '^%s*%d%. ' .. patterns.unchecked

  return line:find(list_checked) or line:find(list_unchecked) or line:find(num_checked) or line:find(num_unchecked)
end

local function check_checkbox(line)
  if not line or type(line) ~= 'string' then return line end

  local patterns = get_checkbox_patterns()
  return line:gsub(patterns.unchecked, '[' .. CONFIG.checked_char .. ']', 1)
end

local function uncheck_checkbox(line)
  if not line or type(line) ~= 'string' then return line end

  local patterns = get_checkbox_patterns()
  return line:gsub(patterns.checked, '[' .. CONFIG.unchecked_char .. ']', 1)
end

local function create_checkbox(line)
  if not line or type(line) ~= 'string' then return line end

  local is_list_item = line:match('^%s*-%s.*$')
  local is_numbered_item = line:match('^%s*%d+%s.*$')

  if not is_list_item and not is_numbered_item then
    return line:gsub('(%S+)', '- [ ] %1', 1)
  elseif is_list_item then
    return line:gsub('(%s*- )(.*)', '%1[ ] %2', 1)
  elseif is_numbered_item then
    return line:gsub('(%s*%d%. )(.*)', '%1[ ] %2', 1)
  end

  return line
end

local function get_current_line()
  local ok, result = pcall(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor[1] - 1 -- Convert to 0-indexed
    local lines = vim.api.nvim_buf_get_lines(bufnr, line_num, line_num + 1, false)
    return lines[1] or ''
  end)

  return ok and result or nil
end

local function set_current_line(new_line)
  if not new_line then return false end

  local ok = pcall(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor[1] - 1 -- Convert to 0-indexed

    vim.api.nvim_buf_set_lines(bufnr, line_num, line_num + 1, false, { new_line })
    vim.api.nvim_win_set_cursor(0, cursor) -- Restore cursor position
  end)

  return ok
end

function M.toggle()
  local current_line = get_current_line()
  if not current_line then
    vim.notify('Failed to get current line', vim.log.levels.ERROR)
    return
  end

  local new_line

  if not has_any_checkbox(current_line) then
    new_line = create_checkbox(current_line)
  elseif has_unchecked_checkbox(current_line) then
    new_line = check_checkbox(current_line)
  elseif has_checked_checkbox(current_line) then
    new_line = uncheck_checkbox(current_line)
  else
    new_line = current_line
  end

  if not set_current_line(new_line) then vim.notify('Failed to update line', vim.log.levels.ERROR) end
end

function M.check()
  local current_line = get_current_line()
  if not current_line then
    vim.notify('Failed to get current line', vim.log.levels.ERROR)
    return
  end

  local new_line
  if not has_any_checkbox(current_line) then
    new_line = create_checkbox(current_line)
    new_line = check_checkbox(new_line)
  else
    new_line = check_checkbox(current_line)
  end

  if not set_current_line(new_line) then vim.notify('Failed to update line', vim.log.levels.ERROR) end
end

function M.uncheck()
  local current_line = get_current_line()
  if not current_line then
    vim.notify('Failed to get current line', vim.log.levels.ERROR)
    return
  end

  local new_line
  if not has_any_checkbox(current_line) then
    new_line = create_checkbox(current_line)
  else
    new_line = uncheck_checkbox(current_line)
  end

  if not set_current_line(new_line) then vim.notify('Failed to update line', vim.log.levels.ERROR) end
end

function M.toggle_selection()
  local start_line = vim.fn.line("'<") - 1 -- Convert to 0-indexed
  local end_line = vim.fn.line("'>") - 1 -- Convert to 0-indexed

  if start_line < 0 or end_line < 0 or start_line > end_line then
    vim.notify('Invalid selection', vim.log.levels.WARN)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

  local modified_lines = {}
  for _, line in ipairs(lines) do
    local new_line
    if not has_any_checkbox(line) then
      new_line = create_checkbox(line)
    elseif has_unchecked_checkbox(line) then
      new_line = check_checkbox(line)
    elseif has_checked_checkbox(line) then
      new_line = uncheck_checkbox(line)
    else
      new_line = line
    end
    table.insert(modified_lines, new_line)
  end

  vim.api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, modified_lines)
end

function M.configure(checked_char, unchecked_char)
  if checked_char then CONFIG.checked_char = checked_char end
  if unchecked_char then CONFIG.unchecked_char = unchecked_char end
end

vim.api.nvim_create_user_command('ToggleCheckbox', M.toggle, {
  desc = 'Toggle checkbox on current line',
})

vim.api.nvim_create_user_command('CheckCheckbox', M.check, {
  desc = 'Check checkbox on current line',
})

vim.api.nvim_create_user_command('UncheckCheckbox', M.uncheck, {
  desc = 'Uncheck checkbox on current line',
})

return M
