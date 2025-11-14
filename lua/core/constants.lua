-- =============================================================================
-- Neovim Constants and Configuration Values
-- =============================================================================

local expand = vim.fn.expand

-- =============================================================================
-- Path Validation Utilities
-- =============================================================================

---Validates that a directory exists
---@param path string The path to validate
---@return boolean exists Whether the directory exists
local function validate_directory(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == 'directory'
end

---Gets a validated directory path with fallback
---@param path string The primary path to check
---@param fallback string? Optional fallback path
---@return string path The validated path
local function get_validated_path(path, fallback)
  if validate_directory(path) then
    return path
  end
  
  if fallback and validate_directory(fallback) then
    return fallback
  end
  
  -- Return original path even if invalid (let caller handle)
  return path
end

-- =============================================================================
-- Directory Paths
-- =============================================================================

local HOME = expand('$HOME')
local NEOVIM_CONFIG_DIR = expand('~/.config/nvim')
local NEOVIM_DATA_DIR = expand(vim.fn.stdpath('data'))
local NEOVIM_STATE_DIR = expand('$HOME/.local/state/nvim/')
local PROGRAMMING_DIR = get_validated_path(
  expand('$HOME/Programming'),
  expand('$HOME/Documents/Programming')
)

-- =============================================================================
-- Application Configuration
-- =============================================================================

local config = {
  -- Editor behavior
  auto_save_timeout = 5000, -- milliseconds
  max_file_size = 1024 * 1024, -- 1MB limit for some operations
  
  -- UI preferences
  show_diagnostics = true,
  enable_icons = true,
  
  -- Development settings
  debug_mode = false,
  log_level = vim.log.levels.INFO,
}

-- =============================================================================
-- Catppuccin Color Scheme (Latte)
-- =============================================================================

local colors = {
  -- Main palette
  rosewater = '#dc8a78',
  flamingo = '#dd7878',
  pink = '#ea76cb',
  mauve = '#8839ef',
  red = '#d20f39',
  maroon = '#e64553',
  peach = '#fe640b',
  yellow = '#df8e1d',
  green = '#40a02b',
  teal = '#179299',
  sky = '#04a5e5',
  sapphire = '#209fb5',
  blue = '#1e66f5',
  lavender = '#7287fd',

  -- Text hierarchy
  text = '#4c4f69',
  subtext1 = '#5c5f77',
  subtext0 = '#6c6f85',

  -- Surface layers
  overlay2 = '#7c7f93',
  overlay1 = '#8c8fa1',
  overlay0 = '#9ca0b0',
  surface2 = '#acb0be',
  surface1 = '#bcc0cc',
  surface0 = '#ccd0da',

  -- Base layers
  base = '#eff1f5',
  mantle = '#e6e9ef',
  crust = '#dce0e8',
}

-- =============================================================================
-- File Extensions and Patterns
-- =============================================================================

local file_patterns = {
  -- Programming languages
  javascript = { '*.js', '*.jsx', '*.mjs' },
  typescript = { '*.ts', '*.tsx', '*.d.ts' },
  python = { '*.py', '*.pyw' },
  lua = { '*.lua' },
  rust = { '*.rs' },
  go = { '*.go' },
  
  -- Configuration files
  config = { '*.json', '*.yaml', '*.yml', '*.toml', '*.ini' },
  
  -- Documentation
  docs = { '*.md', '*.txt', '*.rst' },
}

-- =============================================================================
-- Module Exports
-- =============================================================================

return {
  -- Core paths
  HOME = HOME,
  NEOVIM_CONFIG_DIR = NEOVIM_CONFIG_DIR,
  NEOVIM_DATA_DIR = NEOVIM_DATA_DIR,
  NEOVIM_STATE_DIR = NEOVIM_STATE_DIR,
  PROGRAMMING_DIR = PROGRAMMING_DIR,

  -- Configuration
  config = config,
  
  -- Visual theme
  colors = colors,
  
  -- File handling
  file_patterns = file_patterns,
  
  -- Utilities
  validate_directory = validate_directory,
  get_validated_path = get_validated_path,
}
