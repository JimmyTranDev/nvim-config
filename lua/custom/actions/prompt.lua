-- =============================================================================
-- Prompt Action Functions
-- AI chat and search prompt utilities
-- =============================================================================

local link_constants = require('custom.constants.links')
local github_utils = require('custom.utils.github')
local input_utils = require('custom.utils.input')
local file_utils = require('custom.utils.files')
local errors_utils = require('custom.utils.errors')
local vim_utils = require('custom.utils.vim')
local prompts = require('core.prompts')
local prompt_utils = require('custom.utils.prompt')
local ui_utils = require('custom.utils.ui')
local validation = require('custom.utils.validation')

local M = {}

-- =============================================================================
-- Private Helper Functions
-- =============================================================================

--- Build diagnostic prompt with optional context
---@param diagnostics string Diagnostic text
---@param include_context boolean Whether to include folder context
---@return string prompt Complete diagnostic prompt
local function build_diagnostic_prompt(diagnostics, include_context)
  if not validation.is_non_empty_string(diagnostics) then
    return ''
  end
  
  if include_context then
    local folder_content = file_utils.get_recursive_file_contents()
    return folder_content .. '\n\n' .. diagnostics .. '\n\nPlease fix these errors'
  else
    return diagnostics .. '\n\nPlease fix these errors.\n\n'
  end
end

--- Build role-based prompt with optional context
---@param option table Selected prompt option
---@param selected_text string Selected text from editor
---@param input_text string User input text
---@param include_context boolean Whether to include folder context
---@return string prompt Complete role-based prompt
local function build_role_prompt(option, selected_text, input_text, include_context)
  local base_prompt = option.value .. selected_text .. '\n\n' .. input_text
  
  if include_context then
    local folder_content = file_utils.get_recursive_file_contents()
    return folder_content .. '\n\n' .. base_prompt
  else
    return base_prompt
  end
end

--- Get query from user input in different modes
---@return string|nil query Query string or nil if cancelled
local function get_query_from_mode()
  local mode = vim.api.nvim_get_mode().mode
  
  if mode == 'n' then
    return input_utils.safe_input('Search GitHub: ')
  elseif mode:match('v') then
    return input_utils.get_selected_text()
  end
  
  return nil
end

-- =============================================================================
-- Public API Functions
-- =============================================================================

--- Create diagnostic prompt function with optional context
---@param include_context boolean|nil Whether to include folder context
---@return function prompt_function Function that creates diagnostic prompt
function M.get_diagnostic_prompt(include_context)
  return function()
    local diagnostics = errors_utils.get_diagnostic_texts_under_cursor()
    if not validation.is_non_empty_string(diagnostics) then
      vim.notify('No diagnostics found under cursor', vim.log.levels.WARN)
      return
    end
    
    local prompt = build_diagnostic_prompt(diagnostics, include_context or false)
    if validation.is_non_empty_string(prompt) then
      prompt_utils.handle_prompt(prompt)
    end
  end
end

--- Open AI chat selection interface
---@return function chat_function Function that opens AI chat interface
function M.open_ai_chat()
  return function()
    if not link_constants.aiOptions or #link_constants.aiOptions == 0 then
      vim.notify('No AI options configured', vim.log.levels.WARN)
      return
    end
    
    ui_utils.safe_select(link_constants.aiOptions, {
      prompt = 'Select AI or Search Engine: ',
      format_item = function(item) return item.name end,
    }, function(choice)
      if choice and choice.baseUrl then
        file_utils.open(choice.baseUrl)
      end
    end)
  end
end

--- Create folder prompt function with optional initial query
---@param initial_query string|nil Initial query text
---@return function prompt_function Function that creates folder prompt
function M.folder_prompt(initial_query)
  return function()
    local query = initial_query
    if not validation.is_non_empty_string(query) then
      query = input_utils.safe_input('Enter your query: ')
    end
    
    if not validation.is_non_empty_string(query) then
      vim.notify('Query cannot be empty', vim.log.levels.WARN)
      return
    end
    
    local folder_content = file_utils.get_recursive_file_contents()
    local prompt = folder_content .. query
    prompt_utils.handle_prompt(prompt)
  end
end

--- Create role-based prompt function with optional context
---@param prompt_options table Available prompt options
---@param include_context boolean|nil Whether to include folder context
---@return function prompt_function Function that creates role-based prompt
function M.prompt_role(prompt_options, include_context)
  return function()
    if not prompt_options or #prompt_options == 0 then
      vim.notify('No prompt options provided', vim.log.levels.WARN)
      return
    end
    
    local selected_text = vim_utils.get_selected_text_if_visual_mode()
    
    ui_utils.safe_select(prompt_options, {
      prompt = 'Select prompt: ',
      format_item = function(item) return item.name end,
    }, function(option)
      if not option then return end
      
      local input_text = input_utils.safe_input('What do you want to do?: ')
      if not validation.is_non_empty_string(input_text) then
        vim.notify('Input text cannot be empty', vim.log.levels.WARN)
        return
      end
      
      local full_prompt = build_role_prompt(option, selected_text or '', input_text, include_context or false)
      prompt_utils.handle_prompt(full_prompt)
    end)
  end
end

--- Create general prompt function with optional context
---@param query string|nil Initial query
---@param include_context boolean|nil Whether to include folder context
---@return function prompt_function Function that creates general prompt
function M.prompt(query, include_context)
  return function()
    local updated_query = query
    if not validation.is_non_empty_string(updated_query) then
      updated_query = input_utils.safe_input('Enter your query: ')
    end
    
    if not validation.is_non_empty_string(updated_query) then
      vim.notify('Query cannot be empty', vim.log.levels.WARN)
      return
    end
    
    local selected_text = vim_utils.get_selected_text_if_visual_mode()
    local prompt
    
    if include_context then
      local folder_content = file_utils.get_recursive_file_contents()
      prompt = folder_content .. '\n\n' .. updated_query
    else
      prompt = (selected_text or '') .. '\n\n' .. updated_query
    end
    
    prompt_utils.handle_prompt(prompt)
  end
end

--- Create GitHub search function
---@param org_name string|nil Organization name for search
---@return function search_function Function that searches GitHub
function M.search_github(org_name)
  return function()
    local query = get_query_from_mode()
    if not validation.is_non_empty_string(query) then
      vim.notify('No search query provided', vim.log.levels.WARN)
      return
    end
    
    github_utils.search_github(org_name, query)
  end
end

--- Create search engine query function
---@param initial_query string|nil Initial query
---@return function search_function Function that opens search engine
function M.query_search_engine(initial_query)
  return function()
    local prompt = prompt_utils.get_prompt(initial_query)
    if not validation.is_non_empty_string(prompt) then
      vim.notify('No search prompt provided', vim.log.levels.WARN)
      return
    end
    
    if not link_constants.searchOptions or #link_constants.searchOptions == 0 then
      vim.notify('No search options configured', vim.log.levels.WARN)
      return
    end
    
    prompt_utils.open_with_prompt(prompt, link_constants.searchOptions)
  end
end

return M
