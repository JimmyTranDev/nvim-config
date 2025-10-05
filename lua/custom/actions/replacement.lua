local M = {}

local inputUtils = require('custom.utils.input')
local stringUtils = require('custom.utils.string')

-- Enhanced replacement function with scope and prefill options
local function replace_with_options(scope, prefill_search, prefill_replace)
  local search_text = ''
  local replace_text = ''
  
  if prefill_search then
    -- Get selected text if in visual mode
    if vim.fn.mode():match('^[vV\x16]') then
      search_text = inputUtils.get_selected_text()
    else
      -- Get word under cursor
      search_text = vim.fn.expand('<cword>')
    end
  end
  
  if prefill_replace then
    replace_text = search_text -- Start with search text as default replacement
  end
  
  -- Get search pattern
  local search_input = vim.fn.input({
    prompt = 'Search for: ',
    default = search_text,
    completion = 'command'
  })
  
  if search_input == '' then
    vim.notify('No search text provided!', vim.log.levels.WARN)
    return
  end
  
  -- Get replacement text
  local replace_input = vim.fn.input({
    prompt = 'Replace with: ',
    default = replace_text,
    completion = 'command'
  })
  
  if replace_input == nil then
    vim.notify('Replacement cancelled', vim.log.levels.WARN)
    return
  end
  
  -- Escape patterns for safe replacement
  local escaped_search = stringUtils.escape_pattern(search_input)
  local escaped_replace = stringUtils.escape_pattern(replace_input)
  
  -- Build command based on scope
  local cmd = ''
  local scope_desc = ''
  
  if scope == 'buffer' then
    cmd = string.format('%%s/%s/%s/gc', escaped_search, escaped_replace)
    scope_desc = 'current buffer'
  elseif scope == 'buffer_all' then
    cmd = string.format('%%s/%s/%s/g', escaped_search, escaped_replace)
    scope_desc = 'current buffer (all occurrences)'
  elseif scope == 'quickfix' then
    cmd = string.format('cdo s/%s/%s/gc | update', escaped_search, escaped_replace)
    scope_desc = 'quickfix list'
  elseif scope == 'quickfix_all' then
    cmd = string.format('cdo s/%s/%s/g | update', escaped_search, escaped_replace)
    scope_desc = 'quickfix list (all occurrences)'
  elseif scope == 'project' then
    cmd = string.format('cfdo %%s/%s/%s/gc | update', escaped_search, escaped_replace)
    scope_desc = 'project files'
  elseif scope == 'project_all' then
    cmd = string.format('cfdo %%s/%s/%s/g | update', escaped_search, escaped_replace)
    scope_desc = 'project files (all occurrences)'
  end
  
  -- Execute the replacement
  local success, error_msg = pcall(vim.cmd, cmd)
  
  if success then
    vim.notify(
      string.format('Replaced "%s" with "%s" in %s', search_input, replace_input, scope_desc),
      vim.log.levels.INFO
    )
  else
    vim.notify(
      string.format('Replacement failed: %s', error_msg),
      vim.log.levels.ERROR
    )
  end
end

-- Quick replacement functions for different scopes

-- Buffer replacements (with confirmation)
function M.replace_buffer()
  replace_with_options('buffer', false, false)
end

function M.replace_buffer_prefilled()
  replace_with_options('buffer', true, false)
end

function M.replace_buffer_selected()
  if not vim.fn.mode():match('^[vV\x16]') then
    vim.notify('Must be in visual mode!', vim.log.levels.ERROR)
    return
  end
  replace_with_options('buffer', true, false)
end

-- Buffer replacements (all occurrences, no confirmation)
function M.replace_buffer_all()
  replace_with_options('buffer_all', false, false)
end

function M.replace_buffer_all_prefilled()
  replace_with_options('buffer_all', true, false)
end

function M.replace_buffer_all_selected()
  if not vim.fn.mode():match('^[vV\x16]') then
    vim.notify('Must be in visual mode!', vim.log.levels.ERROR)
    return
  end
  replace_with_options('buffer_all', true, false)
end

-- Quickfix list replacements (with confirmation)
function M.replace_quickfix()
  if vim.fn.empty(vim.fn.getqflist()) == 1 then
    vim.notify('Quickfix list is empty! Use :grep or :vimgrep first.', vim.log.levels.WARN)
    return
  end
  replace_with_options('quickfix', false, false)
end

function M.replace_quickfix_prefilled()
  if vim.fn.empty(vim.fn.getqflist()) == 1 then
    vim.notify('Quickfix list is empty! Use :grep or :vimgrep first.', vim.log.levels.WARN)
    return
  end
  replace_with_options('quickfix', true, false)
end

-- Quickfix list replacements (all occurrences, no confirmation)
function M.replace_quickfix_all()
  if vim.fn.empty(vim.fn.getqflist()) == 1 then
    vim.notify('Quickfix list is empty! Use :grep or :vimgrep first.', vim.log.levels.WARN)
    return
  end
  replace_with_options('quickfix_all', false, false)
end

function M.replace_quickfix_all_prefilled()
  if vim.fn.empty(vim.fn.getqflist()) == 1 then
    vim.notify('Quickfix list is empty! Use :grep or :vimgrep first.', vim.log.levels.WARN)
    return
  end
  replace_with_options('quickfix_all', true, false)
end

-- Project-wide replacements (with confirmation)
function M.replace_project()
  if vim.fn.empty(vim.fn.getqflist()) == 1 then
    vim.notify('Quickfix list is empty! Use :grep or :vimgrep first.', vim.log.levels.WARN)
    return
  end
  replace_with_options('project', false, false)
end

function M.replace_project_prefilled()
  if vim.fn.empty(vim.fn.getqflist()) == 1 then
    vim.notify('Quickfix list is empty! Use :grep or :vimgrep first.', vim.log.levels.WARN)
    return
  end
  replace_with_options('project', true, false)
end

-- Project-wide replacements (all occurrences, no confirmation)
function M.replace_project_all()
  if vim.fn.empty(vim.fn.getqflist()) == 1 then
    vim.notify('Quickfix list is empty! Use :grep or :vimgrep first.', vim.log.levels.WARN)
    return
  end
  replace_with_options('project_all', false, false)
end

function M.replace_project_all_prefilled()
  if vim.fn.empty(vim.fn.getqflist()) == 1 then
    vim.notify('Quickfix list is empty! Use :grep or :vimgrep first.', vim.log.levels.WARN)
    return
  end
  replace_with_options('project_all', true, false)
end

-- Interactive replacement with scope selection
function M.replace_interactive()
  local scopes = {
    { name = 'Current Buffer (confirm each)', value = 'buffer' },
    { name = 'Current Buffer (all)', value = 'buffer_all' },
    { name = 'Quickfix List (confirm each)', value = 'quickfix' },
    { name = 'Quickfix List (all)', value = 'quickfix_all' },
    { name = 'Project Files (confirm each)', value = 'project' },
    { name = 'Project Files (all)', value = 'project_all' },
  }
  
  vim.ui.select(scopes, {
    prompt = 'Select replacement scope:',
    format_item = function(item) return item.name end,
  }, function(choice)
    if choice then
      local prefill = vim.fn.mode():match('^[vV\x16]') or vim.fn.expand('<cword>') ~= ''
      replace_with_options(choice.value, prefill, false)
    end
  end)
end

return M
