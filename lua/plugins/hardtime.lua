return {
  'm4xshen/hardtime.nvim',
  dependencies = { 'MunifTanjim/nui.nvim' },
  event = 'VeryLazy',
  opts = {
    max_time = 1000,
    max_count = 3,
    disable_mouse = true,
    hint = true,
    notification = true,
    allow_different_key = true,
    enabled = true,
    restriction_mode = 'block',
  },
}