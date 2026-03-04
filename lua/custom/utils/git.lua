local M = {}

local function run_cmd(cmd)
  local result = vim.fn.system(cmd .. ' 2>/dev/null')
  if vim.v.shell_error ~= 0 then return nil end
  return result:match('^([^\n]*)')
end

function M.get_current_branch()
  return run_cmd('git rev-parse --abbrev-ref HEAD') or ''
end

function M.extract_jira_ticket(branch_name)
  if type(branch_name) ~= 'string' then return '' end
  return branch_name:match('([a-zA-Z]+%-%d+)_') or branch_name:match('([a-zA-Z]+%-%d+)') or ''
end

return M
