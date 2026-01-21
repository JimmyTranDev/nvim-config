return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
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

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        disable = function(lang, buf)
          local max_filesize = 50 * 1024
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then return true end
          local max_lines = 10000
          if vim.api.nvim_buf_line_count(buf) > max_lines then return true end
        end,
        use_languagetree = true,
      },
      context_commentstring = {
        enable = true,
        enable_autocmd = false,
      },
    })
  end,
}
