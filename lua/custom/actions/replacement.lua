-- =============================================================================
-- Replacement Action Functions
-- Text replacement utilities with various scopes and options
-- =============================================================================

local input_utils = require('custom.utils.input')
local string_utils = require('custom.utils.string')
local ui_utils = require('custom.utils.ui')
local validation = require('custom.utils.validation')

local M = {}

-- =============================================================================
-- Configuration
-- =============================================================================

local REPLACEMENT_SCOPES = {
  buffer = {
    cmd_pattern = '%%s/%s/%s/gc',
    description = 'current buffer',
  },
  buffer_all = {
    cmd_pattern = '%%s/%s/%s/g',
    description = 'current buffer (all occurrences)',
  },
  quickfix = {
    cmd_pattern = 'cdo s/%s/%s/gc | update',
    description = 'quickfix list',
    requires_quickfix = true,
  },
  quickfix_all = {
    cmd_pattern = 'cdo s/%s/%s/g | update',
    description = 'quickfix list (all occurrences)',
    requires_quickfix = true,
  },
  project = {
    cmd_pattern = 'cfdo %%s/%s/%s/gc | update',
    description = 'project files',
    requires_quickfix = true,
  },
  project_all = {
    cmd_pattern = 'cfdo %%s/%s/%s/g | update',
    description = 'project files (all occurrences)',
    requires_quickfix = true,
  },
}

local INTERACTIVE_SCOPES = {
  { name = 'Current Buffer (confirm each)', value = 'buffer' },
  { name = 'Current Buffer (all)', value = 'buffer_all' },
  { name = 'Quickfix List (confirm each)', value = 'quickfix' },
  { name = 'Quickfix List (all)', value = 'quickfix_all' },
  { name = 'Project Files (confirm each)', value = 'project' },
  { name = 'Project Files (all)', value = 'project_all' },
}

-- =============================================================================
-- Private Helper Functions
-- =============================================================================

--- Check if quickfix list is available and populated
---@return boolean has_quickfix True if quickfix list has entries
local function has_quickfix_entries()
  return vim.fn.empty(vim.fn.getqflist()) == 0
end

--- Get text for search prefill based on current mode
---@return string text Text to prefill search field
local function get_prefill_text()
  if vim.fn.mode():match('^[vV\x16]') then
    return input_utils.get_selected_text() or ''
  else
    return vim.fn.expand('<cword>')
  end
end

--- Get user input for search and replace text
---@param prefill_search boolean Whether to prefill search field
---@param prefill_replace boolean Whether to prefill replace field
---@return table|nil inputs Table with search and replace text, or nil if cancelled
local function get_replacement_inputs(prefill_search, prefill_replace)
  local search_text = prefill_search and get_prefill_text() or ''
  local replace_text = prefill_replace and search_text or ''
  
  local search_input = vim.fn.input({
    prompt = 'Search for: ',
    default = search_text,
    completion = 'command'
  })
  
  if not validation.is_non_empty_string(search_input) then
    vim.notify('No search text provided!', vim.log.levels.WARN)
    return nil
  end
  
  local replace_input = vim.fn.input({
    prompt = 'Replace with: ',
    default = replace_text,
    completion = 'command'
  })
  
  if replace_input == nil then
    vim.notify('Replacement cancelled', vim.log.levels.WARN)
    return nil
  end
  
  return {
    search = search_input,
    replace = replace_input,
  }
end

--- Build replacement command for given scope
---@param scope string Replacement scope
---@param search_text string Text to search for
---@param replace_text string Text to replace with
---@return string|nil command Vim command or nil if invalid scope
local function build_replacement_command(scope, search_text, replace_text)
  local scope_config = REPLACEMENT_SCOPES[scope]
  if not scope_config then
    vim.notify('Invalid replacement scope: ' .. tostring(scope), vim.log.levels.ERROR)
    return nil
  end
  
  local escaped_search = string_utils.escape_pattern(search_text)
  local escaped_replace = string_utils.escape_pattern(replace_text)
  
  return string.format(scope_config.cmd_pattern, escaped_search, escaped_replace)
end

--- Execute replacement with given options
---@param scope string Replacement scope
---@param prefill_search boolean Whether to prefill search field
---@param prefill_replace boolean Whether to prefill replace field
local function replace_with_options(scope, prefill_search, prefill_replace)
  local scope_config = REPLACEMENT_SCOPES[scope]
  if not scope_config then
    vim.notify('Invalid replacement scope: ' .. tostring(scope), vim.log.levels.ERROR)
    return
  end
  
  -- Check quickfix requirements
  if scope_config.requires_quickfix and not has_quickfix_entries() then
    vim.notify('Quickfix list is empty! Use :grep or :vimgrep first.', vim.log.levels.WARN)
    return
  end
  
  local inputs = get_replacement_inputs(prefill_search, prefill_replace)
  if not inputs then return end
  
  local cmd = build_replacement_command(scope, inputs.search, inputs.replace)
  if not cmd then return end
  
  -- Execute the replacement
  local success, error_msg = pcall(vim.cmd, cmd)
  
  if success then
    ui_utils.show_success(
      string.format('Replaced "%s" with "%s" in %s', inputs.search, inputs.replace, scope_config.description)
    )
  else
    vim.notify(
      string.format('Replacement failed: %s', error_msg),
      vim.log.levels.ERROR
    )
  end
end

-- =============================================================================
-- Public API Functions - Buffer Replacements
-- =============================================================================

--- Replace text in current buffer (with confirmation)
function M.replace_buffer()
  replace_with_options('buffer', false, false)
end

--- Replace text in current buffer with prefilled search
function M.replace_buffer_prefilled()
  replace_with_options('buffer', true, false)
end

--- Replace selected text in current buffer
function M.replace_buffer_selected()
  if not vim.fn.mode():match('^[vV\x16]') then
    vim.notify('Must be in visual mode!', vim.log.levels.ERROR)
    return
  end
  replace_with_options('buffer', true, false)
end

-- =============================================================================
-- Public API Functions - Buffer Replacements (All Occurrences)
-- =============================================================================

--- Replace all occurrences in current buffer (no confirmation)
function M.replace_buffer_all()
  replace_with_options('buffer_all', false, false)
end

--- Replace all occurrences in current buffer with prefilled search
function M.replace_buffer_all_prefilled()
  replace_with_options('buffer_all', true, false)
end

--- Replace all occurrences of selected text in current buffer
function M.replace_buffer_all_selected()
  if not vim.fn.mode():match('^[vV\x16]') then
    vim.notify('Must be in visual mode!', vim.log.levels.ERROR)
    return
  end
  replace_with_options('buffer_all', true, false)
end

-- =============================================================================
-- Public API Functions - Quickfix Replacements
-- =============================================================================

--- Replace text in quickfix list (with confirmation)
function M.replace_quickfix()
  replace_with_options('quickfix', false, false)
end

--- Replace text in quickfix list with prefilled search
function M.replace_quickfix_prefilled()
  replace_with_options('quickfix', true, false)
end

--- Replace all occurrences in quickfix list (no confirmation)
function M.replace_quickfix_all()
  replace_with_options('quickfix_all', false, false)
end

--- Replace all occurrences in quickfix list with prefilled search
function M.replace_quickfix_all_prefilled()
  replace_with_options('quickfix_all', true, false)
end

-- =============================================================================
-- Public API Functions - Project Replacements
-- =============================================================================

--- Replace text in project files (with confirmation)
function M.replace_project()
  replace_with_options('project', false, false)
end

--- Replace text in project files with prefilled search
function M.replace_project_prefilled()
  replace_with_options('project', true, false)
end

--- Replace all occurrences in project files (no confirmation)
function M.replace_project_all()
  replace_with_options('project_all', false, false)
end

--- Replace all occurrences in project files with prefilled search
function M.replace_project_all_prefilled()
  replace_with_options('project_all', true, false)
end

-- =============================================================================
-- Public API Functions - Interactive Replacement
-- =============================================================================

--- Interactive replacement with scope selection
function M.replace_interactive()
  ui_utils.safe_select(INTERACTIVE_SCOPES, {
    prompt = 'Select replacement scope:',
    format_item = function(item) return item.name end,
  }, function(choice)
    if choice then
      local has_prefill = vim.fn.mode():match('^[vV\x16]') or vim.fn.expand('<cword>') ~= ''
      replace_with_options(choice.value, has_prefill, false)
    end
  end)
end

return M
