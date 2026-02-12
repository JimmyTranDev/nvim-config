local M = {}

local CHECKED_PATTERN = '%[x%]'
local UNCHECKED_PATTERN = '%[ %]'

local function has_unchecked_checkbox(line)
  if not line then return false end
  return line:find(UNCHECKED_PATTERN) ~= nil
end

local function has_any_checkbox(line)
  if not line then return false end
  return line:find('^%s*[-%d].*%[[x ]%]') ~= nil
end

local function check_checkbox(line)
  return line and line:gsub(UNCHECKED_PATTERN, '[x]', 1) or line
end

local function uncheck_checkbox(line)
  return line and line:gsub(CHECKED_PATTERN, '[ ]', 1) or line
end

local function create_checkbox(line)
  if not line then return line end

  if line:match('^%s*-%s') then
    return line:gsub('(%s*- )(.*)', '%1[ ] %2', 1)
  elseif line:match('^%s*%d+%s') then
    return line:gsub('(%s*%d%. )(.*)', '%1[ ] %2', 1)
  end

  return line:gsub('(%S+)', '- [ ] %1', 1)
end

local function get_current_line()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lines = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)
  return lines[1], cursor
end

local function set_current_line(new_line, cursor)
  vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1], false, { new_line })
  vim.api.nvim_win_set_cursor(0, cursor)
end

function M.toggle()
  local line, cursor = get_current_line()
  if not line then return end

  local new_line
  if not has_any_checkbox(line) then
    new_line = create_checkbox(line)
  elseif has_unchecked_checkbox(line) then
    new_line = check_checkbox(line)
  else
    new_line = uncheck_checkbox(line)
  end

  set_current_line(new_line, cursor)
end

vim.api.nvim_create_user_command('ToggleCheckbox', M.toggle, { desc = 'Toggle checkbox on current line' })

return M
