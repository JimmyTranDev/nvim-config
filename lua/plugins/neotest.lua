return {
  'nvim-neotest/neotest',
  cond = function()
    return not require('core.vscode').is_vscode() -- VSCode has its own test runners
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-neotest/neotest-go',
    'sidlatau/neotest-dart',
  },
  keys = {
    {
      mode = 'n',
      '<leader><leader>nt',
      function() return require('neotest').run.run(vim.fn.expand('%')) end,
      desc = 'Run current test',
      silent = true,
    },
    {
      mode = 'n',
      '<leader><leader>nd',
      function() return require('neotest').run.run(vim.fn.expand('%:h')) end,
      desc = 'Run current directory tests',
      silent = true,
    },
    {
      mode = 'n',
      '<leader><leader>na',
      function() return require('neotest').run.run(vim.fn.getcwd()) end,
      desc = 'Run all tests',
      silent = true,
    },
    {
      mode = 'n',
      '<leader><leader>nc',
      function() return require('neotest').run.run() end,
      desc = 'Run closest test',
      silent = true,
    },
    {
      mode = 'n',
      '<leader><leader>nl',
      function() return require('neotest').run.run_last() end,
      desc = 'Run last test',
      silent = true,
    },
    {
      mode = 'n',
      '<leader><leader>nw',
      function() return require('neotest').watch.toggle(vim.fn.expand('%:h')) end,
      desc = 'Toggle watch',
      silent = true,
    },
    {
      mode = 'n',
      '<leader><leader>ns',
      function() return require('neotest').summary.toggle() end,
      desc = 'Toggle summary',
      silent = true,
    },
    {
      mode = 'n',
      '<leader><leader>np',
      function() return require('neotest').output_panel.toggle() end,
      desc = 'Toggle output panel',
      silent = true,
    },
    {
      mode = 'n',
      '<leader><leader>no',
      function() return require('neotest').output.open() end,
      desc = 'Open output',
      silent = true,
    },
    {
      mode = 'n',
      '<leader><leader>ntn',
      function() return require('neotest').jump.next({ status = 'failed' }) end,
      desc = 'Jump to next failed test',
      silent = true,
    },
    {
      mode = 'n',
      '<leader><leader>ntp',
      function() return require('neotest').jump.prev({ status = 'failed' }) end,
      desc = 'Jump to previous failed test',
      silent = true,
    },
  },
  config = function()
    -- get neotest namespace (api call creates or returns namespace)
    local neotest_ns = vim.api.nvim_create_namespace('neotest')
    vim.diagnostic.config({
      virtual_text = {
        format = function(diagnostic)
          local message = diagnostic.message:gsub('\n', ' '):gsub('\t', ' '):gsub('%s+', ' '):gsub('^%s+', '')
          return message
        end,
      },
    }, neotest_ns)
    require('neotest').setup({
      -- your neotest config here
      floating = {
        border = 'rounded',
        max_height = 0.9,
        max_width = 0.9,
        options = {},
      },
      adapters = {
        require('neotest-go'),
        require('neotest-dart')({
          command = 'flutter', -- Command being used to run tests. Defaults to `flutter`
          -- Change it to `fvm flutter` if using FVM
          -- change it to `dart` for Dart only tests
          use_lsp = true, -- When set Flutter outline information is used when constructing test name.
          -- Useful when using custom test names with @isTest annotation
          custom_test_method_names = {},
        }),
      },
    })
  end,
}
