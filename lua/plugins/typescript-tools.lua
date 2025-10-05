return {
  'pmizio/typescript-tools.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
  ft = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' },
  types = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' },
  opts = {},
  keys = {
    {
      mode = 'n',
      '<leader>co',
      ':TSToolsOrganizeImports<CR>',
      desc = 'Organize Imports',
      silent = true,
    },
    { mode = 'n', '<leader>cs', ':TSToolsSortImports<CR>', desc = 'Sort Imports' },
    { mode = 'n', '<leader>ci', ':TSToolsRemoveUnusedImports<CR>', desc = 'Remove Unused Imports' },
    { mode = 'n', '<leader>cu', ':TSToolsRemoveUnused<CR>', desc = 'Remove All Unused' },
    { mode = 'n', '<leader>cc', ':TSToolsAddMissingImports<CR>', desc = 'Add Missing Imports' },
    { mode = 'n', '<leader>cf', ':TSToolsFixAll<CR>', desc = 'Fix All' },
    { mode = 'n', '<leader>cd', ':TSToolsGoToSourceDefinition<CR>', desc = 'Go to Source Definition' },
    { mode = 'n', '<leader>cR', ':TSToolsRenameFile<CR>', desc = 'Rename File' },
    { mode = 'n', '<leader>cr', ':TSToolsFileReferences<CR>', desc = 'File References' },
  },
}
