return {
  'NickvanDyke/opencode.nvim',
  dependencies = {
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
    vim.g.opencode_opts = {}

    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        vim.defer_fn(function()
          local cwd = vim.fn.getcwd()
          for _, file in ipairs(vim.v.oldfiles or {}) do
            local abs_file = vim.fn.fnamemodify(file, ':p')
            if vim.fn.filereadable(abs_file) == 1 and vim.startswith(vim.fn.fnamemodify(abs_file, ':h'), cwd) then
              vim.cmd('edit ' .. vim.fn.fnameescape(abs_file))
              break
            end
          end
          -- require('opencode').toggle()
        end, 200)
      end,
      desc = 'Auto-open OpenCode and most recent file from current folder (if any) on startup',
    })
  end,
}
