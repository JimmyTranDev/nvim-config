-- Utility to get and open recent files in current working directory
local M = {}

local function get_recent_files()
  local recent_files = vim.v.oldfiles or {}
  local cwd = vim.loop.cwd()
  local filtered = {}
  for _, file in ipairs(recent_files) do
    -- Check if file is in current directory and actually exists
    if vim.startswith(file, cwd) and vim.loop.fs_stat(file) then
      table.insert(filtered, file)
    end
  end
  return filtered
end

function M.open_most_recent_in_cwd()
  local files = get_recent_files()
  if #files > 0 then
    -- Files are already filtered to existing ones, so we can directly open the first
    vim.cmd('edit ' .. vim.fn.fnameescape(files[1]))
    return true
  end
  return false
end



return M
