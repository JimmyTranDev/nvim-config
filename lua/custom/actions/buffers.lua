local M = {}

function M.close_other_buffers_and_create_empty()
  local current_buf = vim.api.nvim_get_current_buf()
  local buffers_to_keep = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
      local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')

      if filetype == 'toggleterm' or bufname:match('term://') or bufname:match('opencode') or filetype == 'opencode' or buftype == 'terminal' then
        buffers_to_keep[bufnr] = true
      end
    end
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) and not buffers_to_keep[bufnr] and bufnr ~= current_buf then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
    end
  end

  vim.cmd('enew')
  vim.api.nvim_buf_set_name(0, '')
end

return M
