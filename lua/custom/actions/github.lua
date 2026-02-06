local github_utils = require('custom.utils.github')

local M = {}

local function get_current_repo_info()
  local handle = io.popen('gh repo view --json name,owner,nameWithOwner 2>/dev/null')
  if not handle then return nil end

  local output = handle:read('*a')
  handle:close()

  if vim.v.shell_error ~= 0 then return nil end

  local ok, repo_info = pcall(vim.fn.json_decode, output)
  return ok and repo_info or nil
end

local function format_pr_display(pr) return string.format('#%d %s [%s]', pr.number, pr.title, pr.state) end

local function open_url(url) vim.fn.system('open ' .. vim.fn.shellescape(url)) end

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
        open_url(pr.url)
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

function M.create_pr_into_develop()
  local result = vim.fn.system('gh pr create --base develop --web 2>&1')

  if vim.v.shell_error == 0 then
    vim.notify('PR created into develop and opened in browser', vim.log.levels.INFO)
  else
    vim.notify('Failed to create PR into develop: ' .. result, vim.log.levels.ERROR)
  end
end

function M.open_current_repo_prs()
  local repo_info = get_current_repo_info()
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
  local handle = io.popen('gh repo list ' .. org_name .. ' --limit 30 --json name,url 2>/dev/null')
  if not handle then
    vim.notify('Failed to fetch repositories', vim.log.levels.ERROR)
    return
  end

  local output = handle:read('*a')
  handle:close()

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
  local handle = io.popen('git rev-parse HEAD 2>/dev/null')
  if not handle then
    vim.notify('Failed to get current commit hash', vim.log.levels.ERROR)
    return
  end

  local commit_hash = handle:read('*a'):gsub('%s+', '')
  handle:close()

  if vim.v.shell_error ~= 0 or not commit_hash or commit_hash == '' then
    vim.notify('Could not determine current commit hash', vim.log.levels.ERROR)
    return
  end

  local repo_info = get_current_repo_info()
  if not repo_info or not repo_info.nameWithOwner then
    vim.notify('Could not determine repository', vim.log.levels.ERROR)
    return
  end

  local github_url = string.format('https://github.com/%s/commit/%s', repo_info.nameWithOwner, commit_hash)

  open_url(github_url)
  vim.notify(string.format('Opened commit %s in GitHub', commit_hash:sub(1, 7)), vim.log.levels.INFO)
end

M.open_prs_in_current_repo = M.open_current_repo_prs

function M.list_org_repos_and_open()
  local orgs = {
    vim.env.GITHUB_ORGANIZATION_NAME,
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

  local function fetch_and_show_repos(org_name)
    vim.notify('Fetching repositories for ' .. org_name .. '...', vim.log.levels.INFO)

    vim.system(
      { 'gh', 'repo', 'list', org_name, '--limit', '100', '--json', 'name,url,updatedAt,description' },
      { text = true },
      vim.schedule_wrap(function(result)
        if result.code ~= 0 then
          vim.notify('Failed to fetch repositories for ' .. org_name, vim.log.levels.ERROR)
          return
        end

        local ok, repos = pcall(vim.fn.json_decode, result.stdout)
        if not ok or #repos == 0 then
          vim.notify('No repositories found for ' .. org_name, vim.log.levels.INFO)
          return
        end

        local items = {}
        for _, repo in ipairs(repos) do
          table.insert(items, {
            text = repo.name .. (repo.description and (' - ' .. repo.description) or ''),
            name = repo.name,
            url = repo.url,
            org = org_name,
          })
        end

        Snacks.picker({
          title = 'Repos: ' .. org_name,
          items = items,
          format = function(item) return { { item.text, 'Normal' } } end,
          confirm = function(picker, item)
            picker:close()
            open_url(item.url)
            vim.notify('Opened ' .. item.name .. ' in browser', vim.log.levels.INFO)
          end,
        })
      end)
    )
  end

  if #valid_orgs == 1 then
    fetch_and_show_repos(valid_orgs[1])
  else
    vim.ui.select(valid_orgs, {
      prompt = 'Select organization:',
    }, function(selected_org)
      if not selected_org then return end
      fetch_and_show_repos(selected_org)
    end)
  end
end

function M.list_contributed_repos_and_open()
  local username = vim.env.PRI_GITHUB_USERNAME
  if not username or username == '' then
    vim.notify('PRI_GITHUB_USERNAME not set', vim.log.levels.ERROR)
    return
  end

  vim.notify('Fetching repos you contributed to...', vim.log.levels.INFO)

  vim.system(
    { 'gh', 'api', 'graphql', '-f', 'query=query { viewer { repositoriesContributedTo(first: 100, contributionTypes: [COMMIT, PULL_REQUEST, ISSUE]) { nodes { nameWithOwner url description updatedAt } } } }' },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.notify('Failed to fetch contributed repos', vim.log.levels.ERROR)
        return
      end

      local ok, data = pcall(vim.fn.json_decode, result.stdout)
      if not ok or not data.data or not data.data.viewer or not data.data.viewer.repositoriesContributedTo then
        vim.notify('Failed to parse contributed repos', vim.log.levels.ERROR)
        return
      end

      local repos = data.data.viewer.repositoriesContributedTo.nodes
      if #repos == 0 then
        vim.notify('No contributed repos found', vim.log.levels.INFO)
        return
      end

      local items = {}
      for _, repo in ipairs(repos) do
        table.insert(items, {
          text = repo.nameWithOwner .. (repo.description and (' - ' .. repo.description) or ''),
          name = repo.nameWithOwner,
          url = repo.url,
        })
      end

      Snacks.picker({
        title = 'Contributed Repos',
        items = items,
        format = function(item) return { { item.text, 'Normal' } } end,
        confirm = function(picker, item)
          picker:close()
          open_url(item.url)
          vim.notify('Opened ' .. item.name .. ' in browser', vim.log.levels.INFO)
        end,
      })
    end)
  )
end

function M.open_org_repo_by_folder()
  local org_name = vim.env.GITHUB_ORGANIZATION_NAME or vim.env.ORG_NAME
  if not org_name or org_name == '' then
    vim.notify('GITHUB_ORGANIZATION_NAME or ORG_NAME not set', vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local folder_name = vim.fn.fnamemodify(cwd, ':t')

  if not folder_name or folder_name == '' then
    vim.notify('Could not determine folder name', vim.log.levels.ERROR)
    return
  end

  local url = 'https://github.com/' .. org_name .. '/' .. folder_name
  open_url(url)
  vim.notify('Opened ' .. org_name .. '/' .. folder_name .. ' in browser', vim.log.levels.INFO)
end

return M
