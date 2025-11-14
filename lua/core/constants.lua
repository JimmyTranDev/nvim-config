-- =============================================================================
-- Neovim Constants and Configuration Values
-- =============================================================================

return {
  -- Only export what's actually used
  NEOVIM_STATE_DIR = vim.fn.expand('$HOME/.local/state/nvim/'),
}
