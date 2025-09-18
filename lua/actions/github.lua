-- actions/github.lua
-- Utility to create a draft pull request and open it in browser using GitHub CLI

local M = {}

M.create_draft_pr = function()
  local cmd = 'gh pr create --draft --web'
  vim.fn.system(cmd)
  vim.notify('Draft PR created and opened in browser', vim.log.levels.INFO)
end

return M
