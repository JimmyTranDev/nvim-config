local inputUtils = require('custom.utils.input')
local prompts = require('core.prompts')

local M = {}

function M.copilotChatFixErrorUnderCursor()
  local errorText = require('custom.actions.errors').getDiagnosticUnderCursor()
  if not errorText or errorText == '' then
    vim.notify('No error under cursor', vim.log.levels.WARN)
    return
  end
  local chat = require('CopilotChat')
  chat.open()
  local query = 'Fix the following error in my code:\n' .. errorText
  chat.ask(query)
end

function M.copilotChatSelected()
  local selectedText = inputUtils.getSelectedTextPure()
  local queryText = inputUtils.getInputFromUser('Query: ')

  if queryText == '' then return end

  local chat = require('CopilotChat')
  chat.open()
  local query = selectedText .. ' \n' .. queryText
  chat.ask(query)
end

function M.copilotChatFms()
  local selectedText = inputUtils.getSelectedTextPure()

  local chat = require('CopilotChat')
  chat.open()
  local query = selectedText
    .. '\n\n'
    .. 'Please improve or refactor the text above. The result should be in a code block.\n'
  chat.ask(query)
end

return M
