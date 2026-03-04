local linkConstants = require('custom.constants.links')
local urlUtils = require('custom.utils.url')

local M = {}

function M.getNpmUrl(query)
  return 'https://www.npmjs.com/package/' .. urlUtils.urlencode(query)
end

function M.getJiraLinkWithTicket(ticket)
  if not linkConstants.jiraTicketUrl or linkConstants.jiraTicketUrl == '' then
    vim.notify('ORG_JIRA_TICKET_LINK not set', vim.log.levels.ERROR)
    return nil
  end
  return linkConstants.jiraTicketUrl .. ticket
end

return M
