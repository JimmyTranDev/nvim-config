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
      function()
        -- Step 1: Fix all TypeScript issues first (most comprehensive fix)
        vim.cmd('TSToolsFixAll')
        vim.defer_fn(function()
          -- Step 2: Remove unused imports and code
          vim.cmd('TSToolsRemoveUnusedImports')
          vim.defer_fn(function()
            vim.cmd('TSToolsRemoveUnused')
            vim.defer_fn(function()
              -- Step 3: Add any missing imports
              vim.cmd('TSToolsAddMissingImports')
              vim.defer_fn(function()
                -- Step 4: Organize and sort imports (final cleanup)
                vim.cmd('TSToolsOrganizeImports')
                vim.defer_fn(function()
                  vim.cmd('TSToolsSortImports')
                  vim.notify('Complete TypeScript cleanup finished: fixed all issues, cleaned imports, organized code', vim.log.levels.INFO)
                end, 100)
              end, 100)
            end, 100)
          end, 100)
        end, 200) -- Longer delay for FixAll to complete
      end,
      desc = 'Complete TS Cleanup (fix all, clean imports, organize)',
      silent = true,
    },
    -- { mode = 'n', '<leader>cd', ':TSToolsGoToSourceDefinition<CR>', desc = 'Go to Source Definition' },
    -- { mode = 'n', '<leader>cR', ':TSToolsRenameFile<CR>', desc = 'Rename File' },
    -- { mode = 'n', '<leader>cr', ':TSToolsFileReferences<CR>', desc = 'File References' },
  },
}
