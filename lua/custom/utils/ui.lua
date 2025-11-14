-- =============================================================================
-- UI Utility Functions
-- Common patterns for user interface interactions
-- =============================================================================

local M = {}

-- =============================================================================
-- Selection Utilities
-- =============================================================================

--- Safe vim.ui.select with error handling
---@param items table List of items to select from
---@param opts table Options for vim.ui.select
---@param callback function Callback function for selection
function M.safe_select(items, opts, callback)
  if not items or #items == 0 then
    vim.notify('No items available for selection', vim.log.levels.WARN)
    return
  end
  
  if not callback then
    error('Callback function is required')
  end
  
  vim.ui.select(items, opts or {}, function(selected)
    if selected then
      callback(selected)
    end
  end)
end

--- Select from git log entries with SHA mapping
---@param include_all? boolean Include all branches
---@param callback function Called with (selected_line, sha)
function M.select_commit(include_all, callback)
  local git_utils = require('custom.utils.git')
  local commit_lines, line_to_sha = git_utils.get_commit_log(include_all)
  
  if #commit_lines == 0 then
    vim.notify('No commits found', vim.log.levels.WARN)
    return
  end
  
  M.safe_select(commit_lines, {
    prompt = 'Select commit:',
    format_item = function(item) return item end,
  }, function(selected_line)
    local sha = line_to_sha[selected_line]
    if sha then
      callback(selected_line, sha)
    else
      vim.notify('Failed to extract commit SHA', vim.log.levels.ERROR)
    end
  end)
end

--- Select from file list with validation
---@param dir string Directory to list files from
---@param prompt string Prompt for selection
---@param callback function Called with selected filename
function M.select_file(dir, prompt, callback)
  local file_utils = require('custom.utils.files')
  local files = file_utils.list_files(dir)
  
  M.safe_select(files, {
    prompt = prompt or 'Select file:',
  }, callback)
end

-- =============================================================================
-- Input Utilities
-- =============================================================================

--- Safe vim.ui.input with validation
---@param opts table Input options
---@param validator? function Optional validation function
---@param callback function Callback with validated input
function M.safe_input(opts, validator, callback)
  -- Handle case where validator is omitted
  if type(validator) == 'function' and not callback then
    callback = validator
    validator = nil
  end
  
  if not callback then
    error('Callback function is required')
  end
  
  vim.ui.input(opts, function(input)
    if not input or input == '' then
      return -- User cancelled or provided empty input
    end
    
    -- Run validation if provided
    if validator then
      local is_valid, error_msg = validator(input)
      if not is_valid then
        vim.notify(error_msg or 'Invalid input', vim.log.levels.WARN)
        return
      end
    end
    
    callback(input)
  end)
end

--- Input with confirmation prompt
---@param opts table Input options
---@param confirmation_prompt string Confirmation message
---@param callback function Called with confirmed input
function M.input_with_confirmation(opts, confirmation_prompt, callback)
  M.safe_input(opts, function(input)
    M.safe_input({
      prompt = confirmation_prompt .. ' (type "yes" to confirm): ',
    }, function(confirmation)
      if confirmation == 'yes' then
        callback(input)
      else
        vim.notify('Operation cancelled', vim.log.levels.INFO)
      end
    end)
  end)
end

-- =============================================================================
-- Progress and Feedback
-- =============================================================================

--- Show progress notification
---@param message string Progress message
---@param level? number Log level (default: INFO)
---@return table notification Notification handle
function M.show_progress(message, level)
  return vim.notify(message, level or vim.log.levels.INFO)
end

--- Update progress notification
---@param notification table Notification handle
---@param message string New message
---@param level? number Log level
function M.update_progress(notification, message, level)
  vim.notify(message, level or vim.log.levels.INFO, {
    replace = notification
  })
end

--- Show success notification
---@param message string Success message
function M.show_success(message)
  vim.notify(message, vim.log.levels.INFO)
end

--- Show error notification
---@param message string Error message
function M.show_error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

--- Show warning notification
---@param message string Warning message
function M.show_warning(message)
  vim.notify(message, vim.log.levels.WARN)
end

-- =============================================================================
-- Command Execution with UI Feedback
-- =============================================================================

--- Execute command in terminal with notification
---@param cmd string Command to execute
---@param success_msg? string Success message
---@param terminal_id? number Terminal ID (default: 5)
function M.exec_with_feedback(cmd, success_msg, terminal_id)
  if not cmd then
    error('Command is required')
  end
  
  local term_id = terminal_id or 5
  local term_cmd = string.format('TermExec%d cmd=\'%s\'', term_id, cmd)
  
  vim.cmd(term_cmd)
  
  if success_msg then
    vim.defer_fn(function()
      M.show_success(success_msg)
    end, 500) -- Small delay to let command start
  end
end

--- Execute command in background terminal
---@param cmd string Command to execute
---@param success_msg? string Success message
function M.exec_background(cmd, success_msg)
  M.exec_with_feedback(cmd, success_msg, 5)
end

-- =============================================================================
-- Multi-step Workflows
-- =============================================================================

--- Create a workflow builder for multi-step operations
---@return table workflow Workflow builder object
function M.create_workflow()
  local workflow = {
    steps = {},
    current_step = 1,
  }
  
  --- Add step to workflow
  ---@param name string Step name
  ---@param fn function Step function
  ---@return table workflow For chaining
  function workflow:add_step(name, fn)
    table.insert(self.steps, { name = name, fn = fn })
    return self
  end
  
  --- Execute next step in workflow
  function workflow:next()
    if self.current_step > #self.steps then
      M.show_success('Workflow completed')
      return
    end
    
    local step = self.steps[self.current_step]
    M.show_progress('Executing: ' .. step.name)
    
    step.fn(function()
      self.current_step = self.current_step + 1
      self:next()
    end)
  end
  
  --- Start workflow execution
  function workflow:execute()
    if #self.steps == 0 then
      M.show_warning('No steps defined in workflow')
      return
    end
    
    self.current_step = 1
    self:next()
  end
  
  return workflow
end

return M