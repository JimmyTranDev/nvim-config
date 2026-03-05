local github_utils = require('custom.utils.github')
local file_utils = require('custom.utils.files')

local M = {}

local function format_pr_display(pr) return string.format('#%d %s [%s]', pr.number, pr.title, pr.state) end

local function select_and_open_pr_from_list(pulls, context_name)
  if #pulls == 0 then
    vim.notify('No PRs found in ' .. context_name, vim.log.levels.INFO)
    return
  end

  local pr_options = {}
  for _, pr in ipairs(pulls) do
    table.insert(pr_options, format_pr_display(pr))
  end

  vim.ui.select(pr_options, {
    prompt = 'Select PR to open:',
  }, function(selected_display)
    if not selected_display then return end

    for _, pr in ipairs(pulls) do
      if selected_display:find('#' .. pr.number) then
        file_utils.open(pr.url)
        vim.notify('Opened PR #' .. pr.number .. ' in browser', vim.log.levels.INFO)
        return
      end
    end
  end)
end

function M.create_draft_pr()
  local result = vim.fn.system('gh pr create --draft --web 2>&1')

  if vim.v.shell_error == 0 then
    vim.notify('Draft PR created and opened in browser', vim.log.levels.INFO)
  else
    vim.notify('Failed to create draft PR: ' .. result, vim.log.levels.ERROR)
  end
end

function M.open_current_repo_prs()
  local repo_info = github_utils.get_repo_info()
  if not repo_info or not repo_info.owner or not repo_info.name then
    vim.notify('Could not determine current repository', vim.log.levels.ERROR)
    return
  end

  local repo_full = repo_info.owner.login .. '/' .. repo_info.name
  local pulls = github_utils.get_pulls(repo_full)

  select_and_open_pr_from_list(pulls, repo_full)
end

function M.select_and_open_pr()
  local orgs = {
    vim.env.ORG_GITHUB_NAME,
    vim.env.PRI_GITHUB_USERNAME,
  }

  local valid_orgs = {}
  for _, org in ipairs(orgs) do
    if org and org ~= '' then table.insert(valid_orgs, org) end
  end

  if #valid_orgs == 0 then
    vim.notify('No GitHub organizations configured in environment', vim.log.levels.ERROR)
    return
  end

  vim.ui.select(valid_orgs, {
    prompt = 'Select organization:',
  }, function(selected_org)
    if not selected_org then return end

    M.select_repo_and_open_pr(selected_org)
  end)
end

function M.select_repo_and_open_pr(org_name)
  local output = vim.fn.system('gh repo list ' .. org_name .. ' --limit 30 --json name,url 2>/dev/null')
  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to fetch repositories for ' .. org_name, vim.log.levels.ERROR)
    return
  end

  local ok, repos = pcall(vim.fn.json_decode, output)
  if not ok or #repos == 0 then
    vim.notify('No repositories found for ' .. org_name, vim.log.levels.ERROR)
    return
  end

  local repo_names = {}
  for _, repo in ipairs(repos) do
    table.insert(repo_names, repo.name)
  end

  vim.ui.select(repo_names, {
    prompt = 'Select repository:',
  }, function(selected_repo)
    if not selected_repo then return end

    local pulls = github_utils.get_pulls(org_name .. '/' .. selected_repo)
    select_and_open_pr_from_list(pulls, selected_repo)
  end)
end

function M.open_current_commit_in_github()
  local commit_hash = vim.fn.system('git rev-parse HEAD 2>/dev/null'):gsub('%s+', '')
  if vim.v.shell_error ~= 0 or not commit_hash or commit_hash == '' then
    vim.notify('Could not determine current commit hash', vim.log.levels.ERROR)
    return
  end

  local repo_info = github_utils.get_repo_info()
  if not repo_info or not repo_info.nameWithOwner then
    vim.notify('Could not determine repository', vim.log.levels.ERROR)
    return
  end

  local github_url = string.format('https://github.com/%s/commit/%s', repo_info.nameWithOwner, commit_hash)

  file_utils.open(github_url)
  vim.notify(string.format('Opened commit %s in GitHub', commit_hash:sub(1, 7)), vim.log.levels.INFO)
end


function M.list_org_repos_and_open()
  local programming_dir = vim.fn.expand('~/Programming')
  local org_dirs = {}

  local handle = vim.loop.fs_scandir(programming_dir)
  if not handle then
    vim.notify('Could not scan ~/Programming', vim.log.levels.ERROR)
    return
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if type == 'directory' and name ~= 'Worktrees' then
      table.insert(org_dirs, name)
    end
  end

  table.sort(org_dirs)

  if #org_dirs == 0 then
    vim.notify('No organization folders found in ~/Programming', vim.log.levels.ERROR)
    return
  end

  local function show_repos(org_name)
    local org_path = programming_dir .. '/' .. org_name
    local repo_handle = vim.loop.fs_scandir(org_path)
    if not repo_handle then
      vim.notify('Could not scan ' .. org_path, vim.log.levels.ERROR)
      return
    end

    local items = {}
    while true do
      local repo_name, repo_type = vim.loop.fs_scandir_next(repo_handle)
      if not repo_name then break end
      if repo_type == 'directory' then
        table.insert(items, {
          text = repo_name,
          name = repo_name,
          url = 'https://github.com/' .. org_name .. '/' .. repo_name,
          org = org_name,
        })
      end
    end

    table.sort(items, function(a, b) return a.name < b.name end)

    if #items == 0 then
      vim.notify('No repositories found in ' .. org_name, vim.log.levels.INFO)
      return
    end

    local snacks_ok, snacks = pcall(require, 'snacks')
    if not snacks_ok then return end

    snacks.picker({
      title = 'Repos: ' .. org_name,
      items = items,
      format = function(item) return { { item.text, 'Normal' } } end,
      confirm = function(picker, item)
        picker:close()
        file_utils.open(item.url)
        vim.notify('Opened ' .. item.name .. ' in browser', vim.log.levels.INFO)
      end,
    })
  end

  if #org_dirs == 1 then
    show_repos(org_dirs[1])
  else
    vim.ui.select(org_dirs, {
      prompt = 'Select organization:',
    }, function(selected_org)
      if not selected_org then return end
      show_repos(selected_org)
    end)
  end
end

return M
