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

  -- Load prompts data to get the FMS prompt
  local prompts_data = require('core.prompts')
  local current_file = debug.getinfo(1, 'S').source:sub(2)
  local current_dir = vim.fn.fnamemodify(current_file, ':h:h:h') -- Go up to nvim/lua
  local prompts_file = current_dir .. '/core/prompts.json'

  local file = io.open(prompts_file, 'r')
  local fms_prompt = ''
  if file then
    local content = file:read('*a')
    file:close()

    local ok, json_data = pcall(vim.json.decode, content)
    if ok then fms_prompt = json_data.copilotFmsPrompt or '' end
  end

  local query = selectedText
    .. '\n\n'
    .. fms_prompt
    .. '\n\n'
    .. 'The text above should be replaced with the text below. The text below should be in a code block.\n'
  chat.ask(query)
end

return M
