local link_utils = require('custom.utils.links')
local git_utils = require('custom.utils.git')
local link_constants = require('custom.constants.links')
local language_utils = require('custom.utils.language')
local file_utils = require('custom.utils.files')
local github_utils = require('custom.utils.github')
local ui_utils = require('custom.utils.ui')
local url_utils = require('custom.utils.url')

local M = {}

local function open_url(url, description)
  if not url or url == '' then
    vim.notify('Invalid URL', vim.log.levels.ERROR)
    return
  end
  file_utils.open(url)
  if description then vim.notify('Opened: ' .. description, vim.log.levels.INFO) end
end

function M.open_current_github_repo()
  local repo_info = github_utils.get_repo_info()
  if not repo_info or not repo_info.url then
    vim.notify('Failed to get repository info. Make sure you are in a git repository and gh CLI is authenticated.', vim.log.levels.ERROR)
    return
  end
  open_url(repo_info.url, 'Current GitHub repository')
end

function M.open_current_github_prs()
  local repo_info = github_utils.get_repo_info()
  if not repo_info or not repo_info.url then
    vim.notify('Failed to get repository info. Make sure you are in a git repository and gh CLI is authenticated.', vim.log.levels.ERROR)
    return
  end
  open_url(repo_info.url .. '/pulls', 'GitHub pull requests')
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

function M.open_private_useful_link()
  local link_names = link_constants.privateUsefulLinkNames
  local private_useful_links = link_constants.privateUsefulLink

  if not link_names or #link_names == 0 then
    vim.notify('No private useful links configured', vim.log.levels.WARN)
    return
  end

  ui_utils.safe_select(link_names, { prompt = 'Select private link to open:' }, function(link_name)
    local url = private_useful_links[link_name]
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

function M.search_google()
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\22' then
    vim.cmd('normal! "zy')
    local text = vim.fn.getreg('z')
    if text and text ~= '' then
      local encoded = url_utils.urlencode(text)
      file_utils.open('https://www.google.com/search?q=' .. encoded)
      return
    end
  end

  vim.ui.input({ prompt = 'Google: ' }, function(input)
    if not input or input == '' then return end
    local encoded = url_utils.urlencode(input)
    file_utils.open('https://www.google.com/search?q=' .. encoded)
  end)
end

function M.open_firefox_container()
  vim.ui.input({ prompt = 'Container name: ' }, function(container)
    if not container or container == '' then return end

    vim.ui.input({ prompt = 'URL: ' }, function(url)
      if not url or url == '' then return end

      local encoded_url = url_utils.urlencode(url)
      local container_url = string.format('ext+container:name=%s&url=%s', url_utils.urlencode(container), encoded_url)
      vim.fn.system({ 'open', '-a', 'Firefox', container_url })
      vim.notify(string.format('Opened in Firefox [%s]: %s', container, url), vim.log.levels.INFO)
    end)
  end)
end

return M
