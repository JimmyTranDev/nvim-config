local M = {}

local function run_cmd(cmd)
  local handle = io.popen(cmd .. ' 2>/dev/null')
  if not handle then return nil end
  local result = handle:read('*l')
  handle:close()
  return result
end

function M.get_current_branch()
  return run_cmd('git rev-parse --abbrev-ref HEAD') or ''
end

function M.extract_jira_ticket(branch_name)
  if type(branch_name) ~= 'string' then return '' end
  return branch_name:match('([a-zA-Z]+%-%d+)_') or branch_name:match('([a-zA-Z]+%-%d+)') or ''
end

function M.get_commit_log(include_all)
  local cmd = include_all and 'git log --oneline --all' or 'git log --oneline'
  local commit_lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then return {}, {} end

  local line_to_sha = {}
  for _, line in ipairs(commit_lines) do
    local sha = line:match('^(%S+)')
    if sha then line_to_sha[line] = sha end
  end
  return commit_lines, line_to_sha
end

return M
