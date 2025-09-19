-- actions/worktree.lua
-- Utility to pull develop and rebase all git worktrees

local M = {}

M.pull_and_rebase_all = function()
  local handle = io.popen('git worktree list | awk "{print $1}"')
  if not handle then
    vim.notify('Failed to list worktrees', vim.log.levels.ERROR)
    return
  end
  local result = handle:read('*a')
  handle:close()
  local worktrees = {}
  for path in string.gmatch(result, '[^\n]+') do
    table.insert(worktrees, path)
  end
  vim.fn.system('git fetch origin develop')
  for _, wt in ipairs(worktrees) do
    local cmd = string.format('cd "%s" && git rebase origin/develop 2>&1', wt)
    local output = vim.fn.system(cmd)
    if string.find(output, 'CONFLICT') or string.find(output, 'error: could not apply') then
      vim.fn.system(string.format('cd "%s" && git rebase --abort', wt))
      vim.notify('Conflict detected and rebase aborted in ' .. wt, vim.log.levels.ERROR)
    end
  end
  vim.notify('Rebased all worktrees onto develop (conflicts aborted)', vim.log.levels.INFO)
end

return M
