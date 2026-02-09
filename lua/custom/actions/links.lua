local link_utils = require('custom.utils.links')
local git_utils = require('custom.utils.git')
local link_constants = require('custom.constants.links')
local github_utils = require('custom.utils.github')
local array_utils = require('custom.utils.array')
local language_utils = require('custom.utils.language')
local file_utils = require('custom.utils.files')
local ui_utils = require('custom.utils.ui')

local M = {}

local function get_project_names_with_current()
  local current_repo = github_utils.getRepoName()
  if current_repo and current_repo ~= '' then
    local result = {}
    array_utils.tableMerge({ current_repo }, link_constants.projectNames or {}, result)
    return result
  end
  return link_constants.projectNames or {}
end

local function open_url(url, description)
  if not url or url == '' then
    vim.notify('Invalid URL', vim.log.levels.ERROR)
    return
  end
  file_utils.open(url)
  if description then vim.notify('Opened: ' .. description, vim.log.levels.INFO) end
end

local function get_current_repo_url()
  local output = vim.fn.system('gh repo view --json url 2>/dev/null')
  if vim.v.shell_error ~= 0 then return nil end

  local ok, repo_info = pcall(vim.fn.json_decode, output)
  if ok and repo_info and repo_info.url then return repo_info.url end
  return nil
end

function M.open_private_github_repo()
  local github_username = link_constants.githubUsername
  local current_repo = github_utils.getRepoName()

  if not current_repo then
    vim.notify('Git remote origin not found', vim.log.levels.WARN)
    return
  end

  if not github_username then
    vim.notify('GitHub username not configured', vim.log.levels.ERROR)
    return
  end

  open_url(github_utils.getRepoUrl(github_username, current_repo), 'Private repo: ' .. current_repo)
end

function M.open_current_github_repo()
  local url = get_current_repo_url()
  if not url then
    vim.notify('Failed to get repository info. Make sure you are in a git repository and gh CLI is authenticated.', vim.log.levels.ERROR)
    return
  end
  open_url(url, 'Current GitHub repository')
end

function M.open_current_github_prs()
  local url = get_current_repo_url()
  if not url then
    vim.notify('Failed to get repository info. Make sure you are in a git repository and gh CLI is authenticated.', vim.log.levels.ERROR)
    return
  end
  open_url(url .. '/pulls', 'GitHub pull requests')
end

function M.open_dev_server() language_utils.openServerUrl('dev') end

function M.open_useful_link()
  local link_names = link_constants.usefulLinkNames
  local useful_links = link_constants.usefulLink

  if not link_names or #link_names == 0 then
    vim.notify('No useful links configured', vim.log.levels.WARN)
    return
  end

  ui_utils.safe_select(link_names, { prompt = 'Select link to open:' }, function(link_name)
    local url = useful_links[link_name]
    if url then
      open_url(url, link_name)
    else
      vim.notify('Link not found: ' .. link_name, vim.log.levels.ERROR)
    end
  end)
end

function M.open_jira_ticket()
  local branch_name = git_utils.get_current_branch()
  if not branch_name or branch_name == '' then
    vim.notify('Not in a git repository or no branch found', vim.log.levels.WARN)
    return
  end

  local jira_ticket = git_utils.extract_jira_ticket(branch_name)
  if not jira_ticket or jira_ticket == '' then
    vim.notify('No JIRA ticket found in branch name: ' .. branch_name, vim.log.levels.WARN)
    return
  end

  local jira_link = link_utils.getJiraLinkWithTicket(jira_ticket)
  if jira_link then
    open_url(jira_link, 'JIRA ticket: ' .. jira_ticket)
  else
    vim.notify('Could not generate JIRA link for: ' .. jira_ticket, vim.log.levels.ERROR)
  end
end

function M.open_npm_url()
  local old_reg = vim.fn.getreg('"')
  vim.cmd('normal! yiW')
  local package_name = vim.fn.getreg('"')
  vim.fn.setreg('"', old_reg)

  if not package_name or package_name == '' then
    vim.notify('No package name under cursor', vim.log.levels.WARN)
    return
  end

  package_name = package_name:gsub('["\':,]', '')
  local npm_url = link_utils.getNpmUrl(package_name)
  if npm_url then
    open_url(npm_url, 'NPM package: ' .. package_name)
  else
    vim.notify('Could not generate NPM URL for: ' .. package_name, vim.log.levels.ERROR)
  end
end

return M
