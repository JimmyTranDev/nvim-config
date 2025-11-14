local copilotActions = require('custom.actions.copilot')
return {
  'CopilotC-Nvim/CopilotChat.nvim',
  branch = 'main',
  dependencies = {
    { 'zbirenbaum/copilot.lua' }, -- or github/copilot.vim
    { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
  },
  config = function()
    require('CopilotChat').setup({
      debug = true, -- Enable debugging
      -- See Configuration section for rest
      window = {
        layout = 'float',
        order = 'rounded',
        height = 0.7,
        width = 0.7,
      },
    })
  end,

  -- See Commands section for default commands if you want to lazy load on them
  keys = {
    { mode = 'n', '<leader>kk', ':CopilotChat<CR>', desc = 'Copilot chat', silent = true },
    { mode = 'v', '<leader>kk', copilotActions.chat_with_selection, desc = 'Copilot chat selected', silent = true },

    { mode = 'v', '<leader>kF', copilotActions.improve_selection, desc = 'Copilot chat fms', silent = true },
    { mode = 'n', '<leader>ke', copilotActions.fix_error_under_cursor, desc = 'Copilot chat fix error under cursor', silent = true },

    { mode = 'v', '<leader>ke', ':CopilotChatExplain<cr>', silent = true, desc = 'Explain code' },
    { mode = 'v', '<leader>kr', ':CopilotChatReview<cr>', silent = true, desc = 'Review code' },
    { mode = 'v', '<leader>kf', ':CopilotChatFix<cr>', silent = true, desc = 'Fix code' },
    { mode = 'v', '<leader>ko', ':CopilotChatOptimize<cr>', silent = true, desc = 'Optimize code' },
    { mode = 'v', '<leader>kd', ':CopilotChatDocs<cr>', silent = true, desc = 'Add documentation' },
    { mode = 'v', '<leader>kt', ':CopilotChatTests<cr>', silent = true, desc = 'Generate tests' },
    { mode = 'n', '<leader>kc', ':CopilotChatCommit<cr>', silent = true, desc = 'Commit code' },
    { mode = 'n', '<leader>kC', ':CopilotChatCommitStaged<cr>', silent = true, desc = 'Commit staged code' },
  },
}
