local M = {}

M.refresh_all_lsps = function()
  for _, client in pairs(vim.lsp.get_clients()) do
    if client and client.name then
      vim.lsp.stop_client(client.id)
    end
  end
  vim.cmd('edit')
  vim.cmd('LspStart')
end

return M
