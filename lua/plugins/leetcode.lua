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
}