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


function M.copy_open_prs()
  local org_name = vim.env.ORG_GITHUB_NAME
  if not org_name or org_name == '' then
    vim.notify('ORG_GITHUB_NAME not set', vim.log.levels.ERROR)
    return
  end

  vim.notify('Fetching open PRs for ' .. org_name .. '...', vim.log.levels.INFO)

  vim.system(
    { 'gh', 'search', 'prs', 'draft:false', '--owner', org_name, '--state', 'open', '--author', '@me', '--json', 'number,title,repository,url', '--limit', '100' },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.notify('Failed to fetch PRs: ' .. (result.stderr or result.stdout), vim.log.levels.ERROR)
        return
      end

      local ok, prs = pcall(vim.fn.json_decode, result.stdout)
      if not ok or not prs or #prs == 0 then
        vim.notify('No open PRs found', vim.log.levels.INFO)
        return
      end

      local pending = #prs
      local pr_data = {}

      for i, pr in ipairs(prs) do
        local repo_full = pr.repository and pr.repository.nameWithOwner or ''
        local api_path = string.format('/repos/%s/pulls/%d', repo_full, pr.number)

        vim.system(
          { 'gh', 'api', api_path .. '/files', '--paginate', '--jq', '[.[] | {filename, additions, deletions}]' },
          { text = true },
          vim.schedule_wrap(function(api_result)
            local additions = 0
            local deletions = 0
            if api_result.code == 0 then
              local s_ok, files = pcall(vim.fn.json_decode, api_result.stdout)
              if s_ok and files then
                for _, file in ipairs(files) do
                  if file.filename ~= 'pnpm-lock.yaml' then
                    additions = additions + (file.additions or 0)
                    deletions = deletions + (file.deletions or 0)
                  end
                end
              end
            end

            pr_data[i] = string.format('%s %s +%d -%d', pr.url, pr.title, additions, deletions)
            pending = pending - 1

            if pending == 0 then
              local lines = {}
              for j = 1, #prs do
                table.insert(lines, pr_data[j])
              end
              local formatted = table.concat(lines, '\n')
              vim.fn.setreg('+', formatted)
              vim.notify(string.format('Copied %d PR(s) to clipboard', #prs), vim.log.levels.INFO)
            end
          end)
        )
      end
    end)
  )
end


function M.select_own_open_prs()
  local orgs = {
    vim.env.ORG_GITHUB_NAME,
    vim.env.PRI_GITHUB_USERNAME,
  }

  local valid_owners = {}
  for _, org in ipairs(orgs) do
    if org and org ~= '' then table.insert(valid_owners, org) end
  end

  if #valid_owners == 0 then
    vim.notify('No GitHub organizations configured in environment', vim.log.levels.ERROR)
    return
  end

  local all_prs = {}
  local pending = #valid_owners

  for _, owner in ipairs(valid_owners) do
    vim.system(
      {
        'gh', 'search', 'prs',
        '--owner', owner,
        '--state', 'open',
        '--author', '@me',
        '--json', 'number,title,repository,url',
        '--limit', '100',
      },
      { text = true },
      vim.schedule_wrap(function(result)
        if result.code == 0 and result.stdout and result.stdout ~= '' then
          local ok, prs = pcall(vim.fn.json_decode, result.stdout)
          if ok and prs then
            for _, pr in ipairs(prs) do
              local repo_name = pr.repository and pr.repository.nameWithOwner or ''
              table.insert(all_prs, {
                text = string.format('#%d %s [%s]', pr.number, pr.title, repo_name),
                number = pr.number,
                title = pr.title,
                url = pr.url,
                repo = repo_name,
              })
            end
          end
        end

        pending = pending - 1
        if pending > 0 then return end

        if #all_prs == 0 then
          vim.notify('No open PRs found', vim.log.levels.INFO)
          return
        end

        table.sort(all_prs, function(a, b) return a.repo < b.repo end)

        local snacks_ok, snacks = pcall(require, 'snacks')
        if not snacks_ok then return end

        snacks.picker({
          title = 'My Open PRs',
          items = all_prs,
          format = function(item) return { { item.text, 'Normal' } } end,
          confirm = function(picker, item)
            picker:close()
            file_utils.open(item.url)
            vim.notify('Opened PR #' .. item.number .. ' in browser', vim.log.levels.INFO)
          end,
        })
      end)
    )
  end
end

function M.select_and_copy_pr()
  local orgs = {
    vim.env.ORG_GITHUB_NAME,
    vim.env.PRI_GITHUB_USERNAME,
  }

  local valid_owners = {}
  for _, org in ipairs(orgs) do
    if org and org ~= '' then table.insert(valid_owners, org) end
  end

  if #valid_owners == 0 then
    vim.notify('No GitHub organizations configured in environment', vim.log.levels.ERROR)
    return
  end

  local all_prs = {}
  local pending = #valid_owners

  for _, owner in ipairs(valid_owners) do
    vim.system(
      {
        'gh', 'search', 'prs',
        'draft:false',
        '--owner', owner,
        '--state', 'open',
        '--author', '@me',
        '--json', 'number,title,repository,url',
        '--limit', '100',
      },
      { text = true },
      vim.schedule_wrap(function(result)
        if result.code == 0 and result.stdout and result.stdout ~= '' then
          local ok, prs = pcall(vim.fn.json_decode, result.stdout)
          if ok and prs then
            for _, pr in ipairs(prs) do
              local repo_name = pr.repository and pr.repository.nameWithOwner or ''
              table.insert(all_prs, {
                text = string.format('#%d %s [%s]', pr.number, pr.title, repo_name),
                number = pr.number,
                title = pr.title,
                url = pr.url,
                repo = repo_name,
              })
            end
          end
        end

        pending = pending - 1
        if pending > 0 then return end

        if #all_prs == 0 then
          vim.notify('No open PRs found', vim.log.levels.INFO)
          return
        end

        table.sort(all_prs, function(a, b) return a.repo < b.repo end)

        local snacks_ok, snacks = pcall(require, 'snacks')
        if not snacks_ok then return end

        snacks.picker({
          title = 'Select PR to Copy',
          items = all_prs,
          format = function(item) return { { item.text, 'Normal' } } end,
          confirm = function(picker, item)
            picker:close()
            local api_path = string.format('/repos/%s/pulls/%d', item.repo, item.number)

            vim.system(
              { 'gh', 'api', api_path .. '/files', '--paginate', '--jq', '[.[] | {filename, additions, deletions}]' },
              { text = true },
              vim.schedule_wrap(function(api_result)
                local additions = 0
                local deletions = 0
                if api_result.code == 0 then
                  local s_ok, files = pcall(vim.fn.json_decode, api_result.stdout)
                  if s_ok and files then
                    for _, file in ipairs(files) do
                      if file.filename ~= 'pnpm-lock.yaml' then
                        additions = additions + (file.additions or 0)
                        deletions = deletions + (file.deletions or 0)
                      end
                    end
                  end
                end

                local formatted = string.format('%s %s +%d -%d', item.url, item.title, additions, deletions)
                vim.fn.setreg('+', formatted)
                vim.notify(string.format('Copied PR #%d to clipboard', item.number), vim.log.levels.INFO)
              end)
            )
          end,
        })
      end)
    )
  end
end

function M.list_org_repos_and_open()
  local programming_dir = vim.fn.expand('~/Programming')
  local org_handle = vim.uv.fs_scandir(programming_dir)
  if not org_handle then
    vim.notify('Could not scan ~/Programming', vim.log.levels.ERROR)
    return
  end

  local items = {}

  while true do
    local org_name, org_type = vim.uv.fs_scandir_next(org_handle)
    if not org_name then break end
    if org_type ~= 'directory' or org_name == 'Worktrees' then goto continue_org end

    local repo_handle = vim.uv.fs_scandir(programming_dir .. '/' .. org_name)
    if not repo_handle then goto continue_org end

    while true do
      local repo_name, repo_type = vim.uv.fs_scandir_next(repo_handle)
      if not repo_name then break end
      if repo_type == 'directory' then
        table.insert(items, {
          text = '[' .. org_name .. '] ' .. repo_name,
          name = repo_name,
          url = 'https://github.com/' .. org_name .. '/' .. repo_name,
          org = org_name,
        })
      end
    end

    ::continue_org::
  end

  table.sort(items, function(a, b) return a.text < b.text end)

  if #items == 0 then
    vim.notify('No repositories found in ~/Programming', vim.log.levels.ERROR)
    return
  end

  local snacks_ok, snacks = pcall(require, 'snacks')
  if not snacks_ok then return end

  snacks.picker({
    title = 'Repos',
    items = items,
    format = function(item) return { { item.text, 'Normal' } } end,
    confirm = function(picker, item)
      picker:close()
      file_utils.open(item.url)
      vim.notify('Opened ' .. item.name .. ' in browser', vim.log.levels.INFO)
    end,
  })
end

return M
