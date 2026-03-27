local git_utils = require('custom.utils.git')
local input_utils = require('custom.utils.input')
local file_utils = require('custom.utils.files')

local M = {}

local function shell_escape_message(msg)
  return msg:gsub('[$`"\\!]', '\\%0')
end

function M.create_branch(prefix)
  return function()
    input_utils.get_input('Jira Ticket: ', function(jira_ticket)
      if jira_ticket then
        local summary = vim.fn.system(string.format("jira issue view %s --raw | jq -r '.fields.summary'", jira_ticket))
        summary = string.gsub(summary, '%s+', '-')
        summary = string.gsub(summary, '[^%w%-]', '')
        local branch_name = string.format('%s/%s_%s', prefix, jira_ticket, summary)

        vim.cmd(string.format('Git checkout -b %s', branch_name))
        vim.cmd("TermExec5 open=0 cmd='git add .'")
        vim.cmd(string.format('TermExec5 open=0 cmd=\'git commit --no-verify -m "%s"\'', shell_escape_message(branch_name)))
      else
        input_utils.get_input('Branch Description: ', function(branch_description)
          if not branch_description then return end
          local description_part = string.gsub(branch_description, '%s+', '-')
          local branch_name = string.format('%s/%s', prefix, description_part)

          vim.cmd(string.format('Git checkout -b %s', branch_name))
          vim.cmd("TermExec5 open=0 cmd='git add .'")
          vim.cmd(string.format('TermExec5 open=0 cmd=\'git commit --no-verify -m "%s"\'', shell_escape_message(branch_name)))
        end)
      end
    end)
  end
end

function M.create_worktree(prefix)
  return function()
    input_utils.get_input('Jira Ticket: ', function(jira_ticket)
      if jira_ticket then
        local summary = vim.fn.system(string.format("jira issue view %s --raw | jq -r '.fields.summary'", jira_ticket))
        summary = string.gsub(summary, '%s+', '-')
        summary = string.gsub(summary, '[^%w%-]', '')
        local branch_name = string.format('%s/%s_%s', prefix, jira_ticket, summary)
        local worktree_name = string.format('~/Programming/Worktrees/%s_%s', prefix, summary)

        vim.cmd(string.format('Git worktree add -b %s %s', branch_name, worktree_name))
      else
        input_utils.get_input('Branch Description: ', function(branch_description)
          if not branch_description then return end
          local description_part = string.gsub(branch_description, '%s+', '-')
          local branch_name = string.format('%s/%s', prefix, description_part)
          local worktree_name = string.format('~/Programming/Worktrees/%s_%s', prefix, description_part)

          vim.cmd(string.format('Git worktree add -b %s %s', branch_name, worktree_name))
        end)
      end
    end)
  end
end

local QUICK_UPDATE_MESSAGE = 'feat: ✨ update'

function M.create_commit(prefix, emoji, should_push, should_generic)
  return function()
    local branch_name = git_utils.get_current_branch()
    local jira_ticket = git_utils.extract_jira_ticket(branch_name)

    if should_generic then
      local commit_message = prefix .. ': update'
      vim.cmd(string.format('TermExec5 open=0 cmd=\'git commit --no-verify -m "%s"\'', shell_escape_message(commit_message)))
      if should_push then vim.cmd("TermExec3 open=0 cmd='git push'") end
      return
    end

    input_utils.get_input('Description: ', function(commit_description)
      if not commit_description then return end

      input_utils.get_input('Scope: ', function(commit_scope)
        local jira_ticket_part = jira_ticket == '' and '' or jira_ticket .. ' '
        local commit_scope_part = (not commit_scope or commit_scope == '') and '' or '(' .. commit_scope .. ')'
        local emoji_part = emoji == '' and '' or ' ' .. emoji

        local commit_message = (prefix or '') .. commit_scope_part .. ':' .. emoji_part .. ' ' .. jira_ticket_part .. commit_description

        vim.cmd(string.format('TermExec5 open=0 cmd=\'git commit --no-verify -m "%s"\'', shell_escape_message(commit_message)))

        if should_push then vim.cmd("TermExec3 open=0 cmd='git push'") end
      end)
    end)
  end
end

function M.quick_commit_update()
  vim.cmd(string.format('Git commit --no-verify -m "%s"', QUICK_UPDATE_MESSAGE))
end

function M.create_commit_from_branch_name()
  local branch_name = git_utils.get_current_branch()
  if not branch_name or branch_name == '' or branch_name == 'main' or branch_name == 'master' then
    vim.notify('Cannot generate commit from current branch name')
    return
  end

  local branch_type = branch_name:match('^([^/]+)/')
  if branch_type == 'feature' then branch_type = 'feat' end

  local branch_emoji = {
    feat = '✨',
    fix = '🐛',
    chore = '🔧',
    docs = '📚',
    style = '💎',
    refactor = '🔨',
    perf = '🚀',
    test = '🧪',
    build = '📦',
    ci = '👷',
    revert = '⏪',
  }

  local emoji = branch_emoji[branch_type] or '✨'
  local prefix = branch_emoji[branch_type] and branch_type or 'feat'

  local jira_ticket = git_utils.extract_jira_ticket(branch_name)
  local jira_ticket_part = jira_ticket == '' and '' or jira_ticket .. ' '

  local description = branch_name:gsub('^[^/]+/', '')
  if jira_ticket ~= '' then
    description = description:gsub('^' .. jira_ticket:gsub('%-', '%%-') .. '[_%-]?', '')
  end
  description = description:gsub('_', ' '):gsub('-', ' ')

  local commit_message = prefix .. ': ' .. emoji .. ' ' .. jira_ticket_part .. description

  vim.cmd('Git add .')

  vim.cmd(string.format('Git commit --no-verify -m "%s"', shell_escape_message(commit_message)))

  vim.notify('Committed: ' .. commit_message)
end

function M.reset_to_reflog()
  local reflog_output = vim.fn.system('git reflog --oneline -n 20')
  if vim.v.shell_error ~= 0 or not reflog_output or reflog_output == '' then
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

local function stash_with_flags(extra_flags, success_msg)
  vim.ui.input({
    prompt = 'Stash message (optional): ',
  }, function(message)
    local cmd
    if message and message ~= '' then
      cmd = string.format('git stash push%s -m "%s"', extra_flags, shell_escape_message(message))
    else
      cmd = 'git stash' .. extra_flags
    end

    vim.cmd(string.format("TermExec5 cmd='%s'", cmd))
    vim.notify(success_msg)
  end)
end

function M.stash_all_changes()
  stash_with_flags('', 'Changes stashed successfully')
end

function M.stash_keep_changes()
  stash_with_flags(' --keep-index', 'Changes stashed (keeping staged changes)')
end

function M.select_and_pop_stash()
  local stash_output = vim.fn.system('git stash list')
  if vim.v.shell_error ~= 0 or not stash_output or stash_output == '' then
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

    vim.notify(string.format('Popped stash %s', stash_id))
  end)
end

function M.git_add_patch(extra_args)
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

    local args = extra_args and extra_args ~= '' and (' ' .. extra_args) or ''
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

function M.reset_all_with_confirm()
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
      'Reset ALL changes? This will:\n- Reset staged files\n- Clean untracked files\n- Restore modified files\n\nAffected files: %d\nType "y" to confirm: ',
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
    vim.notify(string.format('Reset ALL changes (%d files affected)', changes_count))
  end)
end

local function get_pr_for_branch(branch)
  local pr_list_json = vim.fn.system('gh pr list --json number,headRefName,url')
  if vim.v.shell_error ~= 0 or not pr_list_json or pr_list_json == '' then return nil end

  local ok, pr_list = pcall(vim.fn.json_decode, pr_list_json)
  if not ok or not pr_list then return nil end

  for _, pr in ipairs(pr_list) do
    if pr.headRefName == branch and pr.url then return pr.url end
  end
  return nil
end

function M.open_or_create_pull_request()
  local branch = git_utils.get_current_branch()
  if not branch or branch == '' then
    vim.notify('Could not determine current branch', vim.log.levels.ERROR)
    return
  end

  local pr_url = get_pr_for_branch(branch)
  if pr_url then
    file_utils.open(pr_url)
    vim.notify('Opened existing PR for branch: ' .. branch, vim.log.levels.INFO)
  else
    vim.notify('No existing PR found. Creating new PR into develop...', vim.log.levels.INFO)
    local result = vim.fn.system('gh pr create --base develop --web 2>&1')

    if vim.v.shell_error == 0 then
      vim.notify('PR created into develop and opened in browser', vim.log.levels.INFO)
    else
      vim.notify('Failed to create PR into develop: ' .. result, vim.log.levels.ERROR)
    end
  end
end


function M.rebase_choose_ours()
  local current_branch = git_utils.get_current_branch()
  if not current_branch or current_branch == '' then
    vim.notify('Could not determine current branch', vim.log.levels.ERROR)
    return
  end

  local branch_output = vim.fn.system({ 'git', 'branch', '-a', '--format=%(refname:short)' })
  if vim.v.shell_error ~= 0 or not branch_output or branch_output == '' then
    vim.notify('No other branches found', vim.log.levels.ERROR)
    return
  end

  local branches = {}
  local seen = {}
  for line in branch_output:gmatch('[^\n]+') do
    if line ~= '' and line ~= current_branch then
      local clean_branch = line:gsub('origin/', '')
      if not seen[clean_branch] then
        seen[clean_branch] = true
        table.insert(branches, clean_branch)
        if #branches >= 20 then break end
      end
    end
  end

  if #branches == 0 then
    vim.notify('No valid branches to rebase onto', vim.log.levels.ERROR)
    return
  end

  vim.ui.select(branches, {
    prompt = 'Select branch to rebase onto (will choose "ours" for all conflicts):',
    format_item = function(item) return item end,
  }, function(selected_branch)
    if not selected_branch then return end

    vim.ui.input({
      prompt = string.format('Rebase %s onto %s (choose ours for all conflicts)? Type "yes" to confirm: ', current_branch, selected_branch),
    }, function(confirmation)
      if confirmation ~= 'yes' then
        vim.notify('Rebase cancelled.')
        return
      end

      local cmd = string.format('git rebase -X ours %s', selected_branch)
      vim.cmd(string.format("TermExec5 cmd='%s'", cmd))

      vim.notify(string.format('Rebasing %s onto %s (choosing ours for conflicts)', current_branch, selected_branch))
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

    local commit_result = vim.fn.system('git commit -m "init: initial commit"')
    if vim.v.shell_error ~= 0 then
      vim.notify('Failed to create initial commit: ' .. commit_result, vim.log.levels.ERROR)
      return
    end

    local create_result = vim.fn.system(string.format('gh repo create %s --private --source=. --push', folder_name))
    if vim.v.shell_error ~= 0 then
      vim.notify('Failed to create GitHub repo: ' .. create_result, vim.log.levels.ERROR)
      return
    end

    vim.notify(string.format('Created private repo "%s" and pushed initial commit', folder_name), vim.log.levels.INFO)
  end)
end

return M
