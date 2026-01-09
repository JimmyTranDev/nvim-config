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

    -- Auto-open OpenCode when Neovim starts and open the most recent file from current folder (if any)
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        vim.defer_fn(function()
          -- Get current working directory
          local cwd = vim.fn.getcwd()
          -- Try to find the most recently opened file from the current folder
          local oldfiles = vim.v.oldfiles
          if oldfiles and #oldfiles > 0 then
            -- Find the first file that still exists and is in the current directory
            for _, file in ipairs(oldfiles) do
              local abs_file = vim.fn.fnamemodify(file, ':p')
              local file_dir = vim.fn.fnamemodify(abs_file, ':h')
              if vim.fn.filereadable(abs_file) == 1 and vim.startswith(file_dir, cwd) then
                vim.cmd('edit ' .. vim.fn.fnameescape(abs_file))
                break
              end
            end
            -- If no recent file found in current folder, don't open any file
          end
          -- Toggle OpenCode regardless of whether a file was opened
          require('opencode').toggle()
        end, 200) -- 200ms delay to ensure everything is loaded
      end,
      desc = 'Auto-open OpenCode and most recent file from current folder (if any) on startup',
    })
  end,
}
