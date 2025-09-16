local M = {}

function M.getCurrentBranchName()
  local branch = vim.fn.system('git rev-parse --abbrev-ref HEAD')
  return vim.fn.substitute(branch, '\n', '', '')
end

function M.getJiraTicket(branchName)
  local jiraTicket = string.match(branchName, "([a-zA-Z]+%-%d+)_$") or string.match(branchName, "([a-zA-Z]+%-%d+)")
  return jiraTicket or ''
end

function M.getCommitLineToSha(isAll)
  local fugitive_command
  if isAll then
    fugitive_command = 'git log --oneline --all'
  else
    fugitive_command = 'git log --oneline'
  end

  local commitLines = vim.fn.systemlist(fugitive_command)

  local commitLineToSha = {}
  for _, commitLine in ipairs(commitLines) do
    local sha = string.sub(commitLine, 1, 7)
    commitLineToSha[commitLine] = sha
  end
  return commitLines, commitLineToSha
end

return M
