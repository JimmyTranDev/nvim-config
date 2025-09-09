return {
  'nvim-treesitter/nvim-treesitter',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  cmd = { 'TSUpdate', 'TSInstall' },
  config = function()
    require('nvim-treesitter.configs').setup({
      ensure_installed = {
        'lua',
        'vim',
        'vimdoc',
        'query',
        'javascript',
        'typescript',
        'tsx',
        'json',
        'jsonc',
        'html',
        'css',
        'scss',
        'yaml',
        'toml',
        'markdown',
        'markdown_inline',
        'python',
        'java',
        'kotlin',
        'bash',
        'fish', -- removed 'zsh' as it's not available
        'git_config',
        'git_rebase',
        'gitattributes',
        'gitcommit',
        'gitignore',
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      context_commentstring = {
        enable = true,
        enable_autocmd = false,
      },
    })
  end,
}
