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
    local language_utils = require('custom.utils.language')

    require('package-info').setup({
      colors = {
        up_to_date = '#3C4048',
        outdated = '#d19a66',
      },
      icons = {
        enable = true,
        style = {
          up_to_date = '|  ',
          outdated = '|  ',
        },
      },
      autostart = true,
      hide_up_to_date = true,
      hide_unstable_versions = true,
      package_manager = language_utils.getJavascriptPackageManager() or 'npm',
    })
  end,
}
