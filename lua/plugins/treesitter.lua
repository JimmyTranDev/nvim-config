return {
  'nvim-treesitter/nvim-treesitter',
  lazy =false,
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
        -- Disable for large files
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
      },
      context_commentstring = {
        enable = true,
        enable_autocmd = false,
      },
    })
  end,
}
