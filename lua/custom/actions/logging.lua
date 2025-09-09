local inputUtils = require('custom.utils.input')
local loggingUtils = require('custom.utils.logging')

local M = {}

function M.logHistory(folderName, commitMessagePrefix, prompt)
  return function()
    local message = inputUtils.getInputFromUser(prompt .. ': ')

    loggingUtils.logHistory(folderName, commitMessagePrefix .. message)
  end
end

return M
