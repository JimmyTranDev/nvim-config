return {
  'folke/todo-comments.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    {
      '<leader>ft',
      function() Snacks.picker.todo_comments() end,
      desc = 'Todo',
    },
    {
      '<leader>fT',
      function() Snacks.picker.todo_comments({ keywords = { 'TODO', 'FIX', 'FIXME' } }) end,
      desc = 'Todo/Fix/Fixme',
    },
  },
  config = function() require('todo-comments').setup() end,
}
