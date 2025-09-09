return {
  'nvim-lualine/lualine.nvim',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  cond = function() return not require('core.vscode').is_vscode() end,
}
