local linkConstants = require('custom.constants.links')
local urlUtils = require('custom.utils.url')

local M = {}

function M.openUrl(url) vim.cmd('silent !firefox ' .. url) end

function M.getGoogleSearchUrl(query)
  local encodedQuery = urlUtils.urlencode(query)
  return 'https://www.google.com/search?q=' .. encodedQuery
end

function M.getNpmUrl(query)
  local encodedQuery = urlUtils.urlencode(query)
  return 'https://www.npmjs.com/package/' .. encodedQuery
end

function M.getJiraLinkWithTicket(ticket) return linkConstants.jiraTicketUrl .. ticket end

return M
