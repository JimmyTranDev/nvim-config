-- =============================================================================
-- Lazy.nvim Plugin Manager Configuration
-- =============================================================================

local M = {}

-- =============================================================================
-- Configuration Constants
-- =============================================================================

local config = {
  -- Performance optimization: enable lazy loading by default
  lazy_by_default = true,
  
  -- Startup performance: disable automatic update checking
  auto_check_enabled = false,
  check_frequency = 3600, -- 1 hour (if enabled)
  
  -- Default colorscheme for installation
  default_colorscheme = 'catppuccin',
}

-- =============================================================================
-- Runtime Path Optimization
-- =============================================================================

---List of built-in plugins to disable for better performance
---These are rarely used and removing them speeds up startup
local disabled_builtin_plugins = {
  'gzip',          -- Gzip file handling
  'matchit',       -- Extended % matching  
  'matchparen',    -- Highlight matching parentheses
  'netrwPlugin',   -- Network file browser (we use alternatives)
  'tarPlugin',     -- Tar file handling
  'tohtml',        -- Convert to HTML
  'tutor',         -- Vim tutor
  'zipPlugin',     -- Zip file handling
  'rplugin',       -- Remote plugin support
  'syntax',        -- Legacy syntax highlighting (we use treesitter)
  'synmenu',       -- Syntax menu
  'optwin',        -- Options window
  'compiler',      -- Compiler support
  'bugreport',     -- Bug reporting
  'ftplugin',      -- Filetype plugins (handled by treesitter)
}

-- =============================================================================
-- Lazy.nvim Setup Configuration
-- =============================================================================

---Generate the complete lazy.nvim configuration
---@return table configuration Complete configuration table
local function generate_lazy_config()
  return {
    -- Plugin specifications
    spec = {
      { import = 'plugins' }, -- Import all plugins from lua/plugins/
    },
    
    -- Default plugin behavior
    defaults = {
      lazy = config.lazy_by_default,
      version = false, -- Use latest git commits (most plugins have outdated releases)
      -- Note: Individual plugins define their own VSCode compatibility conditions
    },
    
    -- Installation settings
    install = { 
      colorscheme = { config.default_colorscheme }
    },
    
    -- Update checking configuration
    checker = {
      enabled = config.auto_check_enabled,
      frequency = config.check_frequency,
      notify = false, -- Reduce notification noise
    },
    
    -- Enhanced performance optimizations
    performance = {
      cache = {
        enabled = true,
      },
      reset_packpath = true, -- Reset packpath to improve startup time
      rtp = {
        reset = true, -- Reset runtimepath to improve startup time
        paths = {}, -- Remove unnecessary paths
        disabled_plugins = disabled_builtin_plugins,
      },
    },
    
    -- UI configuration
    ui = {
      border = 'rounded',
      backdrop = 60, -- Dim background when lazy UI is open
    },
    
    -- Development settings
    dev = {
      path = '~/Programming', -- Local development plugin path
      patterns = {}, -- Patterns for local development plugins
      fallback = false, -- Don't fallback to git when local plugin not found
    },
  }
end

-- =============================================================================
-- Initialization
-- =============================================================================

---Setup lazy.nvim with error handling
function M.setup()
  local ok, lazy = pcall(require, 'lazy')
  if not ok then
    vim.notify(
      'Failed to load lazy.nvim plugin manager', 
      vim.log.levels.ERROR
    )
    return false
  end
  
  local lazy_config = generate_lazy_config()
  
  -- Setup with error handling
  local setup_ok, err = pcall(lazy.setup, lazy_config)
  if not setup_ok then
    vim.notify(
      'Failed to setup lazy.nvim: ' .. tostring(err),
      vim.log.levels.ERROR
    )
    return false
  end
  
  return true
end

---Get current plugin manager configuration
---@return table config Current configuration
function M.get_config()
  return vim.deepcopy(config)
end

---Update configuration and reinitialize (use with caution)
---@param new_config table New configuration values
function M.update_config(new_config)
  config = vim.tbl_deep_extend('force', config, new_config)
  vim.notify('Plugin configuration updated. Restart required for full effect.', vim.log.levels.INFO)
end

-- =============================================================================
-- Auto-initialization
-- =============================================================================

-- Initialize lazy.nvim when this module loads
M.setup()

return M
