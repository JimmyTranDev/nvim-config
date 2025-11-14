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
      auto_install = false, -- Disable auto-install for faster startup
      sync_install = false, -- Don't block on installation
      ignore_install = {}, -- Languages to ignore
      
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        -- Disable for large files (optimized threshold)
        disable = function(lang, buf)
          local max_filesize = 50 * 1024 -- 50 KB (reduced from 100KB)
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
          -- Disable for very long lines (performance killer)
          local max_lines = 10000
          if vim.api.nvim_buf_line_count(buf) > max_lines then
            return true
          end
        end,
        -- Use faster update time
        use_languagetree = true,
      },
      context_commentstring = {
        enable = true,
        enable_autocmd = false,
      },
    })
  end,
}
