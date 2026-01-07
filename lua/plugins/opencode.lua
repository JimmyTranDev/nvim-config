return {
  'NickvanDyke/opencode.nvim',
  dependencies = {
    -- Recommended for `ask()` and `select()`.
    -- Required for `snacks` provider.
    ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
    { 'folke/snacks.nvim', opts = { input = {}, picker = {}, terminal = {} } },
  },
  lazy = false,
  keys = {
    { '<C-a>', function() require('opencode').ask('@this: ', { submit = true }) end, mode = { 'n', 'x' }, desc = 'Ask opencode' },
    { '<C-x>', function() require('opencode').select() end, mode = { 'n', 'x' }, desc = 'Execute opencode action…' },
    { '<C-.>', function() require('opencode').toggle() end, mode = { 'n', 't' }, desc = 'Toggle opencode' },
    { '<leader>aa', function() return require('opencode').operator('@this ') end, mode = { 'n', 'x' }, expr = true, desc = 'Add range to opencode' },
    { '<leader>al', function() return require('opencode').operator('@this ') .. '_' end, mode = 'n', expr = true, desc = 'Add line to opencode' },
    { '<S-C-u>', function() require('opencode').command('session.half.page.up') end, mode = 'n', desc = 'opencode half page up' },
    { '<S-C-d>', function() require('opencode').command('session.half.page.down') end, mode = 'n', desc = 'opencode half page down' },
    { '+', '<C-a>', mode = 'n', desc = 'Increment', noremap = true },
    { '-', '<C-x>', mode = 'n', desc = 'Decrement', noremap = true },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition".
    }

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Auto-open OpenCode when Neovim starts
    -- vim.api.nvim_create_autocmd('VimEnter', {
    --   callback = function()
    --     vim.defer_fn(function()
    --       require('opencode').toggle()
    --     end, 1000) -- 1 second delay to ensure everything is loaded
    --   end,
    --   desc = 'Auto-open OpenCode on startup',
    -- })
  end,
}
