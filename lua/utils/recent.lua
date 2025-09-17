-- Utility to get and open recent files in current working directory
local M = {}

local function get_recent_files()
  local recent_files = vim.v.oldfiles or {}
  local cwd = vim.loop.cwd()
  local filtered = {}
  for _, file in ipairs(recent_files) do
    if vim.startswith(file, cwd) then
      table.insert(filtered, file)
    end
  end
  return filtered
end

function M.open_most_recent_in_cwd()
  local files = get_recent_files()
  if #files > 0 then
    vim.cmd('edit ' .. vim.fn.fnameescape(files[1]))
  end
end

return M
