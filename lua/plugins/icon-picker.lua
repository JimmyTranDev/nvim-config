return {
  'ziontee113/icon-picker.nvim',
  keys = {
    {
      mode = 'i',
      '<c-,>',
      '<cmd>IconPickerInsert emoji<cr>',
      silent = true,
      desc = 'Icon Picker Insert',
    },
    {
      mode = 'i',
      '<c-.>',
      '<cmd>IconPickerInsert nerd_font<cr>',
      silent = true,
      desc = 'Icon Picker Insert',
    },

    {
      mode = 'n',
      '<leader><leader>dm',
      '<cmd>IconPickerInsert emoji<cr>',
      silent = true,
      desc = 'Icon Picker Insert Emoji',
    },
    {
      mode = 'n',
      '<leader><leader>dM',
      '<cmd>IconPickerInsert nerd_font<cr>',
      silent = true,
      desc = 'Icon Picker Insert Nerd Font',
    },
  },
  config = function() require('icon-picker').setup({ disable_legacy_commands = true }) end,
}
