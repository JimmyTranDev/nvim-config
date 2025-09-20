return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
  },
  cmd = {
    'DBUI',
    'DBUIToggle',
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  keys = {
    { mode = 'n', '<leader><leader>dd', ':DBUI<CR>', desc = 'UI', silent = true },
    { mode = 'n', '<leader><leader>dt', ':DBUIToggle<CR>', desc = 'Toggle UI', silent = true },
    { mode = 'n', '<leader><leader>da', ':DBUIAddConnection<CR>', desc = 'Add Connection', silent = true },
    { mode = 'n', '<leader><leader>df', ':DBUIFindBuffer<CR>', desc = 'Find Buffer', silent = true },
  },
  init = function()
    -- Your DBUI configuration
    vim.g.db_ui_use_nerd_fonts = 1
  end,
}
