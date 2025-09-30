-- actions/github.lua
-- Utility to create a draft pull request and open it in browser using GitHub CLI

local M = {}

function M.create_draft_pr()
  local cmd = 'gh pr create --draft --web'
  vim.fn.system(cmd)
  vim.notify('Draft PR created and opened in browser', vim.log.levels.INFO)
end


local githubUtils = require('custom.utils.github')

function M.open_prs_in_current_repo()
  -- Get current repo (owner/name)
  local handle = io.popen('gh repo view --json name,owner')
  local repo_info = nil
  if handle then
    local output = handle:read('*a')
    handle:close()
    local ok, json = pcall(vim.fn.json_decode, output)
    if ok and json then repo_info = json end
  end
  if not repo_info or not repo_info.owner or not repo_info.name then
    vim.notify('Could not determine current repo', vim.log.levels.ERROR)
    return
  end
  local repo_full = repo_info.owner.login .. '/' .. repo_info.name
  local pulls = githubUtils.get_pulls(repo_full)
  if #pulls == 0 then
    vim.notify('No PRs found in ' .. repo_full, vim.log.levels.INFO)
    return
  end
  local pr_titles = {}
  for _, pr in ipairs(pulls) do
    table.insert(pr_titles, string.format('#%d %s [%s]', pr.number, pr.title, pr.state))
  end
  vim.ui.select(pr_titles, { prompt = 'Select PR to open:' }, function(selected_pr_title)
    if not selected_pr_title then return end
    for _, pr in ipairs(pulls) do
      if selected_pr_title:find('#' .. pr.number) then
        vim.fn.system('open ' .. pr.url)
        vim.notify('Opened PR #' .. pr.number .. ' in browser', vim.log.levels.INFO)
        return
      end
    end
  end)
end

function M.select_and_open_pr()
  local orgs = { vim.env.PRI_GITHUB_USERNAME, vim.env.ORG_GITHUB_NAME, vim.env.ORG_GITHUB_DESIGN_NAME }
  vim.ui.select(orgs, { prompt = 'Select organization:' }, function(selected_org)
    if not selected_org then return end
    local handle = io.popen('gh repo list ' .. selected_org .. ' --limit 30 --json name,url')
    local repos = {}
    if handle then
      local output = handle:read('*a')
      handle:close()
      local ok, json = pcall(vim.fn.json_decode, output)
      if ok and json then repos = json end
    end
    if #repos == 0 then
      vim.notify('No repos found for ' .. selected_org, vim.log.levels.ERROR)
      return
    end
    local repo_names = {}
    for _, r in ipairs(repos) do
      table.insert(repo_names, r.name)
    end
    vim.ui.select(repo_names, { prompt = 'Select repo:' }, function(selected_repo)
      if not selected_repo then return end
  local pulls = githubUtils.get_pulls(selected_org .. '/' .. selected_repo)
      if #pulls == 0 then
        vim.notify('No PRs found in ' .. selected_repo, vim.log.levels.INFO)
        return
      end
      local pr_titles = {}
      for _, pr in ipairs(pulls) do
        table.insert(pr_titles, string.format('#%d %s [%s]', pr.number, pr.title, pr.state))
      end
      vim.ui.select(pr_titles, { prompt = 'Select PR to open:' }, function(selected_pr_title)
        if not selected_pr_title then return end
        for _, pr in ipairs(pulls) do
          if selected_pr_title:find('#' .. pr.number) then
            vim.fn.system('open ' .. pr.url)
            vim.notify('Opened PR #' .. pr.number .. ' in browser', vim.log.levels.INFO)
            return
          end
        end
      end)
    end)
  end)
end

function M.open_current_commit_in_github()
  -- Get current commit hash
  local handle = io.popen('git rev-parse HEAD')
  if not handle then
    vim.notify('Failed to get current commit hash', vim.log.levels.ERROR)
    return
  end
  
  local commit_hash = handle:read('*a'):gsub('%s+', '')
  handle:close()
  
  if not commit_hash or commit_hash == '' then
    vim.notify('Could not determine current commit hash', vim.log.levels.ERROR)
    return
  end
  
  -- Get repo info
  local repo_handle = io.popen('gh repo view --json nameWithOwner')
  if not repo_handle then
    vim.notify('Failed to get repo info', vim.log.levels.ERROR)
    return
  end
  
  local repo_output = repo_handle:read('*a')
  repo_handle:close()
  
  local ok, repo_info = pcall(vim.fn.json_decode, repo_output)
  if not ok or not repo_info or not repo_info.nameWithOwner then
    vim.notify('Could not determine repository', vim.log.levels.ERROR)
    return
  end
  
  -- Construct GitHub commit URL
  local github_url = string.format('https://github.com/%s/commit/%s', repo_info.nameWithOwner, commit_hash)
  
  -- Open in browser
  vim.fn.system('open "' .. github_url .. '"')
  vim.notify(string.format('Opened commit %s in GitHub', commit_hash:sub(1, 7)), vim.log.levels.INFO)
end

return M
