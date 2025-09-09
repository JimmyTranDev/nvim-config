local inputUtils = require('custom.utils.input')
local linkConstants = require('custom.constants.links')
local fileUtils = require('custom.utils.files')
local urlUtils = require('custom.utils.url')

local M = {}

function M.getPrompt(initialQuery)
  local query = initialQuery or inputUtils.getInputFromUser('Enter your query: ')
  local prompt = query

  local mode = vim.api.nvim_get_mode().mode
  if mode == 'v' or mode == 'V' then
    vim.notify('Visual mode detected, using selected text as prompt.', vim.log.levels.INFO)
    local selectedText = inputUtils.getSelectedTextPure()
    prompt = selectedText .. query
  end
  return prompt
end

function M.handlePrompt(prompt)
  local promptTokenCount = vim.fn.wordcount().words
  if promptTokenCount > 100000 then
    vim.fn.setreg('+', prompt)
    vim.notify('Prompt copied to clipboard: ' .. prompt, vim.log.levels.INFO)
    return
  end

  vim.ui.select(linkConstants.aiOptions, {
    prompt = 'Select AI or Search Engine: ',
    format_item = function(item) return item.name end,
  }, function(choice)
    if choice then
      local url = string.format(choice.url, urlUtils.urlencode(prompt))
      fileUtils.open(url)
    end
  end)
end

return M
