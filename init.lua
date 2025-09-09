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

-- Key mappings (loaded last to ensure all dependencies are available)
require('core.keymaps')

-- Initialize VSCode integration
vscode.setup()
