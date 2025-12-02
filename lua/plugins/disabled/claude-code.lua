return {
  'coder/claudecode.nvim',
  config = true,
  keys = {
    { '<leader>bb', nil, desc = 'AI/Claude Code' },
    { '<leader>bc', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude' },
    { '<leader>bf', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
    { '<leader>br', '<cmd>ClaudeCode --resume<cr>', desc = 'Resume Claude' },
    { '<leader>bC', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue Claude' },
    { '<leader>bm', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select Claude model' },
    { '<leader>bb', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Add current buffer' },
    { '<leader>bs', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Send to Claude' },
    {
      '<leader>bs',
      '<cmd>ClaudeCodeTreeAdd<cr>',
      desc = 'Add file',
      ft = { 'NvimTree', 'neo-tree', 'oil', 'minifiles', 'netrw' },
    },
    -- Diff management
    { '<leader>ba', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept diff' },
    { '<leader>bd', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Deny diff' },
  },
  opts = {
    terminal = {
      snacks_win_opts = {
        position = 'float',
        width = 0.85,
        height = 0.85,
        border = 'double',
        backdrop = 90,
      },
    },
  },
}
