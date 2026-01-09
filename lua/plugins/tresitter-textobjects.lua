return {
  'nvim-treesitter/nvim-treesitter-textobjects',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  lazy = false,
  config = function()
    require('nvim-treesitter.configs').setup({
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ap'] = '@parameter.outer',
            ['ip'] = '@parameter.inner',
          },
          selection_modes = {
            ['@function.outer'] = 'V',
            ['@parameter.outer'] = 'v',
          },
          include_surrounding_whitespace = true,
        },

        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            [']f'] = '@function.outer',
            [']p'] = '@parameter.outer',
          },
          goto_next_end = {
            [']F'] = '@function.outer',
            [']P'] = '@parameter.outer',
          },
          goto_previous_start = {
            ['[f'] = '@function.outer',
            ['[p'] = '@parameter.outer',
          },
          goto_previous_end = {
            ['[F'] = '@function.outer',
            ['[P'] = '@parameter.outer',
          },
        },

        swap = {
          enable = true,
          swap_next = {
            ['<leader>sp'] = '@parameter.inner',
            ['<leader>sf'] = '@function.outer',
          },
          swap_previous = {
            ['<leader>sP'] = '@parameter.inner',
            ['<leader>sF'] = '@function.outer',
          },
        },
      },
    })
  end,
}
