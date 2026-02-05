local urlUtils = require('custom.utils.url')
local fileUtils = require('custom.utils.files')

local M = {}

function M.get_pulls(repo)
  local handle = io.popen('gh pr list --repo ' .. repo .. ' --json number,title,url,state')
  if not handle then return {} end
  local output = handle:read('*a')
  handle:close()
  local ok, json = pcall(vim.fn.json_decode, output)
  if not ok or not json then return {} end
  return json
end

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

  local searchTypes = { 'code', 'issues', 'repositories', 'commits' }
  local orgQuery = ''

  if orgName ~= nil and orgName ~= '' then orgQuery = string.format('org:%s+', orgName) end

  vim.ui.select(searchTypes, {
    prompt = 'Select GitHub search type: ',
  }, function(selected)
    if not selected then return end

    local searchUrl = string.format('https://github.com/search?q=%s%s&type=%s', orgQuery, encodedSearchQuery, selected)

    fileUtils.open(searchUrl)
  end)
end

return M
