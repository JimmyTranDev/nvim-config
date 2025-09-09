local urlUtils = require('custom.utils.url')
local fileUtils = require('custom.utils.files')

local M = {}

function M.getRepoName()
  local fullUrl = vim.fn.system('git config --get remote.origin.url')
  local repoName = string.match(fullUrl, '.*/(.*)%.git')
  return repoName
end

function M.getRepoUrl(githubUsername, repoName)
  local url = 'https://github.com/' .. githubUsername .. '/' .. repoName
  return url
end

function M.searchGithub(orgName, searchQuery)
  local encodedSearchQuery = urlUtils.urlencode(searchQuery)

  -- Define search type options
  local searchTypes = { 'code', 'issues', 'repositories', 'commits' }
  local orgQuery = ''

  if orgName ~= nil and orgName ~= '' then orgQuery = string.format('org:%s+', orgName) end

  -- Use vim.ui.select to prompt user for search type
  vim.ui.select(searchTypes, {
    prompt = 'Select GitHub search type: ',
  }, function(selected)
    if not selected then
      return -- User cancelled, exit
    end

    -- Construct the search URL with the selected type
    local searchUrl = string.format('https://github.com/search?q=%s%s&type=%s', orgQuery, encodedSearchQuery, selected)

    -- Open the URL in the browser
    fileUtils.open(searchUrl)
  end)
end

return M
