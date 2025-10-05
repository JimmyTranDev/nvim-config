local M = {}
local gitUtils = require('custom.utils.git')

-- Function to check if VSCode window is open for the current git repository
local function is_vscode_window_open()
  -- Get the current git repository root
  local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
  if vim.v.shell_error ~= 0 then
    return false, nil
  end
  
  -- Use osascript to check if VSCode has a window open for this directory
  local script = string.format([[
    tell application "System Events"
      if not (exists process "Code") then return "false"
    end tell
    
    tell application "Visual Studio Code"
      repeat with w in windows
        try
          set windowName to name of w
          if windowName contains "%s" then return "true"
        end try
      end repeat
    end tell
    return "false"
  ]], vim.fn.fnamemodify(git_root, ':t'))
  
  local result = vim.fn.system('osascript -e \'' .. script .. '\''):gsub('\n', '')
  return result == "true", git_root
end

-- Function to open VSCode with the current file and line number
function M.open_in_vscode()
  -- Get current file path and line number
  local current_file = vim.fn.expand('%:p')
  local current_line = vim.fn.line('.')
  
  -- Check if file exists
  if current_file == '' or vim.fn.filereadable(current_file) == 0 then
    vim.notify('No valid file to open in VSCode', vim.log.levels.WARN)
    return
  end
  
  -- Check if VSCode window is open for current repo
  local window_open, git_root = is_vscode_window_open()
  
  if not window_open and git_root then
    -- Open new VSCode window with the git repository
    vim.notify('Opening new VSCode window for repository...', vim.log.levels.INFO)
    vim.fn.system('code "' .. git_root .. '"')
    -- Wait a moment for VSCode to open
    vim.fn.system('sleep 2')
  end
  
  -- Open the specific file at the current line
  local vscode_command = string.format('code --goto "%s:%d"', current_file, current_line)
  vim.fn.system(vscode_command)
  
  vim.notify(string.format('Opened %s:%d in VSCode', vim.fn.fnamemodify(current_file, ':t'), current_line), vim.log.levels.INFO)
end

return M
