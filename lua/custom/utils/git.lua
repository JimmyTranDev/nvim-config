local M = {}

function M.get_current_branch()
  local handle = io.popen('git rev-parse --abbrev-ref HEAD 2>/dev/null')
  if not handle then return '' end

  local branch = handle:read('*l')
  handle:close()

  return branch or ''
end

function M.extract_jira_ticket(branch_name)
  if not branch_name or type(branch_name) ~= 'string' then return '' end

  local ticket = branch_name:match('([a-zA-Z]+%-%d+)_') or branch_name:match('([a-zA-Z]+%-%d+)')

  return ticket or ''
end

function M.get_commit_log(include_all)
  local command = include_all and 'git log --oneline --all' or 'git log --oneline'
  local commit_lines = vim.fn.systemlist(command)

  if vim.v.shell_error ~= 0 then return {}, {} end

  local line_to_sha = {}
  for _, line in ipairs(commit_lines) do
    local sha = line:match('^(%S+)')
    if sha then line_to_sha[line] = sha end
  end

  return commit_lines, line_to_sha
end

function M.get_latest_commit_sha()
  local handle = io.popen('git rev-parse HEAD 2>/dev/null')
  if not handle then return nil end

  local sha = handle:read('*l')
  handle:close()

  return sha
end

function M.is_git_repo()
  local handle = io.popen('git rev-parse --git-dir 2>/dev/null')
  if not handle then return false end

  local result = handle:read('*l')
  handle:close()

  return result ~= nil and result ~= ''
end

return M
