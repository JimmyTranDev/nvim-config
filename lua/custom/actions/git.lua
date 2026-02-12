local git_utils = require('custom.utils.git')
local input_utils = require('custom.utils.input')
local file_utils = require('custom.utils.files')

local M = {}

function M.createBranch(prefix)
  return function()
    local jiraTicket = input_utils.get_input('Jira Ticket: ')
    local branchName
    if jiraTicket ~= '' then
      local summary = vim.fn.system(string.format("jira issue view %s --raw | jq -r '.fields.summary'", jiraTicket))
      summary = string.gsub(summary, '%s+', '-')
      summary = string.gsub(summary, '[^%w%-]', '')
      branchName = string.format('%s/%s_%s', prefix, jiraTicket, summary)
    else
      local branchDescription = input_utils.get_input('Branch Description: ')
      local descriptionPart = string.gsub(branchDescription, '%s+', '-')
      branchName = string.format('%s/%s', prefix, descriptionPart)
    end

    vim.cmd(string.format('Git checkout -b %s', branchName))

    vim.cmd("TermExec5 open=0 cmd='git add .'")

    vim.cmd(string.format('TermExec5 open=0 cmd=\'git commit --no-verify -m "%s"\'', branchName))
  end
end

function M.createWorktree(prefix)
  return function()
    local jiraTicket = input_utils.get_input('Jira Ticket: ')
    local branchName, worktreeName
    if jiraTicket ~= '' then
      local summary = vim.fn.system(string.format("jira issue view %s --raw | jq -r '.fields.summary'", jiraTicket))
      summary = string.gsub(summary, '%s+', '-')
      summary = string.gsub(summary, '[^%w%-]', '')
      branchName = string.format('%s/%s_%s', prefix, jiraTicket, summary)
      worktreeName = string.format('~/Programming/%s_%s', prefix, summary)
    else
      local branchDescription = input_utils.get_input('Branch Description: ')
      local descriptionPart = string.gsub(branchDescription, '%s+', '-')
      branchName = string.format('%s/%s', prefix, descriptionPart)
      worktreeName = string.format('~/Programming/%s_%s', prefix, descriptionPart)
    end

    vim.cmd(string.format('Git worktree add -b %s %s', branchName, worktreeName))
  end
end

function M.createCommit(prefix, emoji, shouldPush, shouldGeneric)
  return function()
    local branchName = git_utils.get_current_branch()
    local jiraTicket = git_utils.extract_jira_ticket(branchName)

    local commitMessage

    if not shouldGeneric then
      local commitDescription = input_utils.get_input('󰦨 Description: ')
      local commitScope = input_utils.get_input('󰟾 Scope: ')

      if commitDescription == nil then return end

      local jiraTicketPart = jiraTicket == '' and '' or jiraTicket .. ' '
      local commitScopePart = commitScope == '' and '' or '(' .. commitScope .. ')'
      local emojiPart = emoji == '' and '' or ' ' .. emoji

      commitMessage = prefix .. commitScopePart .. ':' .. emojiPart .. ' ' .. jiraTicketPart .. commitDescription
    else
      commitMessage = prefix .. ': update'
    end

    vim.cmd(string.format('TermExec5 open=0 cmd=\'git commit --no-verify -m "%s"\'', commitMessage))

    if shouldPush then vim.cmd("TermExec3 open=0 cmd='git push'") end
  end
end

function M.quickCommitUpdate()
  local commitMessage = 'feat: ✨ update'
  vim.cmd(string.format('Git commit --no-verify -m "%s"', commitMessage))
end

function M.createCommitFromBranchName()
  local branchName = git_utils.get_current_branch()
  if not branchName or branchName == '' or branchName == 'main' or branchName == 'master' then
    vim.notify('Cannot generate commit from current branch name')
    return
  end

  local commitMessage
  local emoji
  local prefix

  if branchName:find('^feat/') or branchName:find('^feature/') then
    prefix = 'feat'
    emoji = '✨'
  elseif branchName:find('^fix/') then
    prefix = 'fix'
    emoji = '🐛'
  elseif branchName:find('^chore/') then
    prefix = 'chore'
    emoji = '🔧'
  elseif branchName:find('^docs/') then
    prefix = 'docs'
    emoji = '📚'
  elseif branchName:find('^style/') then
    prefix = 'style'
    emoji = '💎'
  elseif branchName:find('^refactor/') then
    prefix = 'refactor'
    emoji = '🔨'
  elseif branchName:find('^perf/') then
    prefix = 'perf'
    emoji = '🚀'
  elseif branchName:find('^test/') then
    prefix = 'test'
    emoji = '🧪'
  elseif branchName:find('^build/') then
    prefix = 'build'
    emoji = '📦'
  elseif branchName:find('^ci/') then
    prefix = 'ci'
    emoji = '👷'
  elseif branchName:find('^revert/') then
    prefix = 'revert'
    emoji = '⏪'
  else
    prefix = 'feat'
    emoji = '✨'
  end

  local jiraTicket = git_utils.extract_jira_ticket(branchName)
  local jiraTicketPart = jiraTicket == '' and '' or jiraTicket .. ' '

  local description = branchName:gsub('^[^/]+/', '')
  if jiraTicket ~= '' then
    description = description:gsub('^' .. jiraTicket:gsub('%-', '%%-') .. '[_%-]?', '')
  end
  description = description:gsub('_', ' '):gsub('-', ' ')

  commitMessage = prefix .. ': ' .. emoji .. ' ' .. jiraTicketPart .. description

  vim.cmd('Git add .')

  local escapedMessage = commitMessage:gsub('"', '\\"')
  vim.cmd(string.format('Git commit --no-verify -m "%s"', escapedMessage))

  vim.notify('Committed: ' .. commitMessage)
end

function M.addTagToHash()
  local tagName = input_utils.get_input('Tag Name: ')
  if tagName == '' then return end

  local commitLines, commitLineToSha = git_utils.get_commit_log(false)
  local message = input_utils.get_input('Tag Message: ')

  vim.ui.select(commitLines, {
    prompt = 'Select commit to tag:',
  }, function(commitLine)
    if commitLine == nil then return end

    local sha = commitLineToSha[commitLine]

    if message == '' then
      vim.cmd('Git tag -f ' .. tagName .. ' ' .. sha)
    else
      vim.cmd('Git tag -f -a ' .. tagName .. ' -m ' .. message .. ' ' .. sha)
    end
  end)
end

function M.copyLatestCommitMessage()
  local handle = io.popen('git log -1 --pretty=%B')
  if not handle then
    vim.notify('Failed to run git command')
    return
  end

  local message = handle:read('*a')
  handle:close()

  if not message or message == '' then
    vim.notify('No commit message found.')
    return
  end

  local cleaned = message:gsub('[%z\1-\127\194-\244][\128-\191]+', ''):gsub(':[%w_]+:', ''):gsub('[%p%c%s]*[\xF0-\xF4][\x80-\xBF][\x80-\xBF][\x80-\xBF]', '')

  cleaned = cleaned:gsub('^%s+', ''):gsub('%s+$', '')
  vim.fn.setreg('+', cleaned)
  vim.notify('Cleaned commit message copied to clipboard.')
end

function M.resetToReflog()
  local handle = io.popen('git reflog --oneline -n 20')
  if not handle then vim.notify('Failed to run git reflog command') end

  local reflog_output = handle:read('*a')
  handle:close()

  if not reflog_output or reflog_output == '' then
    vim.notify('No reflog entries found.')
    return
  end

  local reflog_entries = {}
  local reflog_hashes = {}

  for line in reflog_output:gmatch('[^\n]+') do
    if line ~= '' then
      local hash = line:match('^(%S+)')
      if hash then
        table.insert(reflog_entries, line)
        reflog_hashes[line] = hash
      end
    end
  end

  if #reflog_entries == 0 then
    vim.notify('No reflog entries to display.')
    return
  end

  vim.ui.select(reflog_entries, {
    prompt = 'Select reflog entry to reset to:',
    format_item = function(item) return item end,
  }, function(selected_entry)
    if not selected_entry then return end

    local hash = reflog_hashes[selected_entry]
    if not hash then
      vim.notify('Failed to extract hash from reflog entry')
      return
    end

    local reset_options = {
      'soft (keep changes staged)',
      'mixed (keep changes unstaged)',
      'hard (discard all changes)',
    }

    vim.ui.select(reset_options, {
      prompt = 'Select reset type:',
    }, function(reset_type)
      if not reset_type then return end

      local reset_flag = ''
      if reset_type:match('^soft') then
        reset_flag = '--soft'
      elseif reset_type:match('^mixed') then
        reset_flag = '--mixed'
      elseif reset_type:match('^hard') then
        reset_flag = '--hard'
      end

      local cmd = string.format('git reset %s %s', reset_flag, hash)
      vim.cmd(string.format("TermExec5 cmd='%s'", cmd))

      vim.notify(string.format('Reset %s to %s', reset_flag, hash))
    end)
  end)
end

local function reset_to_commit(reset_type)
  local flag = reset_type == 'hard' and '--hard' or '--soft'
  local emoji = reset_type == 'hard' and '🔥' or '💿'
  local desc = reset_type == 'hard' and '⚠️  This will discard ALL changes' or 'changes will be kept staged'

  local handle = io.popen('git log --oneline -n 20')
  if not handle then
    vim.notify('Failed to run git log command')
    return
  end

  local log_output = handle:read('*a')
  handle:close()

  if not log_output or log_output == '' then
    vim.notify('No commit entries found.')
    return
  end

  local commit_entries = {}
  local commit_hashes = {}

  for line in log_output:gmatch('[^\n]+') do
    if line ~= '' then
      local hash = line:match('^(%S+)')
      if hash then
        table.insert(commit_entries, line)
        commit_hashes[line] = hash
      end
    end
  end

  if #commit_entries == 0 then
    vim.notify('No commit entries to display.')
    return
  end

  vim.ui.select(commit_entries, {
    prompt = 'Select commit to reset ' .. reset_type .. ' to (' .. desc .. '):',
    format_item = function(item) return item end,
  }, function(selected_entry)
    if not selected_entry then return end

    local hash = commit_hashes[selected_entry]
    if not hash then
      vim.notify('Failed to extract hash from commit entry')
      return
    end

    if reset_type == 'hard' then
      vim.ui.input({
        prompt = string.format("⚠️  Reset HARD to %s? This will discard ALL changes! Type 'yes' to confirm: ", hash:sub(1, 7)),
      }, function(confirmation)
        if confirmation ~= 'yes' then
          vim.notify('Reset cancelled.')
          return
        end
        vim.cmd(string.format("TermExec5 cmd='git reset %s %s'", flag, hash))
        vim.notify(string.format('%s Reset %s to %s', emoji, flag, hash:sub(1, 7)))
      end)
    else
      vim.cmd(string.format("TermExec5 cmd='git reset %s %s'", flag, hash))
      vim.notify(string.format('%s Reset %s to %s (changes kept staged)', emoji, flag, hash:sub(1, 7)))
    end
  end)
end

function M.resetHardToCommit() reset_to_commit('hard') end

function M.resetSoftToCommit() reset_to_commit('soft') end

function M.stashAllChanges()
  vim.ui.input({
    prompt = 'Stash message (optional): ',
  }, function(message)
    local cmd
    if message and message ~= '' then
      cmd = string.format('git stash push -m "%s"', message)
    else
      cmd = 'git stash'
    end

    vim.cmd(string.format("TermExec5 cmd='%s'", cmd))
    vim.notify('📦 Changes stashed successfully')
  end)
end

function M.stashKeepChanges()
  vim.ui.input({
    prompt = 'Stash message (optional): ',
  }, function(message)
    local cmd
    if message and message ~= '' then
      cmd = string.format('git stash push --keep-index -m "%s"', message)
    else
      cmd = 'git stash --keep-index'
    end

    vim.cmd(string.format("TermExec5 cmd='%s'", cmd))
    vim.notify('📦 Changes stashed (keeping staged changes)')
  end)
end

function M.selectAndPopStash()
  local handle = io.popen('git stash list')
  if not handle then
    vim.notify('Failed to run git stash list command')
    return
  end

  local stash_output = handle:read('*a')
  handle:close()

  if not stash_output or stash_output == '' then
    vim.notify('No stashes found.')
    return
  end

  local stash_entries = {}
  local stash_ids = {}

  for line in stash_output:gmatch('[^\n]+') do
    if line ~= '' then
      local stash_id = line:match('^(stash@{%d+})')
      if stash_id then
        table.insert(stash_entries, line)
        stash_ids[line] = stash_id
      end
    end
  end

  if #stash_entries == 0 then
    vim.notify('No stash entries to display.')
    return
  end

  vim.ui.select(stash_entries, {
    prompt = 'Select stash to pop:',
    format_item = function(item) return item end,
  }, function(selected_entry)
    if not selected_entry then return end

    local stash_id = stash_ids[selected_entry]
    if not stash_id then
      vim.notify('Failed to extract stash ID from entry')
      return
    end

    local cmd = string.format('git stash pop %s', stash_id)
    vim.cmd(string.format("TermExec5 cmd='%s'", cmd))

    vim.notify(string.format('📦 Popped stash %s', stash_id))
  end)
end

function M.gitAddPatch(extraArgs)
  return function()
    local status = vim.fn.system('git status --porcelain')
    if status == '' or status == nil then
      vim.notify('Nothing to add - working tree clean', vim.log.levels.INFO, { title = 'Git' })
      return
    end

    local has_unstaged = false
    for line in status:gmatch('[^\r\n]+') do
      if line:match('^.[MD]') or line:match('^??') then
        has_unstaged = true
        break
      end
    end

    if not has_unstaged then
      vim.notify('No unstaged changes to add', vim.log.levels.INFO, { title = 'Git' })
      return
    end

    local args = extraArgs and extraArgs ~= '' and (' ' .. extraArgs) or ''
    vim.cmd('tabnew')
    vim.cmd(string.format('terminal git add -N . && git add -p%s; exit', args))
    vim.cmd('startinsert')

    local term_win = vim.api.nvim_get_current_win()
    local term_buf = vim.api.nvim_get_current_buf()

    vim.api.nvim_create_autocmd('TermClose', {
      buffer = term_buf,
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(term_win) then vim.api.nvim_win_close(term_win, true) end
      end,
    })
  end
end

function M.resetAllWithConfirm()
  local status = vim.fn.system('git status --porcelain')
  if status == '' or status == nil then
    vim.notify('Nothing to reset - working tree clean', vim.log.levels.INFO, { title = 'Git' })
    return
  end

  local changes_count = 0
  for _ in status:gmatch('[^\r\n]+') do
    changes_count = changes_count + 1
  end

  vim.ui.input({
    prompt = string.format(
      '⚠️  Reset ALL changes? This will:\n• Reset staged files\n• Clean untracked files\n• Restore modified files\n\nAffected files: %d\nType "y" to confirm: ',
      changes_count
    ),
  }, function(confirmation)
    if confirmation ~= 'y' then
      vim.notify('Reset cancelled.')
      return
    end

    vim.cmd("TermExec5 open=0 cmd='git reset .'")
    vim.cmd("TermExec5 open=0 cmd='git clean -df'")
    vim.cmd("TermExec5 open=0 cmd='git restore .'")
    vim.notify(string.format('🔥 Reset ALL changes (%d files affected)', changes_count))
  end)
end

function M.openGithubPullRequest()
  local github_utils = require('custom.utils.github')

  local branch = git_utils.get_current_branch()
  local repo = github_utils.getRepoName()
  local username = vim.env.GITHUB_USERNAME or vim.env.PRI_GITHUB_USERNAME or ''
  if not branch or branch == '' or not repo or repo == '' or username == '' then
    vim.notify('Could not determine branch, repo, or username')
    return
  end
  local handle = io.popen('gh pr list --json number,headRefName,url')
  local prListJson = handle and handle:read('*a') or ''
  if handle then handle:close() end
  local prUrl = nil
  if prListJson and prListJson ~= '' then
    local ok, prList = pcall(vim.fn.json_decode, prListJson)
    if ok and prList then
      for _, pr in ipairs(prList) do
        if pr.headRefName == branch and pr.url then
          prUrl = pr.url
          break
        end
      end
    end
  end
  if prUrl then
    file_utils.open(prUrl)
    vim.notify('Opened existing PR for branch: ' .. branch)
  else
    local url = string.format('https://github.com/%s/%s/pull/new/%s', username, repo, branch)
    file_utils.open(url)
    vim.notify('Opened new PR creation page for branch: ' .. branch)
  end
end

local function get_pr_for_branch(branch)
  local handle = io.popen('gh pr list --json number,headRefName,url')
  if not handle then return nil end

  local prListJson = handle:read('*a')
  handle:close()

  if vim.v.shell_error ~= 0 or not prListJson or prListJson == '' then return nil end

  local ok, prList = pcall(vim.fn.json_decode, prListJson)
  if not ok or not prList then return nil end

  for _, pr in ipairs(prList) do
    if pr.headRefName == branch and pr.url then return pr.url end
  end
  return nil
end

function M.openExistingPullRequestOnly()
  local branch = git_utils.get_current_branch()
  if not branch or branch == '' then
    vim.notify('Could not determine current branch', vim.log.levels.ERROR)
    return
  end

  local prUrl = get_pr_for_branch(branch)
  if prUrl then
    file_utils.open(prUrl)
    vim.notify('🔗 Opened PR for branch: ' .. branch, vim.log.levels.INFO)
  else
    vim.notify('❌ No existing PR found for branch: ' .. branch, vim.log.levels.WARN)
  end
end

function M.openOrCreatePullRequest()
  local branch = git_utils.get_current_branch()
  if not branch or branch == '' then
    vim.notify('Could not determine current branch', vim.log.levels.ERROR)
    return
  end

  local prUrl = get_pr_for_branch(branch)
  if prUrl then
    file_utils.open(prUrl)
    vim.notify('🔗 Opened existing PR for branch: ' .. branch, vim.log.levels.INFO)
  else
    vim.notify('No existing PR found. Creating new PR into develop...', vim.log.levels.INFO)
    local result = vim.fn.system('gh pr create --base develop --web 2>&1')

    if vim.v.shell_error == 0 then
      vim.notify('🔀 PR created into develop and opened in browser', vim.log.levels.INFO)
    else
      vim.notify('Failed to create PR into develop: ' .. result, vim.log.levels.ERROR)
    end
  end
end

function M.rebaseChooseOurs()
  local current_branch = vim.fn.systemlist('git branch --show-current')[1]
  if not current_branch or current_branch == '' then
    vim.notify('❌ Could not determine current branch', vim.log.levels.ERROR)
    return
  end

  local handle = io.popen('git branch -a --format="%(refname:short)" | grep -v "^' .. current_branch .. '$" | head -20')
  if not handle then
    vim.notify('❌ Failed to get branch list', vim.log.levels.ERROR)
    return
  end

  local branch_output = handle:read('*a')
  handle:close()

  if not branch_output or branch_output == '' then
    vim.notify('❌ No other branches found', vim.log.levels.ERROR)
    return
  end

  local branches = {}
  for line in branch_output:gmatch('[^\n]+') do
    if line ~= '' and line ~= current_branch then
      local clean_branch = line:gsub('origin/', '')
      if not vim.tbl_contains(branches, clean_branch) then table.insert(branches, clean_branch) end
    end
  end

  if #branches == 0 then
    vim.notify('❌ No valid branches to rebase onto', vim.log.levels.ERROR)
    return
  end

  vim.ui.select(branches, {
    prompt = 'Select branch to rebase onto (will choose "ours" for all conflicts):',
    format_item = function(item) return item end,
  }, function(selected_branch)
    if not selected_branch then return end

    vim.ui.input({
      prompt = string.format('⚠️  Rebase %s onto %s (choose ours for all conflicts)? Type "yes" to confirm: ', current_branch, selected_branch),
    }, function(confirmation)
      if confirmation ~= 'yes' then
        vim.notify('Rebase cancelled.')
        return
      end

      local cmd = string.format('git rebase -X ours %s', selected_branch)
      vim.cmd(string.format("TermExec5 cmd='%s'", cmd))

      vim.notify(string.format('🔄 Rebasing %s onto %s (choosing ours for conflicts)', current_branch, selected_branch))
    end)
  end)
end

function M.init_repo_and_push()
  local cwd = vim.fn.getcwd()
  local folder_name = vim.fn.fnamemodify(cwd, ':t')

  if folder_name == '' then
    vim.notify('Could not determine folder name', vim.log.levels.ERROR)
    return
  end

  local git_check = vim.fn.system('git rev-parse --is-inside-work-tree 2>/dev/null')
  if vim.v.shell_error == 0 and git_check:match('true') then
    vim.notify('Already a git repository', vim.log.levels.WARN)
    return
  end

  vim.ui.input({
    prompt = string.format('Create private repo "%s" and push? (y/n): ', folder_name),
  }, function(confirmation)
    if confirmation ~= 'y' then
      vim.notify('Cancelled.')
      return
    end

    local init_result = vim.fn.system('git init')
    if vim.v.shell_error ~= 0 then
      vim.notify('Failed to init git repo: ' .. init_result, vim.log.levels.ERROR)
      return
    end

    local add_result = vim.fn.system('git add .')
    if vim.v.shell_error ~= 0 then
      vim.notify('Failed to add files: ' .. add_result, vim.log.levels.ERROR)
      return
    end

    local commit_result = vim.fn.system('git commit -m "🎉 init: initial commit"')
    if vim.v.shell_error ~= 0 then
      vim.notify('Failed to create initial commit: ' .. commit_result, vim.log.levels.ERROR)
      return
    end

    local create_result = vim.fn.system(string.format('gh repo create %s --private --source=. --push', folder_name))
    if vim.v.shell_error ~= 0 then
      vim.notify('Failed to create GitHub repo: ' .. create_result, vim.log.levels.ERROR)
      return
    end

    vim.notify(string.format('🎉 Created private repo "%s" and pushed initial commit', folder_name), vim.log.levels.INFO)
  end)
end

return M
