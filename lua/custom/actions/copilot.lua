-- =============================================================================
-- Copilot Chat Action Functions  
-- GitHub Copilot Chat integration utilities
-- =============================================================================

local input_utils = require('custom.utils.input')
local ui_utils = require('custom.utils.ui')

local M = {}

-- =============================================================================
-- Private Helper Functions
-- =============================================================================

--- Get CopilotChat module safely
---@return table|nil copilot_chat CopilotChat module or nil if not available
local function get_copilot_chat()
  local ok, copilot_chat = pcall(require, 'CopilotChat')
  if not ok then
    vim.notify('CopilotChat plugin not available', vim.log.levels.ERROR)
    return nil
  end
  return copilot_chat
end

--- Open Copilot chat and ask query
---@param query string Query to ask
---@return boolean success True if query was sent successfully
local function ask_copilot(query)
  if not query or query == '' then
    vim.notify('No query provided', vim.log.levels.WARN)
    return false
  end
  
  local chat = get_copilot_chat()
  if not chat then return false end
  
  local ok = pcall(function()
    chat.open()
    chat.ask(query)
  end)
  
  if not ok then
    vim.notify('Failed to communicate with Copilot Chat', vim.log.levels.ERROR)
    return false
  end
  
  return true
end

--- Get diagnostic text under cursor
---@return string|nil diagnostic_text Diagnostic text or nil if none found
local function get_diagnostic_under_cursor()
  local errors_actions = require('custom.actions.errors')
  local errors_utils = require('custom.utils.errors')
  
  local ok, diagnostic_text = pcall(errors_utils.getDiagnosticTextsUnderCursor)
  if ok and diagnostic_text and diagnostic_text ~= '' and 
     diagnostic_text ~= 'No diagnostics found under cursor' then
    return diagnostic_text
  end
  
  return nil
end

-- =============================================================================
-- Chat Templates
-- =============================================================================

local CHAT_TEMPLATES = {
  fix_error = 'Fix the following error in my code:\n\n%s',
  improve_code = '%s\n\nPlease improve or refactor the code above. The result should be in a code block.',
  explain_code = '%s\n\nPlease explain what this code does and how it works.',
  optimize_code = '%s\n\nPlease optimize this code for better performance and readability.',
  add_comments = '%s\n\nPlease add helpful comments to this code.',
  convert_to_typescript = '%s\n\nPlease convert this JavaScript code to TypeScript with proper types.',
}

-- =============================================================================
-- Public API Functions
-- =============================================================================

--- Fix error under cursor using Copilot Chat
function M.fix_error_under_cursor()
  local diagnostic_text = get_diagnostic_under_cursor()
  if not diagnostic_text then
    vim.notify('No error found under cursor', vim.log.levels.WARN)
    return
  end
  
  local query = string.format(CHAT_TEMPLATES.fix_error, diagnostic_text)
  if ask_copilot(query) then
    ui_utils.show_success('Copilot Chat opened with error fix request')
  end
end

--- Chat with selected text and custom query
function M.chat_with_selection()
  local selected_text = input_utils.get_selected_text()
  if not selected_text or selected_text == '' then
    vim.notify('No text selected', vim.log.levels.WARN)
    return
  end
  
  ui_utils.safe_input({
    prompt = 'Enter your question about the selected code: ',
  }, function(user_query)
    local query = selected_text .. '\n\n' .. user_query
    if ask_copilot(query) then
      ui_utils.show_success('Copilot Chat opened with your question')
    end
  end)
end

--- Improve/refactor selected code
function M.improve_selection()
  local selected_text = input_utils.get_selected_text()
  if not selected_text or selected_text == '' then
    vim.notify('No text selected', vim.log.levels.WARN)
    return
  end
  
  local query = string.format(CHAT_TEMPLATES.improve_code, selected_text)
  if ask_copilot(query) then
    ui_utils.show_success('Copilot Chat opened with refactoring request')
  end
end

--- Explain selected code
function M.explain_selection()
  local selected_text = input_utils.get_selected_text()
  if not selected_text or selected_text == '' then
    vim.notify('No text selected', vim.log.levels.WARN)
    return
  end
  
  local query = string.format(CHAT_TEMPLATES.explain_code, selected_text)
  if ask_copilot(query) then
    ui_utils.show_success('Copilot Chat opened with explanation request')
  end
end

--- Optimize selected code
function M.optimize_selection()
  local selected_text = input_utils.get_selected_text()
  if not selected_text or selected_text == '' then
    vim.notify('No text selected', vim.log.levels.WARN)
    return
  end
  
  local query = string.format(CHAT_TEMPLATES.optimize_code, selected_text)
  if ask_copilot(query) then
    ui_utils.show_success('Copilot Chat opened with optimization request')
  end
end

--- Add comments to selected code
function M.add_comments_to_selection()
  local selected_text = input_utils.get_selected_text()
  if not selected_text or selected_text == '' then
    vim.notify('No text selected', vim.log.levels.WARN)
    return
  end
  
  local query = string.format(CHAT_TEMPLATES.add_comments, selected_text)
  if ask_copilot(query) then
    ui_utils.show_success('Copilot Chat opened with comment request')
  end
end

--- Convert JavaScript to TypeScript
function M.convert_to_typescript()
  local selected_text = input_utils.get_selected_text()
  if not selected_text or selected_text == '' then
    vim.notify('No text selected', vim.log.levels.WARN)
    return
  end
  
  local query = string.format(CHAT_TEMPLATES.convert_to_typescript, selected_text)
  if ask_copilot(query) then
    ui_utils.show_success('Copilot Chat opened with TypeScript conversion request')
  end
end

--- Custom chat with template selection
function M.chat_with_template()
  local selected_text = input_utils.get_selected_text()
  if not selected_text or selected_text == '' then
    vim.notify('No text selected', vim.log.levels.WARN)
    return
  end
  
  local template_options = {
    'Improve/Refactor Code',
    'Explain Code', 
    'Optimize Code',
    'Add Comments',
    'Convert to TypeScript',
    'Custom Query',
  }
  
  ui_utils.safe_select(template_options, {
    prompt = 'Select chat template:',
  }, function(selected_option)
    local query
    
    if selected_option == 'Improve/Refactor Code' then
      query = string.format(CHAT_TEMPLATES.improve_code, selected_text)
    elseif selected_option == 'Explain Code' then
      query = string.format(CHAT_TEMPLATES.explain_code, selected_text)
    elseif selected_option == 'Optimize Code' then
      query = string.format(CHAT_TEMPLATES.optimize_code, selected_text)
    elseif selected_option == 'Add Comments' then
      query = string.format(CHAT_TEMPLATES.add_comments, selected_text)
    elseif selected_option == 'Convert to TypeScript' then
      query = string.format(CHAT_TEMPLATES.convert_to_typescript, selected_text)
    elseif selected_option == 'Custom Query' then
      ui_utils.safe_input({
        prompt = 'Enter your custom query: ',
      }, function(custom_query)
        local final_query = selected_text .. '\n\n' .. custom_query
        ask_copilot(final_query)
      end)
      return
    end
    
    if query and ask_copilot(query) then
      ui_utils.show_success('Copilot Chat opened with ' .. selected_option:lower())
    end
  end)
end



return M
