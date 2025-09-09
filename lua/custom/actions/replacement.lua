local M = {}

local inputUtils = require('custom.utils.input')
local stringUtils = require('custom.utils.string')

function M.replace_text()
  -- Check if in visual mode
  if vim.fn.mode():match('^[vV\x16]') then
    -- Get selected text
    local selected_text = inputUtils.get_selected_text()

    if selected_text == '' then
      vim.notify('No text selected!', vim.log.levels.ERROR)
      return
    end

    -- Escape selected text for pattern matching
    local escaped_selected = stringUtils.escape_string(selected_text)

    -- Prompt for replacement text
    local replace_text = vim.fn.input('Replace with: ')
    if replace_text == '' then
      vim.notify('No replacement text provided!', vim.log.levels.WARN)
      return
    end

    -- Escape replacement text
    local escaped_replace = stringUtils.escape_string(replace_text)

    -- Perform replacement across entire file
    vim.cmd(string.format('%%s/%s/%s/g', escaped_selected, escaped_replace))

    vim.notify(string.format('Replaced "%s" with "%s"', selected_text, replace_text), vim.log.levels.INFO)
  else
    vim.notify('Must be in visual mode to select text!', vim.log.levels.ERROR)
  end
end

function M.replace_text_cdo()
  -- Yank the visually selected text
  vim.api.nvim_command('normal! "zy')
  local selected_text = vim.fn.getreg('z')

  if selected_text == '' then
    vim.api.nvim_echo({ { 'No text selected', 'ErrorMsg' } }, true, {})
    return
  end

  -- Escape the selected text for pattern matching
  local escaped_selected = stringUtils.escape_pattern(selected_text)

  -- Prompt for replacement text
  local replacement_text = vim.fn.input('Replace with: ')
  if replacement_text == nil then
    vim.api.nvim_echo({ { 'Replacement cancelled', 'WarningMsg' } }, true, {})
    return
  end

  -- Escape the replacement text
  local escaped_replacement = stringUtils.escape_pattern(replacement_text)

  -- Perform the replacement using cdo
  local cmd = string.format('cdo s/%s/%s/g | update', escaped_selected, escaped_replacement)
  vim.api.nvim_command(cmd)

  vim.api.nvim_echo({ { string.format('Replaced "%s" with "%s"', selected_text, replacement_text), 'Normal' } }, true, {})
end

return M
