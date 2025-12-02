return {
  'kawre/leetcode.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  cmd = 'Leet',
  build = ':TSUpdate html',
  keys = {
    -- Core LeetCode operations
    { '<leader>bll', '<cmd>Leet<CR>', desc = '󰞷 Open LeetCode', mode = 'n' },
    { '<leader>blm', '<cmd>Leet menu<CR>', desc = '󰍉 LeetCode menu', mode = 'n' },
    { '<leader>blc', '<cmd>Leet console<CR>', desc = '󰆍 Open console', mode = 'n' },
    { '<leader>bli', '<cmd>Leet info<CR>', desc = 'ℹ️  Problem info', mode = 'n' },
    
    -- Problem navigation & browsing
    { '<leader>blL', '<cmd>Leet list<CR>', desc = '📋 List problems', mode = 'n' },
    { '<leader>bld', '<cmd>Leet daily<CR>', desc = '📅 Daily challenge', mode = 'n' },
    { '<leader>blR', '<cmd>Leet random<CR>', desc = '🎲 Random problem', mode = 'n' },
    
    -- Code execution & testing
    { '<leader>blr', '<cmd>Leet run<CR>', desc = '▶️  Run code', mode = 'n' },
    { '<leader>blS', '<cmd>Leet submit<CR>', desc = '📤 Submit solution', mode = 'n' },
    { '<leader>blT', '<cmd>Leet test<CR>', desc = '🧪 Run tests', mode = 'n' },
    
    -- Session & content management
    { '<leader>bls', '<cmd>Leet session<CR>', desc = '🔗 Manage session', mode = 'n' },
    { '<leader>bly', '<cmd>Leet yank<CR>', desc = '📋 Yank solution', mode = 'n' },
    
    -- Configuration & preferences
    { '<leader>blg', '<cmd>Leet lang<CR>', desc = '🌐 Change language', mode = 'n' },
    { '<leader>blD', '<cmd>Leet desc<CR>', desc = '📖 Toggle description', mode = 'n' },
    { '<leader>blC', '<cmd>Leet cache<CR>', desc = '💾 Cache operations', mode = 'n' },
  },
  opts = {
    arg = 'leetcode.nvim',
    lang = 'javascript',
    
    cn = {
      enabled = false,
      translator = true,
      translate_problems = true,
    },
    
    storage = {
      home = vim.fn.stdpath('data') .. '/leetcode',
      cache = vim.fn.stdpath('cache') .. '/leetcode',
    },
    
    logging = true,
    
    cache = {
      update_interval = 60 * 60 * 24 * 7, -- 7 days
    },
    
    console = {
      open_on_runcode = true,
      dir = 'row',
      size = {
        width = '90%',
        height = '75%',
      },
      result = {
        size = '60%',
      },
      testcase = {
        virt_text = true,
        size = '40%',
      },
    },
    
    description = {
      position = 'left',
      width = '40%',
      show_stats = true,
    },
    
    image_support = false,
  },
  config = function(_, opts)
    require('leetcode').setup(opts)
    
    -- Comprehensive LeetCode keymaps
    local keymap = vim.keymap
    local function map(mode, lhs, rhs, desc)
      keymap.set(mode, lhs, rhs, { desc = desc, silent = true, noremap = true })
    end

    -- Core LeetCode operations
    map('n', '<leader>bll', '<cmd>Leet<CR>', '󰞷 Open LeetCode')
    map('n', '<leader>blm', '<cmd>Leet menu<CR>', '󰍉 LeetCode menu')  
    map('n', '<leader>blc', '<cmd>Leet console<CR>', '󰆍 Open console')
    map('n', '<leader>bli', '<cmd>Leet info<CR>', 'ℹ️  Problem info')
    
    -- Problem navigation & browsing
    map('n', '<leader>blL', '<cmd>Leet list<CR>', '📋 List problems')
    map('n', '<leader>bld', '<cmd>Leet daily<CR>', '📅 Daily challenge')  
    map('n', '<leader>blR', '<cmd>Leet random<CR>', '🎲 Random problem')
    
    -- Code execution & testing  
    map('n', '<leader>blr', '<cmd>Leet run<CR>', '▶️  Run code')
    map('n', '<leader>blS', '<cmd>Leet submit<CR>', '📤 Submit solution')
    map('n', '<leader>blT', '<cmd>Leet test<CR>', '🧪 Run tests')
    
    -- Session & content management
    map('n', '<leader>bls', '<cmd>Leet session<CR>', '🔗 Manage session') 
    map('n', '<leader>bly', '<cmd>Leet yank<CR>', '📋 Yank solution')
    
    -- Configuration & preferences
    map('n', '<leader>blg', '<cmd>Leet lang<CR>', '🌐 Change language')
    map('n', '<leader>blD', '<cmd>Leet desc<CR>', '📖 Toggle description')
    map('n', '<leader>blC', '<cmd>Leet cache<CR>', '💾 Cache operations')
    
    -- Quick access shortcuts in console mode
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'leetcode.nvim',
      callback = function()
        map('n', '<CR>', '<cmd>Leet run<CR>', '▶️  Run code')
        map('n', 's', '<cmd>Leet submit<CR>', '📤 Submit solution')
        map('n', 't', '<cmd>Leet test<CR>', '🧪 Run tests')
      end,
    })
  end,
}