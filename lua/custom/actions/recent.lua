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

function M.open_in_vscode_at_line()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then
    vim.notify('No file to open in VS Code', vim.log.levels.WARN)
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local cmd = string.format('code --goto "%s:%d"', file, line)
  vim.fn.system(cmd)
  -- Focus VS Code in the root folder of the git repo (macOS only)
  local git_root = vim.fn.systemlist('git -C "' .. file .. '" rev-parse --show-toplevel')[1]
  if git_root and git_root ~= '' then
    vim.fn.system(string.format('open -a "Visual Studio Code" "%s"', git_root))
  end
end

return M
