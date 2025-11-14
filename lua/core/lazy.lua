-- =============================================================================
-- Lazy.nvim Bootstrap and Configuration
-- =============================================================================

local M = {}

-- Configuration constants
local LAZY_REPO = 'https://github.com/folke/lazy.nvim.git'
local LAZY_BRANCH = 'stable'

---Check if git is available on the system
---@return boolean available Whether git is available
local function is_git_available()
  local handle = io.popen('git --version 2>/dev/null')
  if not handle then
    return false
  end
  
  local result = handle:read('*a')
  handle:close()
  
  return result and result:match('git version') ~= nil
end



---Display an error message and wait for user input before exiting
---@param title string The error title
---@param message string The error message
---@param details string? Additional error details
local function show_error_and_exit(title, message, details)
  local echo_content = {
    { title .. '\n', 'ErrorMsg' },
    { message .. '\n', 'WarningMsg' },
  }
  
  if details then
    table.insert(echo_content, { '\nDetails:\n', 'Normal' })
    table.insert(echo_content, { details .. '\n', 'Comment' })
  end
  
  table.insert(echo_content, { '\nPress any key to exit...', 'Normal' })
  
  vim.api.nvim_echo(echo_content, true, {})
  vim.fn.getchar()
  os.exit(1)
end

---Validate the cloned lazy.nvim installation
---@param lazypath string Path to lazy.nvim installation
---@return boolean valid Whether the installation is valid
local function validate_lazy_installation(lazypath)
  -- Check if main lazy.nvim module exists
  local init_file = lazypath .. '/lua/lazy/init.lua'
  local stat = (vim.uv or vim.loop).fs_stat(init_file)
  
  return stat and stat.type == 'file'
end

---Bootstrap lazy.nvim plugin manager
---@return boolean success Whether bootstrap was successful
function M.bootstrap()
  local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
  
  -- Check if lazy.nvim is already installed
  if (vim.uv or vim.loop).fs_stat(lazypath) then
    -- Validate existing installation
    if validate_lazy_installation(lazypath) then
      vim.opt.rtp:prepend(lazypath)
      return true
    else
      -- Invalid installation, remove and reinstall
      vim.notify('Removing corrupted lazy.nvim installation...', vim.log.levels.WARN)
      vim.fn.system({ 'rm', '-rf', lazypath })
    end
  end
  
  -- Check for git availability (essential)
  if not is_git_available() then
    show_error_and_exit(
      'Git not found!',
      'Git is required to install lazy.nvim but was not found on your system.',
      'Please install git and try again.'
    )
    return false
  end
  
  -- Clone lazy.nvim (let git handle network issues with its own error messages)
  vim.notify('Installing lazy.nvim...', vim.log.levels.INFO)
  
  local clone_cmd = {
    'git', 'clone',
    '--filter=blob:none',
    '--branch=' .. LAZY_BRANCH,
    LAZY_REPO,
    lazypath
  }
  
  local output = vim.fn.system(clone_cmd)
  
  if vim.v.shell_error ~= 0 then
    -- Provide helpful error message based on common failure modes
    local error_msg = 'The git clone operation failed.'
    if output:match('network') or output:match('connection') or output:match('resolve') then
      error_msg = error_msg .. '\nThis appears to be a network connectivity issue.'
    elseif output:match('permission') or output:match('access') then
      error_msg = error_msg .. '\nThis appears to be a file permission issue.'
    end
    
    show_error_and_exit(
      'Failed to clone lazy.nvim!',
      error_msg,
      output
    )
    return false
  end
  
  -- Validate the fresh installation
  if not validate_lazy_installation(lazypath) then
    show_error_and_exit(
      'Invalid lazy.nvim installation!',
      'lazy.nvim was cloned but appears to be corrupted.',
      'Try removing ' .. lazypath .. ' and restarting Neovim.'
    )
    return false
  end
  
  -- Add to runtime path
  vim.opt.rtp:prepend(lazypath)
  
  vim.notify('lazy.nvim installed successfully!', vim.log.levels.INFO)
  return true
end

-- Auto-bootstrap when this module is loaded
M.bootstrap()

return M
