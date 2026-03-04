local M = {}

M.jiraTicketUrl = vim.env.ORG_JIRA_TICKET_LINK or ''
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

return M
