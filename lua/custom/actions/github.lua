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

return M
