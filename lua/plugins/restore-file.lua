-- Restore the most recent file from oldfiles that belongs to the current working directory.
-- Uses noautocmd + deferred manual autocmd firing to avoid triggering LSP/plugins too early during startup.
return {
  'restore-file',
  virtual = true,
  lazy = false,
  config = function()
    vim.api.nvim_create_autocmd('UIEnter', {
      callback = function()
        if vim.fn.argc() > 0 then
          return
        end
        local cwd = vim.fn.getcwd()
        for _, file in ipairs(vim.v.oldfiles or {}) do
          local abs_file = vim.fn.fnamemodify(file, ':p')
          if vim.fn.filereadable(abs_file) == 1 and vim.startswith(vim.fn.fnamemodify(abs_file, ':h'), cwd) then
            vim.defer_fn(function()
              vim.cmd('noautocmd edit ' .. vim.fn.fnameescape(abs_file))
              pcall(vim.treesitter.start)
              vim.defer_fn(function()
                pcall(vim.api.nvim_exec_autocmds, 'BufReadPost', { buffer = 0 })
                pcall(vim.api.nvim_exec_autocmds, 'FileType', { buffer = 0 })
              end, 10)
            end, 50)
            break
          end
        end
      end,
      desc = 'Auto-open most recent file from current folder on startup',
    })
  end,
}
