local inputUtils = require('custom.utils.input')
local loggingUtils = require('custom.utils.logging')
local githubUtils = require('custom.utils.github')

local M = {}

function M.logHistory(_, commitMessagePrefix, prompt)
  return function()
    local message = inputUtils.getInputFromUser(prompt .. ': ')
    local repoName = githubUtils.getRepoName()
    loggingUtils.logHistory(repoName, commitMessagePrefix .. message)
  end
end

return M
