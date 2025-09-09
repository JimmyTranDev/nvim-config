-- tailwind-tools.lua
return {
  'luckasRanarison/tailwind-tools.nvim',
  name = 'tailwind-tools',
  build = ':UpdateRemotePlugins',
  ft = { 'html', 'css', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'svelte', 'vue' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    -- "nvim-telescope/telescope.nvim", -- optional
    'neovim/nvim-lspconfig', -- optional
  },
  opts = {}, -- your configuration
}
