-- =============================================================================
-- Input and Buffer Utilities
-- =============================================================================

local M = {}

-- =============================================================================
-- User Input Functions
-- =============================================================================

--- Get input from user with validation and retry logic
---@param prompt string The prompt to display
---@param default_text? string Default text to show (optional)
---@param allow_empty? boolean Whether to allow empty input (default: false)
---@return string input The user input
function M.get_input(prompt, default_text, allow_empty)
  local input = vim.fn.input(prompt, default_text or '')
  
  -- Handle special case where space means empty string
  if input == ' ' then
    return ''
  end
  
  -- Retry if empty and not allowed
  if input == '' and not allow_empty then
    return M.get_input(prompt, default_text, allow_empty)
  end
  
  return input
end

--- Legacy function for backward compatibility
---@param prompt string The prompt to display
---@param text? string Default text to show
---@return string input The user input
function M.getInputFromUser(prompt, text)
  return M.get_input(prompt, text, false)
end

-- =============================================================================
-- Text Selection Functions  
-- =============================================================================

--- Get selected text with register preservation
---@return string selected_text The selected text
function M.get_selected_text()
  local old_reg = vim.fn.getreg('"')
  vim.cmd('normal! ""y')
  local selected = vim.fn.getreg('"')
  vim.fn.setreg('"', old_reg)
  return selected
end

--- Get selected text with character filtering (legacy)
---@return string selected_text The filtered selected text
function M.getSelectedText()
  vim.cmd('normal! y')
  local selected_text = vim.fn.getreg('"')
  return selected_text:gsub('"', ''):gsub(':', '')
end

--- Get selected text without any processing (legacy)
---@return string selected_text The raw selected text
function M.getSelectedTextPure()
  vim.cmd('normal! y')
  return vim.fn.getreg('"')
end

-- =============================================================================
-- Buffer Content Functions
-- =============================================================================

--- Get current buffer content as a string
---@return string content The buffer content
function M.get_buffer_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, '\n')
end

--- Replace current buffer content
---@param new_content string The new content to set
function M.replace_buffer_content(new_content)
  if not new_content or type(new_content) ~= 'string' then
    error('New content must be a string')
  end
  
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.split(new_content, '\n')
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

return M
