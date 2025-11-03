return {
  'NickvanDyke/opencode.nvim',
  dependencies = {
    -- Recommended for `ask()`, and required for `toggle()` — otherwise optional
    { 'folke/snacks.nvim', opts = { input = { enabled = true } } },
  },
  config = function()
    vim.g.opencode_opts = {
      float = true,
    }

    -- Required for `opts.auto_reload`
    vim.opt.autoread = true
  end,
  keys = {
    { '<leader>aa', function() require('opencode').command('session_new') end, desc = 'New session', mode = 'n' },
    { '<leader>at', function() require('opencode').toggle() end, desc = 'Toggle embedded', mode = 'n' },
    { '<leader>aq', function() require('opencode').ask('@cursor: ') end, desc = 'Ask about this', mode = 'n' },
    { '<leader>aq', function() require('opencode').ask('@selection: ') end, desc = 'Ask about selection', mode = 'v' },
    { '<leader>ab', function() require('opencode').prompt('@buffer', { append = true }) end, desc = 'Add buffer to prompt', mode = 'n' },
    { '<leader>aB', function() require('opencode').prompt('@selection', { append = true }) end, desc = 'Add selection to prompt', mode = 'v' },
    { '<leader>ae', function() require('opencode').prompt('Explain @cursor and its context') end, desc = 'Explain this code', mode = 'n' },
    { '<S-C-u>', function() require('opencode').command('messages_half_page_up') end, desc = 'Messages half page up', mode = 'n' },
    { '<S-C-d>', function() require('opencode').command('messages_half_page_down') end, desc = 'Messages half page down', mode = 'n' },
    { '<leader>as', function() require('opencode').select() end, desc = 'Select prompt', mode = { 'n', 'v' } },
    { '<leader>ac', function() require('opencode').prompt('commit') end, desc = 'Commit changes', mode = 'n' },
  },
}
