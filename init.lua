-- Core Neovim Configuration
-- Load configuration modules in order of dependency

-- Plugin manager setup
require('core.lazy')

-- Basic options and settings
require('core.options')

-- Plugin configurations
require('core.plugins')

-- Autocommands and custom commands
require('core.commands')

-- Status line configuration
require('core.statusline')

require('core.keymaps')


-- Enhanced LSP and Treesitter activation for all file operations
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile', 'BufEnter' }, {
  callback = function(event)
    local buf = event.buf
    local filetype = vim.bo[buf].filetype
    
    -- Skip special buffers
    if filetype == '' or filetype == 'lazy' or filetype == 'mason' or filetype == 'help' then
      return
    end
    
    -- Ensure filetype is detected
    if filetype == '' then
      vim.bo[buf].filetype = vim.filetype.match({ buf = buf }) or ''
      filetype = vim.bo[buf].filetype
    end
    
    -- Enable Treesitter highlighting efficiently
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) and vim.treesitter.highlighter then
        if vim.treesitter.highlighter.active[buf] == nil then
          local ok, _ = pcall(vim.treesitter.start, buf)
          if not ok then
            pcall(vim.cmd, 'TSBufEnable highlight')
          end
        end
      end
    end, 1)
  end,
})
