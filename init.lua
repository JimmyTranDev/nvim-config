-- Core Neovim Configuration
-- Load configuration modules in order of dependency

-- VSCode integration (must be first to set up environment)
local vscode = require('core.vscode')

-- Performance optimizations (must be first)
require('core.performance')

-- Plugin manager setup
require('core.lazy')

-- Basic options and settings
require('core.options')

-- Plugin configurations
require('core.plugins')

-- Autocommands and custom commands
require('core.commands')

-- Status line configuration (only in regular Neovim)
if not vscode.is_vscode() then require('core.statusline') end

require('core.keymaps')

vscode.setup()
-- Open directly into last file (skip dashboard)
if not vscode.is_vscode() then
  vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
      if vim.fn.argc() == 0 then require('custom.actions.recent').open_most_recent_in_cwd() end
    end,
  })
end
