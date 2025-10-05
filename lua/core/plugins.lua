require('lazy').setup({
  spec = {
    { import = 'plugins' },
  },
  defaults = {
    -- Enable lazy loading by default for better performance
    lazy = true,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- Note: Individual plugins will define their own `cond` for VSCode compatibility
  },
  install = { colorscheme = { 'catppuccin' } },
  checker = { 
    enabled = false, -- Disable automatic checking for better performance
    frequency = 3600, -- Check once per hour if enabled
  },
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true, -- reset the package path to improve startup time
    rtp = {
      reset = true, -- reset the runtime path to $VIMRUNTIME and your config directory
      -- disable some rtp plugins
      disabled_plugins = {
        'gzip',
        'matchit',
        'matchparen',
        'netrwPlugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
        'rplugin',
        'syntax',
        'synmenu',
        'optwin',
        'compiler',
        'bugreport',
        'ftplugin',
      },
      -- add any other paths here that you want to include in the runtime path
      -- for example:
      -- paths = { "~/.config/nvim/lua" },
    },
  },
})
