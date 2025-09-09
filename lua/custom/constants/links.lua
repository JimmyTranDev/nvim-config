local M = {}

M.githubUsername = vim.env.GITHUB_USERNAME
M.jiraTicketUrl = vim.env.JIRA_TICKET_URL
M.companyGithubTeamName = vim.env.GITHUB_ORGANIZATION_NAME
local jsonUtils = require('custom.utils.json')
local expand = vim.fn.expand

M.projectNameToRouteObject = jsonUtils.parse_json_from_file(expand('$HOME/Programming/secrets/technical_links.json'))
M.projectNames = {}
for projectName, _ in pairs(M.projectNameToRouteObject) do
  table.insert(M.projectNames, projectName)
end

M.usefulLink = jsonUtils.parse_json_from_file(expand('$HOME/Programming/secrets/useful_links.json'))
M.usefulLinkNames = {}
for key in pairs(M.usefulLink) do
  table.insert(M.usefulLinkNames, key)
end

M.aiOptions = {
  { name = 'ChatGPT', url = 'https://chatgpt.com/?q=%s', baseUrl = 'https://chatgpt.com' },
  { name = 'Grok', url = 'https://grok.com/?q=%s', baseUrl = 'https://grok.com' },
  { name = 'Claude', url = 'https://claude.ai/new?q=%s', baseUrl = 'https://claude.ai' },
  { name = 'Gemini', url = 'https://gemini.google.com/?q=%s', baseUrl = 'https://gemini.google.com' },
  { name = 'Perplexity', url = 'https://www.perplexity.ai/?q=%s', baseUrl = 'https://www.perplexity.ai' },
}

M.searchOptions = {
  { name = 'Google', url = 'https://www.google.com/search?q=%s', baseUrl = 'https://www.google.com' },
  { name = 'Bing', url = 'https://www.bing.com/search?q=%s', baseUrl = 'https://www.bing.com' },
  { name = 'DuckDuckGo', url = 'https://duckduckgo.com/?q=%s', baseUrl = 'https://duckduckgo.com' },
}

return M
