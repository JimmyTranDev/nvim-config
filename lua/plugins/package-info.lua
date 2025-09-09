return {
  'vuki656/package-info.nvim',
  dependencies = 'MunifTanjim/nui.nvim',
  ft = { 'json' },
  keys = {
    {
      mode = 'n',
      '<leader>ps',
      function() require('package-info').show() end,
      silent = true,
      desc = 'NPM Show',
    },
    {
      mode = 'n',
      '<leader>pd',
      function() require('package-info').delete() end,
      silent = true,
      desc = 'Npm Delete',
    },
    {
      mode = 'n',
      '<leader>pc',
      function() require('package-info').change_version() end,
      silent = true,
      desc = 'Npm Change',
    },
    {
      mode = 'n',
      '<leader>pi',
      function() require('package-info').install() end,
      silent = true,
      desc = 'Npm Install',
    },
  },
  config = function()
    require('package-info').setup({
      colors = {
        up_to_date = '#3C4048', -- Text color for up to date dependency virtual text
        outdated = '#d19a66', -- Text color for outdated dependency virtual text
      },
      icons = {
        enable = true, -- Whether to display icons
        style = {
          up_to_date = '|  ', -- Icon for up to date dependencies
          outdated = '|  ', -- Icon for outdated dependencies
        },
      },
      autostart = true, -- Whether to autostart when `package.json` is opened
      hide_up_to_date = true, -- It hides up to date versions when displaying virtual text
      hide_unstable_versions = true, -- It hides unstable versions from version list e.g next-11.1.3-canary3
      -- Can be `npm`, `yarn`, or `pnpm`. Used for `delete`, `install` etc...
      -- The plugin will try to auto-detect the package manager based on
      -- `yarn.lock` or `package-lock.json`. If none are found it will use the
      -- provided one, if nothing is provided it will use `yarn`
      package_manager = 'pnpm',
    })
  end,
}
