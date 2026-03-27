local M = {}

function M.create_kill_toggle_term(index)
  return function()
    local term = require('toggleterm.terminal').get_all()[index]
    if term then term:shutdown() end
  end
end

function M.kill_all_toggle_term()
  for _, term in pairs(require('toggleterm.terminal').get_all()) do
    term:shutdown()
  end
end

return M
