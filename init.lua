-- Core Neovim Configuration
-- Load configuration modules in order of dependency

-- Plugin manager setup
require('core.lazy')

-- Basic options and settings
require('core.options')

-- Plugin configurations
require('core.plugins')

-- Autocommands and custom commands
require('core.commands')

-- Status line configuration
require('core.statusline')

require('core.keymaps')
