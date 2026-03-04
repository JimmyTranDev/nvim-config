local M = {}

function M.get_pulls(repo)
  local output = vim.fn.system('gh pr list --repo ' .. repo .. ' --json number,title,url,state')
  if vim.v.shell_error ~= 0 then return {} end
  local ok, json = pcall(vim.fn.json_decode, output)
  if not ok or not json then return {} end
  return json
end

function M.get_repo_info()
  local output = vim.fn.system('gh repo view --json name,owner,nameWithOwner,url 2>/dev/null')
  if vim.v.shell_error ~= 0 then return nil end
  local ok, repo_info = pcall(vim.fn.json_decode, output)
  return ok and repo_info or nil
end

function M.getRepoName()
  local info = M.get_repo_info()
  return info and info.name or nil
end

return M
