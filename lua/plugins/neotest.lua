return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    'marilari88/neotest-vitest',
    'rcasia/neotest-java',
    'nvim-neotest/neotest-python',
  },
  keys = {
    { '<leader>cr', function() require('neotest').run.run() end, desc = 'Run Nearest' },
    { '<leader>cf', function() require('neotest').run.run(vim.fn.expand('%')) end, desc = 'Run File' },
    { '<leader>cs', function() require('neotest').summary.toggle() end, desc = 'Toggle Summary' },
    { '<leader>co', function() require('neotest').output_panel.toggle() end, desc = 'Toggle Output Panel' },
    { '<leader>cd', function() require('neotest').run.run({ strategy = 'dap' }) end, desc = 'Debug Nearest' },
    { '<leader>cx', function() require('neotest').run.stop() end, desc = 'Stop' },
    { '<leader>ca', function() require('neotest').run.run(vim.uv.cwd()) end, desc = 'Run All' },
  },
  config = function()
    require('neotest').setup({
      adapters = {
        require('neotest-vitest'),
        require('neotest-java'),
        require('neotest-python'),
      },
    })
  end,
}
