return {
  'otavioschwanck/arrow.nvim',
  keys = { 'm', "'" },
  dependencies = {
    { 'nvim-tree/nvim-web-devicons' },
    -- or if using `mini.icons`
    -- { "echasnovski/mini.icons" },
  },
  opts = {
    show_icons = true,
    leader_key = "'", -- Recommended to be a single key
    buffer_leader_key = '\\', -- Per Buffer Mappings
  },
}
