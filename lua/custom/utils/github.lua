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

function M.getRepoName()
  local fullUrl = vim.fn.system('git config --get remote.origin.url')
  local repoName = string.match(fullUrl, '.*/(.*)%.git')
  return repoName
end

return M
