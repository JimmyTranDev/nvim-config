local linkConstants = require('custom.constants.links')
local urlUtils = require('custom.utils.url')

local M = {}

function M.getGoogleSearchUrl(query)
  return 'https://www.google.com/search?q=' .. urlUtils.urlencode(query)
end

function M.getNpmUrl(query)
  return 'https://www.npmjs.com/package/' .. urlUtils.urlencode(query)
end

function M.getJiraLinkWithTicket(ticket) return linkConstants.jiraTicketUrl .. ticket end

return M
