return {
  'NickvanDyke/opencode.nvim',
  dependencies = {
    { 'folke/snacks.nvim', opts = { input = {}, picker = {}, terminal = {} } },
  },
  lazy = false,
  keys = {
    { '<C-a>', function() require('opencode').ask('@this: ', { submit = true }) end, mode = { 'n', 'x' }, desc = '󰚴 Ask opencode' },
    { '<C-.>', function() require('opencode').toggle() end, mode = { 'n', 't' }, desc = '󰚴 Toggle opencode' },
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
      desc = '󰚴 Auto-open OpenCode and most recent file from current folder (if any) on startup',
    })
  end,
}
