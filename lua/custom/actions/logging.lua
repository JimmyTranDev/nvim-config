-- =============================================================================
-- Logging Action Functions
-- History and activity logging utilities
-- =============================================================================

local input_utils = require('custom.utils.input')
local logging_utils = require('custom.utils.logging')
local github_utils = require('custom.utils.github')
local validation = require('custom.utils.validation')

local M = {}

-- =============================================================================
-- Public API Functions
-- =============================================================================

--- Create a function to log history with custom prefix and prompt
---@param _ any Unused parameter (kept for backward compatibility)
---@param commit_message_prefix string Prefix to add to commit message
---@param prompt string Prompt to show user
---@return function log_function Function that logs history when called
function M.log_history(_, commit_message_prefix, prompt)
  return function()
    if not validation.is_non_empty_string(commit_message_prefix) then
      vim.notify('Commit message prefix is required', vim.log.levels.ERROR)
      return
    end
    
    if not validation.is_non_empty_string(prompt) then
      vim.notify('Prompt text is required', vim.log.levels.ERROR)
      return
    end
    
    local message = input_utils.safe_input(prompt .. ': ')
    if not validation.is_non_empty_string(message) then
      vim.notify('Log message cannot be empty', vim.log.levels.WARN)
      return
    end
    
    local repo_name = github_utils.get_repo_name()
    if not repo_name then
      vim.notify('Could not determine repository name', vim.log.levels.WARN)
      repo_name = 'unknown'
    end
    
    local full_message = commit_message_prefix .. message
    logging_utils.log_history(repo_name, full_message)
    
    vim.notify('Log entry added', vim.log.levels.INFO)
  end
end

return M
