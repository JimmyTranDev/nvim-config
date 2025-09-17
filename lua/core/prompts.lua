local M = {}

local function load_prompts()
  local prompts_file = vim.fn.expand('~/Programming/secrets/prompts.json')

  local file = io.open(prompts_file, 'r')
  if not file then
    -- Check if secrets directory exists and provide helpful message
    local storage = require('custom.utils.storage')
    if not storage.secrets_directory_exists() then
      vim.notify('Secrets directory does not exist. Use <Leader>;fI to initialize it.', vim.log.levels.INFO)
    else
      vim.notify('Could not open prompts.json file: ' .. prompts_file, vim.log.levels.WARN)
    end
    return {}
  end

  local content = file:read('*a')
  file:close()

  local ok, prompts = pcall(vim.json.decode, content)
  if not ok then
    vim.notify('Could not parse prompts.json file', vim.log.levels.ERROR)
    return {}
  end

  return prompts
end

local prompts_data = load_prompts()

M.promptRoles = prompts_data.promptRoles or {}
M.newsPrompt = prompts_data.newsPrompt or ''
M.marketStatusPrompt = prompts_data.marketStatusPrompt or ''
M.storyGeneratePrompt = prompts_data.storyGeneratePrompt or ''
M.testIdsPrompt = prompts_data.testIdsPrompt or ''
M.accessibilityImproveReactPrompt = prompts_data.accessibilityImproveReactPrompt or ''
M.langaugePrompt = prompts_data.langaugePrompt or ''
M.copilotFmsPrompt = prompts_data.copilotFmsPrompt or ''

return M
