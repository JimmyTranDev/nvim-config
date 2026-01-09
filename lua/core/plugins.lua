local M = {}

local config = {
  lazy_by_default = true,

  auto_check_enabled = false,
  check_frequency = 3600, -- 1 hour (if enabled)

  default_colorscheme = 'catppuccin',
}

local disabled_builtin_plugins = {
  'gzip', -- Gzip file handling
  'matchit', -- Extended % matching
  'matchparen', -- Highlight matching parentheses
  'netrwPlugin', -- Network file browser (we use alternatives)
  'tarPlugin', -- Tar file handling
  'tohtml', -- Convert to HTML
  'tutor', -- Vim tutor
  'zipPlugin', -- Zip file handling
  'rplugin', -- Remote plugin support
  'syntax', -- Legacy syntax highlighting (we use treesitter)
  'synmenu', -- Syntax menu
  'optwin', -- Options window
  'compiler', -- Compiler support
  'bugreport', -- Bug reporting
  'ftplugin', -- Filetype plugins (handled by treesitter)
}

local function generate_lazy_config()
  return {
    spec = {
      { import = 'plugins' }, -- Import all plugins from lua/plugins/
    },

    defaults = {
      lazy = config.lazy_by_default,
      version = false, -- Use latest git commits (most plugins have outdated releases)
    },

    install = {
      colorscheme = { config.default_colorscheme },
    },

    checker = {
      enabled = config.auto_check_enabled,
      frequency = config.check_frequency,
      notify = false, -- Reduce notification noise
    },

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

    ui = {
      border = 'rounded',
      backdrop = 60, -- Dim background when lazy UI is open
    },

    dev = {
      path = '~/Programming', -- Local development plugin path
      patterns = {}, -- Patterns for local development plugins
      fallback = false, -- Don't fallback to git when local plugin not found
    },
  }
end

function M.setup()
  local ok, lazy = pcall(require, 'lazy')
  if not ok then
    vim.notify('Failed to load lazy.nvim plugin manager', vim.log.levels.ERROR)
    return false
  end

  local lazy_config = generate_lazy_config()

  local setup_ok, err = pcall(lazy.setup, lazy_config)
  if not setup_ok then
    vim.notify('Failed to setup lazy.nvim: ' .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.get_config() return vim.deepcopy(config) end

function M.update_config(new_config)
  config = vim.tbl_deep_extend('force', config, new_config)
  vim.notify('Plugin configuration updated. Restart required for full effect.', vim.log.levels.INFO)
end

M.setup()

return M
