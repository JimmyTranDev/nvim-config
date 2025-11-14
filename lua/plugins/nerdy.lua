return {
  '2KAbhishek/nerdy.nvim',
  dependencies = {
    'stevearc/dressing.nvim',
    'nvim-telescope/telescope.nvim',
  },
  cmd = 'Nerdy',
  keys = {
    -- Insert mode keybindings (preserving familiar shortcuts)
    {
      mode = 'i',
      '<c-,>',
      '<cmd>Nerdy<cr>',
      silent = true,
      desc = 'Nerdy Icon Picker',
    },
    {
      mode = 'i', 
      '<c-.>',
      '<cmd>Nerdy<cr>',
      silent = true,
      desc = 'Nerdy Icon Picker',
    },

    -- Normal mode keybindings (preserving existing locations)
    {
      mode = 'n',
      '<leader><leader>dm',
      '<cmd>Nerdy<cr>',
      silent = true,
      desc = 'Nerdy Icon Picker',
    },
    {
      mode = 'n',
      '<leader><leader>dM',
      '<cmd>Nerdy<cr>',
      silent = true,
      desc = 'Nerdy Icon Picker',
    },
  },
  config = function()
    -- Nerdy doesn't require setup by default, but we can configure if needed
    -- The plugin works out of the box with telescope
  end,
}