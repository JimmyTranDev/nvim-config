-- =============================================================================
-- Neovim Constants and Configuration Values
-- =============================================================================

local expand = vim.fn.expand

-- =============================================================================
-- Directory Paths
-- =============================================================================
local HOME = expand('$HOME')
local NEOVIM_STATE_DIR = expand('$HOME/.local/state/nvim/')
local PROGRAMMING_DIR = expand('$HOME/Programming')

-- =============================================================================
-- Catppuccin Color Scheme
-- =============================================================================
local colors = {
  -- Main colors (Latte)
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

  -- Text colors (Latte)
  text = '#4c4f69',
  subtext1 = '#5c5f77',
  subtext0 = '#6c6f85',

  -- Surface colors (Latte)
  overlay2 = '#7c7f93',
  overlay1 = '#8c8fa1',
  overlay0 = '#9ca0b0',
  surface2 = '#acb0be',
  surface1 = '#bcc0cc',
  surface0 = '#ccd0da',

  -- Base colors (Latte)
  base = '#eff1f5',
  mantle = '#e6e9ef',
  crust = '#dce0e8',
}

-- =============================================================================
-- Module Exports
-- =============================================================================
return {
  -- Paths
  HOME = HOME,
  NEOVIM_STATE_DIR = NEOVIM_STATE_DIR,
  PROGRAMMING_DIR = PROGRAMMING_DIR,

  -- Colors
  colors = colors,
}
