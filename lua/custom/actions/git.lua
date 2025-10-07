-- =============================================================================
-- Git Action Functions
-- =============================================================================

local gitUtils = require('custom.utils.git')
local inputUtils = require('custom.utils.input')
local fileUtils = require('custom.utils.files')
local loggingUtils = require('custom.utils.logging')

local M = {}

-- =============================================================================
-- Branch Operations
-- =============================================================================

function M.createBranch(prefix)
  return function()
    local jiraTicket = inputUtils.getInputFromUser('Jira Ticket: ')
    local branchName
    if jiraTicket ~= '' then
      local summary = vim.fn.system(string.format("jira issue view %s --raw | jq -r '.fields.summary'", jiraTicket))
      summary = string.gsub(summary, '%s+', '-')
      summary = string.gsub(summary, '[^%w%-]', '')
      branchName = string.format('%s/%s_%s', prefix, jiraTicket, summary)
    else
      local branchDescription = inputUtils.getInputFromUser('Branch Description: ')
      local descriptionPart = string.gsub(branchDescription, '%s+', '-')
      branchName = string.format('%s/%s', prefix, descriptionPart)
    end

    -- Create the branch
    vim.cmd(string.format('Git checkout -b %s', branchName))

    -- Add all files
    vim.cmd("TermExec5 open=0 cmd='git add .'")

    -- Commit with the branch name as the message
    vim.cmd(string.format('TermExec5 open=0 cmd=\'git commit --no-verify -m "%s"\'', branchName))
  end
end

function M.createWorktree(prefix)
  return function()
    local jiraTicket = inputUtils.getInputFromUser('Jira Ticket: ')
    local branchName, worktreeName
    if jiraTicket ~= '' then
      local summary = vim.fn.system(string.format("jira issue view %s --raw | jq -r '.fields.summary'", jiraTicket))
      summary = string.gsub(summary, '%s+', '-')
      summary = string.gsub(summary, '[^%w%-]', '')
      branchName = string.format('%s/%s_%s', prefix, jiraTicket, summary)
      worktreeName = string.format('~/Programming/%s_%s', prefix, summary)
    else
      local branchDescription = inputUtils.getInputFromUser('Branch Description: ')
      local descriptionPart = string.gsub(branchDescription, '%s+', '-')
      branchName = string.format('%s/%s', prefix, descriptionPart)
      worktreeName = string.format('~/Programming/%s_%s', prefix, descriptionPart)
    end

    vim.cmd(string.format('Git worktree add -b %s %s', branchName, worktreeName))
  end
end

-- =============================================================================
-- Commit Operations
-- =============================================================================

function M.createCommit(prefix, emoji, shouldPush, shouldGeneric)
  return function()
    local projectName = fileUtils.getCwdName()
    local branchName = gitUtils.getCurrentBranchName()
    local jiraTicket = gitUtils.getJiraTicket(branchName)

    local commitMessage = ''

    if not shouldGeneric then
      local commitDescription = inputUtils.getInputFromUser('󰦨 Description: ')
      local commitScope = inputUtils.getInputFromUser('󰟾 Scope: ')

      if commitDescription == nil then return end

      local jiraTicketPart = jiraTicket == '' and '' or jiraTicket .. ' '
      local commitScopePart = commitScope == '' and '' or '(' .. commitScope .. ')'
      local emojiPart = emoji == '' and '' or ' ' .. emoji

      commitMessage = prefix .. commitScopePart .. ':' .. emojiPart .. ' ' .. jiraTicketPart .. commitDescription
    else
      commitMessage = prefix .. ': update'
    end

    loggingUtils.logHistory('logs-work', string.format('[%s] %s', projectName, commitMessage))
    vim.cmd(string.format('TermExec5 open=0 cmd=\'git commit --no-verify -m "%s"\'', commitMessage))

    if shouldPush then vim.cmd("TermExec3 open=0 cmd='git push'") end
  end
end

function M.quickCommitUpdate()
  vim.cmd('Git add .')

  local commitMessage = 'feat: ✨ update'
  vim.cmd(string.format('Git commit --no-verify -m "%s"', commitMessage))
end

-- =============================================================================
-- Tag Operations
-- =============================================================================

function M.addTagToHash()
  local tagName = inputUtils.getInputFromUser('Tag Name: ')
  if tagName == '' then return end

  local commitLines, commitLineToSha = gitUtils.getCommitLineToSha(false)
  local message = inputUtils.getInputFromUser('Tag Message: ')

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

  if not message or message == '' then
    vim.notify('No commit message found.')
    return
  end

  local cleaned = message:gsub('[%z\1-\127\194-\244][\128-\191]+', ''):gsub(':[%w_]+:', ''):gsub('[%p%c%s]*[\xF0-\xF4][\x80-\xBF][\x80-\xBF][\x80-\xBF]', '')

  cleaned = cleaned:gsub('^%s+', ''):gsub('%s+$', '')
  vim.fn.setreg('+', cleaned)
  vim.notify('Cleaned commit message copied to clipboard.')
end

-- =============================================================================
-- Reflog Operations
-- =============================================================================

function M.resetToReflog()
  -- Get reflog entries
  local handle = io.popen('git reflog --oneline -n 20')
  if not handle then vim.notify('Failed to run git reflog command') end

  local reflog_output = handle:read('*a')
  handle:close()

  if not reflog_output or reflog_output == '' then
    vim.notify('No reflog entries found.')
    return
  end

  -- Parse reflog entries
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

  -- Show selection menu
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

    -- Ask for reset type
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

      -- Execute the reset
      local cmd = string.format('git reset %s %s', reset_flag, hash)
      vim.cmd(string.format("TermExec5 cmd='%s'", cmd))

      vim.notify(string.format('Reset %s to %s', reset_flag, hash))
    end)
  end)
end

-- =============================================================================
-- Reset Operations
-- =============================================================================

function M.resetHardToCommit()
  -- Get commit log
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

  -- Parse commit entries
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

  -- Show selection menu
  vim.ui.select(commit_entries, {
    prompt = 'Select commit to reset hard to (⚠️  This will discard all changes):',
    format_item = function(item) return item end,
  }, function(selected_entry)
    if not selected_entry then return end

    local hash = commit_hashes[selected_entry]
    if not hash then
      vim.notify('Failed to extract hash from commit entry')
      return
    end

    -- Confirmation prompt for hard reset
    vim.ui.input({
      prompt = string.format("⚠️  Reset HARD to %s? This will discard ALL changes! Type 'yes' to confirm: ", hash:sub(1, 7)),
    }, function(confirmation)
      if confirmation ~= 'yes' then
        vim.notify('Reset cancelled.')
        return
      end

      -- Execute the hard reset
      local cmd = string.format('git reset --hard %s', hash)
      vim.cmd(string.format("TermExec5 cmd='%s'", cmd))

      vim.notify(string.format('🔥 Reset --hard to %s', hash:sub(1, 7)))
    end)
  end)
end

function M.resetSoftToCommit()
  -- Get commit log
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

  -- Parse commit entries
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

  -- Show selection menu
  vim.ui.select(commit_entries, {
    prompt = 'Select commit to reset soft to (changes will be kept staged):',
    format_item = function(item) return item end,
  }, function(selected_entry)
    if not selected_entry then return end

    local hash = commit_hashes[selected_entry]
    if not hash then
      vim.notify('Failed to extract hash from commit entry')
      return
    end

    -- Execute the soft reset
    local cmd = string.format('git reset --soft %s', hash)
    vim.cmd(string.format("TermExec5 cmd='%s'", cmd))

    vim.notify(string.format('💿 Reset --soft to %s (changes kept staged)', hash:sub(1, 7)))
  end)
end

-- =============================================================================
-- Stash Operations
-- =============================================================================

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
  -- Get stash list
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

  -- Parse stash entries
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

  -- Show selection menu
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

    -- Execute the stash pop
    local cmd = string.format('git stash pop %s', stash_id)
    vim.cmd(string.format("TermExec5 cmd='%s'", cmd))

    vim.notify(string.format('📦 Popped stash %s', stash_id))
  end)
end

function M.gitAddPatch(extraArgs)
  return function()
    -- Check if there are any changes to stage
    local status = vim.fn.system('git status --porcelain')
    if status == '' or status == nil then
      vim.notify('Nothing to add - working tree clean', vim.log.levels.INFO, { title = 'Git' })
      return
    end

    -- Check if there are any unstaged changes (modified files)
    local has_unstaged = false
    for line in status:gmatch('[^\r\n]+') do
      if line:match('^.[MD]') or line:match('^??') then -- Modified, deleted, or untracked
        has_unstaged = true
        break
      end
    end

    if not has_unstaged then
      vim.notify('No unstaged changes to add', vim.log.levels.INFO, { title = 'Git' })
      return
    end

    local args = extraArgs or ''
    vim.cmd('tabnew')
    vim.cmd(string.format('terminal git add -N . && git add -p %s; exit', args))
    vim.cmd('startinsert') -- <-- This puts you in insert mode in the terminal

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

-- =============================================================================
-- Reset Operations
-- =============================================================================

function M.resetAllWithConfirm()
  -- Check if there are any changes to reset
  local status = vim.fn.system('git status --porcelain')
  if status == '' or status == nil then
    vim.notify('Nothing to reset - working tree clean', vim.log.levels.INFO, { title = 'Git' })
    return
  end

  -- Show what will be affected
  local changes_count = 0
  for _ in status:gmatch('[^\r\n]+') do
    changes_count = changes_count + 1
  end

  -- Confirmation prompt with details
  vim.ui.input({
    prompt = string.format('⚠️  Reset ALL changes? This will:\n• Reset staged files\n• Clean untracked files\n• Restore modified files\n\nAffected files: %d\nType "yes" to confirm: ', changes_count),
  }, function(confirmation)
    if confirmation ~= 'yes' then
      vim.notify('Reset cancelled.')
      return
    end

    -- Execute the reset operations
    vim.cmd("TermExec5 cmd='git reset . && git clean -df && git restore .'")
    vim.notify(string.format('🔥 Reset ALL changes (%d files affected)', changes_count))
  end)
end

-- =============================================================================
-- GitHub PR Operations
-- =============================================================================

function M.openGithubPullRequest()
  local githubUtils = require('custom.utils.github')

  local branch = gitUtils.getCurrentBranchName()
  local repo = githubUtils.getRepoName()
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
    fileUtils.open(prUrl)
    vim.notify('Opened existing PR for branch: ' .. branch)
  else
    local url = string.format('https://github.com/%s/%s/pull/new/%s', username, repo, branch)
    fileUtils.open(url)
    vim.notify('Opened new PR creation page for branch: ' .. branch)
  end
end

-- =============================================================================
-- Rebase Operations
-- =============================================================================

function M.rebaseChooseOurs()
  -- Get current branch
  local current_branch = vim.fn.systemlist('git branch --show-current')[1]
  if not current_branch or current_branch == '' then
    vim.notify('❌ Could not determine current branch', vim.log.levels.ERROR)
    return
  end

  -- Get list of branches for rebase target
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

  -- Parse branch entries
  local branches = {}
  for line in branch_output:gmatch('[^\n]+') do
    if line ~= '' and line ~= current_branch then
      -- Clean up remote branch names
      local clean_branch = line:gsub('origin/', '')
      if not vim.tbl_contains(branches, clean_branch) then
        table.insert(branches, clean_branch)
      end
    end
  end

  if #branches == 0 then
    vim.notify('❌ No valid branches to rebase onto', vim.log.levels.ERROR)
    return
  end

  -- Show branch selection
  vim.ui.select(branches, {
    prompt = 'Select branch to rebase onto (will choose "ours" for all conflicts):',
    format_item = function(item) return item end,
  }, function(selected_branch)
    if not selected_branch then return end

    -- Confirmation prompt
    vim.ui.input({
      prompt = string.format('⚠️  Rebase %s onto %s (choose ours for all conflicts)? Type "yes" to confirm: ', current_branch, selected_branch),
    }, function(confirmation)
      if confirmation ~= 'yes' then
        vim.notify('Rebase cancelled.')
        return
      end

      -- Execute rebase with strategy to choose ours
      local cmd = string.format('git rebase -X ours %s', selected_branch)
      vim.cmd(string.format("TermExec5 cmd='%s'", cmd))
      
      vim.notify(string.format('🔄 Rebasing %s onto %s (choosing ours for conflicts)', current_branch, selected_branch))
    end)
  end)
end

return M
