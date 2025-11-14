-- =============================================================================
-- Checkbox Toggle Action Functions
-- Markdown/text checkbox management utilities
-- =============================================================================

local M = {}

-- =============================================================================
-- Configuration
-- =============================================================================

local CONFIG = {
  checked_char = 'x',
  unchecked_char = ' ',
}

-- =============================================================================
-- Private Helper Functions
-- =============================================================================

--- Get checkbox patterns
---@return table patterns Table of checkbox patterns
local function get_checkbox_patterns()
  return {
    checked = '%[' .. CONFIG.checked_char .. '%]',
    unchecked = '%[' .. CONFIG.unchecked_char .. '%]',
  }
end

--- Check if line contains an unchecked checkbox
---@param line string Line to check
---@return boolean has_unchecked True if line contains unchecked checkbox
local function has_unchecked_checkbox(line)
  if not line or type(line) ~= 'string' then return false end
  return line:find(get_checkbox_patterns().unchecked) ~= nil
end

--- Check if line contains a checked checkbox
---@param line string Line to check  
---@return boolean has_checked True if line contains checked checkbox
local function has_checked_checkbox(line)
  if not line or type(line) ~= 'string' then return false end
  return line:find(get_checkbox_patterns().checked) ~= nil
end

--- Check if line contains any checkbox (checked or unchecked)
---@param line string Line to check
---@return boolean has_checkbox True if line contains any checkbox
local function has_any_checkbox(line)
  if not line or type(line) ~= 'string' then return false end
  
  local patterns = get_checkbox_patterns()
  
  -- Check for list item with checkbox: "- [x]" or "- [ ]"
  local list_checked = '^%s*- ' .. patterns.checked
  local list_unchecked = '^%s*- ' .. patterns.unchecked
  
  -- Check for numbered item with checkbox: "1. [x]" or "1. [ ]"  
  local num_checked = '^%s*%d%. ' .. patterns.checked
  local num_unchecked = '^%s*%d%. ' .. patterns.unchecked
  
  return line:find(list_checked) or line:find(list_unchecked) or
         line:find(num_checked) or line:find(num_unchecked)
end

--- Check a checkbox (convert unchecked to checked)
---@param line string Line to modify
---@return string modified_line Line with checkbox checked
local function check_checkbox(line)
  if not line or type(line) ~= 'string' then return line end
  
  local patterns = get_checkbox_patterns()
  return line:gsub(patterns.unchecked, '[' .. CONFIG.checked_char .. ']', 1)
end

--- Uncheck a checkbox (convert checked to unchecked)
---@param line string Line to modify
---@return string modified_line Line with checkbox unchecked
local function uncheck_checkbox(line)
  if not line or type(line) ~= 'string' then return line end
  
  local patterns = get_checkbox_patterns()
  return line:gsub(patterns.checked, '[' .. CONFIG.unchecked_char .. ']', 1)
end

--- Convert line to checkbox format
---@param line string Line to convert
---@return string checkbox_line Line with checkbox added
local function create_checkbox(line)
  if not line or type(line) ~= 'string' then return line end
  
  -- Check if already a list or numbered item
  local is_list_item = line:match('^%s*-%s.*$')
  local is_numbered_item = line:match('^%s*%d+%s.*$')
  
  if not is_list_item and not is_numbered_item then
    -- "xxx" -> "- [ ] xxx"
    return line:gsub('(%S+)', '- [ ] %1', 1)
  elseif is_list_item then
    -- "- xxx" -> "- [ ] xxx"
    return line:gsub('(%s*- )(.*)', '%1[ ] %2', 1)
  elseif is_numbered_item then
    -- "1. xxx" -> "1. [ ] xxx"
    return line:gsub('(%s*%d%. )(.*)', '%1[ ] %2', 1)
  end
  
  return line
end

--- Get current line content safely
---@return string|nil line Current line content or nil if error
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

--- Set current line content safely
---@param new_line string New line content
---@return boolean success True if line was set successfully
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

-- =============================================================================
-- Public API Functions
-- =============================================================================

--- Toggle checkbox state on current line
--- Creates checkbox if none exists, toggles state if checkbox exists
function M.toggle()
  local current_line = get_current_line()
  if not current_line then
    vim.notify('Failed to get current line', vim.log.levels.ERROR)
    return
  end
  
  local new_line
  
  if not has_any_checkbox(current_line) then
    -- No checkbox exists, create one
    new_line = create_checkbox(current_line)
  elseif has_unchecked_checkbox(current_line) then
    -- Has unchecked checkbox, check it
    new_line = check_checkbox(current_line)
  elseif has_checked_checkbox(current_line) then
    -- Has checked checkbox, uncheck it
    new_line = uncheck_checkbox(current_line)
  else
    -- Fallback - shouldn't reach here
    new_line = current_line
  end
  
  if not set_current_line(new_line) then
    vim.notify('Failed to update line', vim.log.levels.ERROR)
  end
end

--- Force check checkbox on current line
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
  
  if not set_current_line(new_line) then
    vim.notify('Failed to update line', vim.log.levels.ERROR)
  end
end

--- Force uncheck checkbox on current line
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
  
  if not set_current_line(new_line) then
    vim.notify('Failed to update line', vim.log.levels.ERROR)
  end
end

--- Toggle checkbox for selected lines (visual mode)
function M.toggle_selection()
  local start_line = vim.fn.line("'<") - 1 -- Convert to 0-indexed
  local end_line = vim.fn.line("'>") - 1   -- Convert to 0-indexed
  
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

-- =============================================================================
-- Configuration
-- =============================================================================

--- Set checkbox characters
---@param checked_char? string Character for checked boxes (default: 'x')
---@param unchecked_char? string Character for unchecked boxes (default: ' ') 
function M.configure(checked_char, unchecked_char)
  if checked_char then
    CONFIG.checked_char = checked_char
  end
  if unchecked_char then
    CONFIG.unchecked_char = unchecked_char
  end
end

-- =============================================================================
-- Command Registration
-- =============================================================================

-- Create user commands
vim.api.nvim_create_user_command('ToggleCheckbox', M.toggle, {
  desc = 'Toggle checkbox on current line'
})

vim.api.nvim_create_user_command('CheckCheckbox', M.check, {
  desc = 'Check checkbox on current line'
})

vim.api.nvim_create_user_command('UncheckCheckbox', M.uncheck, {
  desc = 'Uncheck checkbox on current line'
})

return M
