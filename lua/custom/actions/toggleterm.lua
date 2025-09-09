local M = {}

function M.createKillToggleTerm(index)
  return function()
    local all_terms = require('toggleterm.terminal').get_all()
    local term = all_terms[index]

    if term then
      term:shutdown()
    else
    end
  end
end

function M.killAllToggleTerm()
  local all_terms = require('toggleterm.terminal').get_all()
  for _, term in pairs(all_terms) do
    term:shutdown()
  end
end

return M
