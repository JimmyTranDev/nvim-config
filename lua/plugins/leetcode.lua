return {
  'kawre/leetcode.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  cmd = 'Leet',
  build = ':TSUpdate html',
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
    map('n', '<leader>bl', '<cmd>Leet<CR>', '󰞷 Open LeetCode')
    map('n', '<leader>bm', '<cmd>Leet menu<CR>', '󰍉 LeetCode menu')  
    map('n', '<leader>bc', '<cmd>Leet console<CR>', '󰆍 Open console')
    map('n', '<leader>bi', '<cmd>Leet info<CR>', 'ℹ️  Problem info')
    
    -- Problem navigation & browsing
    map('n', '<leader>bL', '<cmd>Leet list<CR>', '📋 List problems')
    map('n', '<leader>bd', '<cmd>Leet daily<CR>', '📅 Daily challenge')  
    map('n', '<leader>bR', '<cmd>Leet random<CR>', '🎲 Random problem')
    
    -- Code execution & testing  
    map('n', '<leader>br', '<cmd>Leet run<CR>', '▶️  Run code')
    map('n', '<leader>bS', '<cmd>Leet submit<CR>', '📤 Submit solution')
    map('n', '<leader>bT', '<cmd>Leet test<CR>', '🧪 Run tests')
    
    -- Session & content management
    map('n', '<leader>bs', '<cmd>Leet session<CR>', '🔗 Manage session') 
    map('n', '<leader>by', '<cmd>Leet yank<CR>', '📋 Yank solution')
    
    -- Configuration & preferences
    map('n', '<leader>bg', '<cmd>Leet lang<CR>', '🌐 Change language')
    map('n', '<leader>bD', '<cmd>Leet desc<CR>', '📖 Toggle description')
    map('n', '<leader>bC', '<cmd>Leet cache<CR>', '💾 Cache operations')
    
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