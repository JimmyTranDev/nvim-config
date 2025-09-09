return {
  'Bekaboo/dropbar.nvim',
  -- optional, but required for fuzzy finder support
  event = { 'BufReadPost', 'BufNewFile' },
  cond = function()
    return not require('core.vscode').is_vscode() -- VSCode has its own breadcrumbs
  end,
  dependencies = {
    -- 'nvim-telescope/telescope-fzf-native.nvim',
    -- build = 'make'
  },
  config = function()
    local dropbar_api = require('dropbar.api')
    vim.keymap.set('n', '<Leader>d', dropbar_api.pick, { desc = 'Pick symbols in winbar' })
    vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
    vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select next context' })
  end,
}
