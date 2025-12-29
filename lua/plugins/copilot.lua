return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  cond = false,
  config = function()
    require('copilot').setup({
      panel = {
        enabled = false,
        auto_refresh = false,
        keymap = {
          jump_prev = false,
          jump_next = false,
          accept = false,
          refresh = false,
          open = false,
        },
        layout = {
          position = 'bottom',
          ratio = 0.4,
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        keymap = {
          accept = '<c-h>',
          accept_word = false,
          accept_line = false,
          next = '<c-K>',
          prev = '<c-J>',
          dismiss = '<C-e>',
        },
      },
      filetypes = {
        yaml = true,
        markdown = true,
        help = false,
        gitcommit = true,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ['.'] = false,
        ['*'] = true,
      },
      copilot_node_command = 'node',
      server_opts_overrides = {
        trace = 'verbose',
        settings = {
          advanced = {
            listCount = 10,
            inlineSuggestCount = 3,
          },
        },
      },
    })

    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        vim.defer_fn(function() vim.cmd('Copilot auth') end, 1000)
      end,
    })

    vim.keymap.set('n', '<leader>ct', '<cmd>Copilot toggle<CR>', { desc = 'Toggle Copilot' })

    vim.keymap.set('n', '<leader>cs', '<cmd>Copilot status<CR>', { desc = 'Copilot status' })
  end,
}
