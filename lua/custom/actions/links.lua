local linkUtils = require('custom.utils.links')
local gitUtils = require('custom.utils.git')
local linkConstants = require('custom.constants.links')
local githubUtils = require('custom.utils.github')
local arrayUtils = require('custom.utils.array')
local languageUtils = require('custom.utils.language')
local fileUtils = require('custom.utils.files')

local M = {}

function M.openGithubRepo()
  local projectNames = {}
  local currentRepoName = githubUtils.getRepoName()

  arrayUtils.tableMerge({ currentRepoName }, linkConstants.projectNames, projectNames)

  if not arrayUtils.hasValue(linkConstants.projectNames, currentRepoName) then
    local orgnizationNames = { vim.env.PRI_GITHUB_USERNAME, vim.env.ORG_GITHUB_NAME, vim.env.ORG_GITHUB_DESIGN_NAME }
    vim.ui.select(orgnizationNames, {
      prompt = 'Select organization/username:',
    }, function(orgName)
      if orgName == nil or orgName == '' then return end

      local url = 'https://github.com/' .. orgName .. '/' .. currentRepoName
      fileUtils.open(url)
    end)
    return
  end

  vim.ui.select(projectNames, {
    prompt = 'Select repo to open:',
  }, function(projectName)
    if projectName == nil or projectName == '' then return end

    local url = string.format(vim.env.ORG_GITHUB_LINK, projectName)
    fileUtils.open(url)
  end)
end

function M.openTestLogs()
  local projectNames = {}
  arrayUtils.tableMerge({ githubUtils.getRepoName() }, linkConstants.projectNames, projectNames)
  vim.ui.select(projectNames, {
    prompt = 'Select repo to open:',
  }, function(projectName)
    if projectName == nil then return end
    local url = string.format(vim.env.ORG_TEST_LOGS_LINK, projectName)
    fileUtils.open(url)
  end)
end

function M.openTestPods()
  local projectNames = {}
  arrayUtils.tableMerge({ githubUtils.getRepoName() }, linkConstants.projectNames, projectNames)
  vim.ui.select(projectNames, {
    prompt = 'Select repo to open:',
  }, function(projectName)
    if projectName == nil then return end

    local url = string.format(vim.env.ORG_TEST_PODS_LINK, projectName)

    fileUtils.open(url)
  end)
end

function M.openProdLogs()
  local projectNames = {}
  arrayUtils.tableMerge({ githubUtils.getRepoName() }, linkConstants.projectNames, projectNames)
  vim.ui.select(projectNames, {
    prompt = 'Select repo to open:',
  }, function(projectName)
    if projectName == nil then return end
    local url = string.format(vim.env.ORG_PROD_LOGS_LINK, projectName)
    fileUtils.open(url)
  end)
end

function M.openProdPods()
  local projectNames = {}
  arrayUtils.tableMerge({ githubUtils.getRepoName() }, linkConstants.projectNames, projectNames)
  vim.ui.select(projectNames, {
    prompt = 'Select repo to open:',
  }, function(projectName)
    if projectName == nil then return end
    local url = string.format(vim.env.ORG_PROD_PODS_LINK, projectName)

    fileUtils.open(url)
  end)
end

function M.openContainerRegistry()
  local projectNames = {}
  arrayUtils.tableMerge({ githubUtils.getRepoName() }, linkConstants.projectNames, projectNames)
  vim.ui.select(projectNames, {
    prompt = 'Select repo to open:',
  }, function(projectName)
    if projectName == nil then return end
    local url = string.format(vim.env.ORG_CONTAINER_REGISTRY_LINK, projectName)
    fileUtils.open(url)
  end)
end

function M.openDevServer() languageUtils.openServerUrl('dev') end

function M.openTestServer() languageUtils.openServerUrl('test') end

function M.openProdServer() languageUtils.openServerUrl('prod') end

function M.openUsefulLink()
  vim.ui.select(linkConstants.usefulLinkNames, {
    prompt = 'Select link to open:',
  }, function(linkName)
    if linkName == nil then return end
    if linkName == '' then return end

    fileUtils.open(linkConstants.usefulLink[linkName])
  end)
end

function M.openGithubUrlPrivate()
  local githubUsername = linkConstants.githubUsername
  local currentRepoName = githubUtils.getRepoName()
  if currentRepoName == nil then
    vim.notify('Git remote origin not found')
    return
  end
  local currentRepoUrl = githubUtils.getRepoUrl(githubUsername, currentRepoName)
  fileUtils.open(currentRepoUrl)
end

function M.openJiraTicket()
  local branchName = gitUtils.getCurrentBranchName()
  local jiraTicket = gitUtils.getJiraTicket(branchName)
  if jiraTicket == '' then
    vim.notify('No Jira ticket found in branch name')
    return
  end

  local jiraLink = linkUtils.getJiraLinkWithTicket(jiraTicket)
  fileUtils.open(jiraLink)
end



function M.openNpmUrl()
  vim.cmd('normal! yiW')
  local selectedText = vim.fn.getreg('"')
  selectedText = selectedText:gsub('"', ''):gsub(':', '')
  local url = linkUtils.getNpmUrl(selectedText)
  fileUtils.open(url)
end

return M
