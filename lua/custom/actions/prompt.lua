local M = {}

local linkConstants = require('custom.constants.links')
local githubUtils = require('custom.utils.github')
local inputUtils = require('custom.utils.input')
local fileUtils = require('custom.utils.files')
local errorsUtils = require('custom.utils.errors')
local vimUtils = require('custom.utils.vim')
local prompts = require('core.prompts')
local promptUtils = require('custom.utils.prompt')

function M.getDiagnosticPrompt(hasContext)
  return function()
    local diagnostics = errorsUtils.getDiagnosticTextsUnderCursor()
    if hasContext then
      local folderContent = fileUtils.getRecusriveFileContents()
      local prompt = folderContent .. '\n\n' .. diagnostics .. '\n\nPlease fix these errors'
      promptUtils.handlePrompt(prompt)
    else
      local prompt = diagnostics .. '\n\nPlease fix these errors.\n\n'
      promptUtils.handlePrompt(prompt)
    end
  end
end

function M.openAiChat()
  return function()
    vim.ui.select(linkConstants.aiOptions, {
      prompt = 'Select AI or Search Engine: ',
      format_item = function(item) return item.name end,
    }, function(choice)
      if choice then fileUtils.open(choice.baseUrl) end
    end)
  end
end

function M.folderPrompt(initialQuery)
  return function()
    local query = initialQuery or inputUtils.getInputFromUser('Enter your query: ')
    local prompt = fileUtils.getRecusriveFileContents() .. query

    promptUtils.handlePrompt(prompt)
  end
end

function M.promptNews()
  local countries = { 'Norway', 'Japan', 'Vietnam', 'Hong Kong', 'Korea' }
  return function()
    vim.ui.select(countries, {
      prompt = 'Select country for news prompt: ',
    }, function(country)
      if country then
        local newsPrompt = string.format(prompts.newsPrompt, country)
        promptUtils.handlePrompt(newsPrompt)
      end
    end)
  end
end

function M.promptRole(promptOptions, hasContext)
  return function()
    local selectedText = vimUtils.getSelectedTextIfVisualMode()
    vim.ui.select(promptOptions, {
      prompt = 'Select prompt: ',
      format_item = function(item) return item.name end,
    }, function(option)
      if option then
        local inputText = inputUtils.getInputFromUser('What do you want to do?: ')
        if hasContext then
          local folderContent = fileUtils.getRecusriveFileContents()
          local fullPrompt = folderContent .. '\n\n' .. option.value .. selectedText .. '\n\n' .. inputText
          promptUtils.handlePrompt(fullPrompt)
        else
          local fullPrompt = option.value .. selectedText .. '\n\n' .. inputText
          promptUtils.handlePrompt(fullPrompt)
        end
      end
    end)
  end
end

function M.prompt(query, hasContext)
  return function()
    local updatedQuery = query
    if not query then updatedQuery = inputUtils.getInputFromUser('Enter your query: ') end
    local selectedText = vimUtils.getSelectedTextIfVisualMode()

    if hasContext then
      local folderContent = fileUtils.getRecusriveFileContents()
      local prompt = folderContent .. '\n\n' .. updatedQuery
      promptUtils.handlePrompt(prompt)
    else
      local prompt = selectedText .. '\n\n' .. updatedQuery
      promptUtils.handlePrompt(prompt)
    end
  end
end

function M.searchGithub(orgName)
  return function()
    local mode = vim.api.nvim_get_mode().mode
    local query

    if mode == 'n' then
      query = inputUtils.getInputFromUser('Search GitHub: ')
    elseif mode:match('v') then
      query = inputUtils.getSelectedText()
    end

    if query then githubUtils.searchGithub(orgName, query) end
  end
end

-- Search engine query with prompt
function M.querySearchEngine(initialQuery)
  return function()
    local prompt = promptUtils.getPrompt(initialQuery)
    promptUtils.openWithPrompt(prompt, linkConstants.searchOptions)
  end
end

return M
