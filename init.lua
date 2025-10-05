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

-- Open directly into last file (skip dashboard)
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    local function setup_buffer()
      -- Single timer for buffer setup
      vim.defer_fn(function()
        vim.cmd('edit')
        local buf = vim.api.nvim_get_current_buf()
        -- Only trigger events if buffer has content
        if vim.api.nvim_buf_get_name(buf) ~= '' then
          vim.api.nvim_exec_autocmds('BufRead', { buffer = buf })
        end
      end, 5) -- Reduced from 10ms
    end

    if vim.fn.argc() == 0 then
      require('custom.actions.recent').open_most_recent_in_cwd()
      if vim.api.nvim_buf_get_name(0) ~= '' then
        setup_buffer()
      end
    else
      setup_buffer()
    end
  end,
})

-- Optimized LSP and Treesitter activation
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  once = false,
  callback = function(event)
    local buf = event.buf
    local filetype = vim.bo[buf].filetype
    
    -- Skip special buffers
    if filetype == '' or filetype == 'lazy' or filetype == 'mason' or filetype == 'help' then
      return
    end
    
    -- Enable Treesitter highlighting efficiently
    if vim.treesitter.highlighter and vim.treesitter.highlighter.active[buf] == nil then
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(buf) then
          pcall(vim.cmd, 'TSBufEnable highlight')
        end
      end, 1)
    end
  end,
})
