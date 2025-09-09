return {
  'artemave/workspace-diagnostics.nvim',
  cond = function()
    return not require('core.vscode').is_vscode() -- VSCode manages its own diagnostics
  end,
  keys = {
    {
      mode = 'n',
      '<leader>fx',
      function()
        for _, client in ipairs(vim.lsp.get_clients()) do
          require('workspace-diagnostics').populate_workspace_diagnostics(client, 0)
        end
      end,
      desc = 'Workspace Diagnostics',
    },
  },
  config = function() require('lazy').setup({ 'artemave/workspace-diagnostics.nvim' }) end,
}
