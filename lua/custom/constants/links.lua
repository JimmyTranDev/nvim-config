local M = {}

M.jiraTicketUrl = vim.env.ORG_JIRA_TICKET_LINK or ''
local jsonUtils = require('custom.utils.json')
local expand = vim.fn.expand

local links = jsonUtils.parse_json_from_file(expand('$HOME/Programming/JimmyTranDev/secrets/links.json'))

M.projectNameToRouteObject = links.work_technical or {}
M.projectNames = {}
for projectName, _ in pairs(M.projectNameToRouteObject) do
  table.insert(M.projectNames, projectName)
end

M.usefulLink = links.work_useful or {}
M.usefulLinkNames = {}
for key in pairs(M.usefulLink) do
  table.insert(M.usefulLinkNames, key)
end

M.privateUsefulLink = links.private_useful or {}
M.privateUsefulLinkNames = {}
for key in pairs(M.privateUsefulLink) do
  table.insert(M.privateUsefulLinkNames, key)
end

return M
