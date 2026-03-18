return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  config = function()
    require('nvim-treesitter').setup({
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
        'fish',
        'git_config',
        'git_rebase',
        'gitattributes',
        'gitcommit',
        'gitignore',
        'go',
      },
      auto_install = false,
      sync_install = false,
      ignore_install = {},
    })

    vim.treesitter.language.register('markdown', 'mdx')
  end,
}
