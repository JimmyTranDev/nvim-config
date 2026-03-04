local M = {}

function M.get_pulls(repo)
  local handle = io.popen('gh pr list --repo ' .. repo .. ' --json number,title,url,state')
  if not handle then return {} end
  local output = handle:read('*a')
  handle:close()
  local ok, json = pcall(vim.fn.json_decode, output)
  if not ok or not json then return {} end
  return json
end

function M.get_repo_info()
  local handle = io.popen('gh repo view --json name,owner,nameWithOwner,url 2>/dev/null')
  if not handle then return nil end

  local output = handle:read('*a')
  handle:close()

  if vim.v.shell_error ~= 0 then return nil end

  local ok, repo_info = pcall(vim.fn.json_decode, output)
  return ok and repo_info or nil
end

function M.getRepoName()
  local info = M.get_repo_info()
  return info and info.name or nil
end

return M
