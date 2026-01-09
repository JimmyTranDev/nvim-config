return {
  'sQVe/sort.nvim',
  cmd = { 'Sort' },
  config = function()
    require('sort').setup({
      default_mappings = false,
    })
  end,
  keys = {
    { '<leader>ss', ':Sort<CR>', mode = { 'n', 'v' }, desc = 'Sort lines' },
    { '<leader>si', ':Sort i<CR>', mode = { 'n', 'v' }, desc = 'Sort lines (ignore case)' },
    { '<leader>su', ':Sort u<CR>', mode = { 'n', 'v' }, desc = 'Sort lines (unique)' },
    { '<leader>sr', ':Sort!<CR>', mode = { 'n', 'v' }, desc = 'Sort lines (reverse)' },
    { '<leader>sn', ':Sort n<CR>', mode = { 'n', 'v' }, desc = 'Sort lines (numeric)' },
    { '<leader>sl', ':Sort l<CR>', mode = { 'n', 'v' }, desc = 'Sort lines (by length)' },
  },
}
