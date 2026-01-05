-- =============================================================================
-- Link Action Functions
-- Quick access to project-related URLs and external links
-- =============================================================================

local link_utils = require('custom.utils.links')
local git_utils = require('custom.utils.git')
local link_constants = require('custom.constants.links')
local github_utils = require('custom.utils.github')
local array_utils = require('custom.utils.array')
local language_utils = require('custom.utils.language')
local file_utils = require('custom.utils.files')
local ui_utils = require('custom.utils.ui')

local M = {}

-- =============================================================================
-- Private Helper Functions
-- =============================================================================

--- Get organization names from environment
---@return table org_names List of organization names
local function get_organization_names()
  local orgs = { 
    vim.env.PRI_GITHUB_USERNAME
  }
  
  -- Filter out nil/empty values
  local valid_orgs = {}
  for _, org in ipairs(orgs) do
    if org and org ~= '' then
      table.insert(valid_orgs, org)
    end
  end
  
  return valid_orgs
end

--- Get project names list with current repo
---@return table project_names Combined list of project names
local function get_project_names_with_current()
  local project_names = {}
  local current_repo = github_utils.getRepoName()
  
  if current_repo and current_repo ~= '' then
    array_utils.tableMerge({ current_repo }, link_constants.projectNames or {}, project_names)
  else
    project_names = link_constants.projectNames or {}
  end
  
  return project_names
end

--- Open URL with error handling
---@param url string URL to open
---@param description? string Description for user feedback
local function open_url_safe(url, description)
  if not url or url == '' then
    vim.notify('Invalid URL', vim.log.levels.ERROR)
    return
  end
  
  file_utils.open(url)
  if description then
    ui_utils.show_success('Opened: ' .. description)
  end
end

-- =============================================================================
-- GitHub Repository Operations
-- =============================================================================

--- Open GitHub repository with organization selection
function M.open_github_repo()
  local current_repo = github_utils.getRepoName()
  if not current_repo or current_repo == '' then
    vim.notify('Could not determine current repository', vim.log.levels.WARN)
    return
  end
  
  local project_names = get_project_names_with_current()
  
  -- If current repo is not in known projects, prompt for organization
  if not array_utils.hasValue(link_constants.projectNames or {}, current_repo) then
    local org_names = get_organization_names()
    
    if #org_names == 0 then
      vim.notify('No GitHub organizations configured', vim.log.levels.ERROR)
      return
    end
    
    ui_utils.safe_select(org_names, {
      prompt = 'Select organization/username:',
    }, function(org_name)
      local url = string.format('https://github.com/%s/%s', org_name, current_repo)
      open_url_safe(url, string.format('%s/%s', org_name, current_repo))
    end)
    return
  end

  ui_utils.safe_select(project_names, {
    prompt = 'Select repository to open:',
  }, function(project_name)
    -- Try to open using private GitHub repo logic since ORG_GITHUB_LINK is no longer available
    local github_username = vim.env.PRI_GITHUB_USERNAME
    if github_username then
      local url = string.format('https://github.com/%s/%s', github_username, project_name)
      open_url_safe(url, project_name)
    else
      vim.notify('GitHub username not configured', vim.log.levels.ERROR)
    end
  end)
end

--- Open private GitHub repository
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
  
  local url = github_utils.getRepoUrl(github_username, current_repo)
  open_url_safe(url, string.format('Private repo: %s', current_repo))
end

--- Open current project's GitHub repository
function M.open_current_github_repo()
  -- Get current repository info using gh CLI
  local handle = io.popen('gh repo view --json url 2>/dev/null')
  if not handle then
    vim.notify('Failed to run gh command', vim.log.levels.ERROR)
    return
  end
  
  local output = handle:read('*a')
  handle:close()
  
  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to get repository info. Make sure you are in a git repository and gh CLI is authenticated.', vim.log.levels.ERROR)
    return
  end
  
  local ok, repo_info = pcall(vim.fn.json_decode, output)
  if not ok or not repo_info or not repo_info.url then
    vim.notify('Could not determine repository URL', vim.log.levels.ERROR)
    return
  end
  
  open_url_safe(repo_info.url, 'Current GitHub repository')
end

--- Open current project's GitHub pull requests tab
function M.open_current_github_prs()
  -- Get current repository info using gh CLI
  local handle = io.popen('gh repo view --json url 2>/dev/null')
  if not handle then
    vim.notify('Failed to run gh command', vim.log.levels.ERROR)
    return
  end
  
  local output = handle:read('*a')
  handle:close()
  
  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to get repository info. Make sure you are in a git repository and gh CLI is authenticated.', vim.log.levels.ERROR)
    return
  end
  
  local ok, repo_info = pcall(vim.fn.json_decode, output)
  if not ok or not repo_info or not repo_info.url then
    vim.notify('Could not determine repository URL', vim.log.levels.ERROR)
    return
  end
  
  local pr_url = repo_info.url .. '/pulls'
  open_url_safe(pr_url, 'GitHub pull requests')
end

-- =============================================================================
-- Infrastructure and Environment Links
-- =============================================================================

--- Generic function to open environment-specific links
---@param link_template string Environment variable containing URL template
---@param description string Description for user feedback
local function open_environment_link(link_template, description)
  if not link_template then
    vim.notify(description .. ' link not configured', vim.log.levels.ERROR)
    return
  end
  
  local project_names = get_project_names_with_current()
  
  ui_utils.safe_select(project_names, {
    prompt = 'Select repository for ' .. description:lower() .. ':',
  }, function(project_name)
    local url = string.format(link_template, project_name)
    open_url_safe(url, string.format('%s - %s', description, project_name))
  end)
end

--- Open test environment logs
function M.open_test_logs()
  vim.notify('Test logs functionality not configured', vim.log.levels.WARN)
end

--- Open test environment pods
function M.open_test_pods()
  vim.notify('Test pods functionality not configured', vim.log.levels.WARN)
end

--- Open production logs
function M.open_prod_logs()
  vim.notify('Production logs functionality not configured', vim.log.levels.WARN)
end

--- Open production pods
function M.open_prod_pods()
  vim.notify('Production pods functionality not configured', vim.log.levels.WARN)
end

--- Open container registry
function M.open_container_registry()
  vim.notify('Container registry functionality not configured', vim.log.levels.WARN)
end

-- =============================================================================
-- Server Environment Operations
-- =============================================================================

--- Open development server
function M.open_dev_server()
  language_utils.openServerUrl('dev')
end

--- Open test server
function M.open_test_server()
  language_utils.openServerUrl('test')
end

--- Open production server
function M.open_prod_server()
  language_utils.openServerUrl('prod')
end

-- =============================================================================
-- Utility Links
-- =============================================================================

--- Open useful links from configuration
function M.open_useful_link()
  local link_names = link_constants.usefulLinkNames
  local useful_links = link_constants.usefulLink
  
  if not link_names or #link_names == 0 then
    vim.notify('No useful links configured', vim.log.levels.WARN)
    return
  end
  
  ui_utils.safe_select(link_names, {
    prompt = 'Select link to open:',
  }, function(link_name)
    local url = useful_links[link_name]
    if url then
      open_url_safe(url, link_name)
    else
      vim.notify('Link not found: ' .. link_name, vim.log.levels.ERROR)
    end
  end)
end

-- =============================================================================
-- JIRA Integration
-- =============================================================================

--- Open JIRA ticket from current branch name
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
    open_url_safe(jira_link, 'JIRA ticket: ' .. jira_ticket)
  else
    vim.notify('Could not generate JIRA link for: ' .. jira_ticket, vim.log.levels.ERROR)
  end
end

-- =============================================================================
-- Package Management Links
-- =============================================================================

--- Open NPM package page for word under cursor
function M.open_npm_url()
  -- Save current register
  local old_reg = vim.fn.getreg('"')
  
  -- Yank word under cursor
  vim.cmd('normal! yiW')
  local package_name = vim.fn.getreg('"')
  
  -- Restore register
  vim.fn.setreg('"', old_reg)
  
  if not package_name or package_name == '' then
    vim.notify('No package name under cursor', vim.log.levels.WARN)
    return
  end
  
  -- Clean package name
  package_name = package_name:gsub('["\':,]', '')
  
  local npm_url = link_utils.getNpmUrl(package_name)
  if npm_url then
    open_url_safe(npm_url, 'NPM package: ' .. package_name)
  else
    vim.notify('Could not generate NPM URL for: ' .. package_name, vim.log.levels.ERROR)
  end
end



return M
