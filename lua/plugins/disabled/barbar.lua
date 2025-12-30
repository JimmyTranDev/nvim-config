return {
  'romgrk/barbar.nvim',
  dependencies = {
    'lewis6991/gitsigns.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  event = 'VimEnter',
  keys = {
    -- Buffer navigation
    { '<Leader>bp', '<Cmd>BufferPrevious<CR>', desc = '󰒮 Previous buffer' },
    { '<Leader>bn', '<Cmd>BufferNext<CR>', desc = '󰒭 Next buffer' },
    { '<Leader>bP', '<Cmd>BufferMovePrevious<CR>', desc = '󰜲 Move buffer left' },
    { '<Leader>bN', '<Cmd>BufferMoveNext<CR>', desc = '󰜵 Move buffer right' },

    -- Buffer selection by position
    { '<Leader>b1', '<Cmd>BufferGoto 1<CR>', desc = '󰲠 Go to buffer 1' },
    { '<Leader>b2', '<Cmd>BufferGoto 2<CR>', desc = '󰲢 Go to buffer 2' },
    { '<Leader>b3', '<Cmd>BufferGoto 3<CR>', desc = '󰲤 Go to buffer 3' },
    { '<Leader>b4', '<Cmd>BufferGoto 4<CR>', desc = '󰲦 Go to buffer 4' },
    { '<Leader>b5', '<Cmd>BufferGoto 5<CR>', desc = '󰲨 Go to buffer 5' },
    { '<Leader>b6', '<Cmd>BufferGoto 6<CR>', desc = '󰲪 Go to buffer 6' },
    { '<Leader>b7', '<Cmd>BufferGoto 7<CR>', desc = '󰲬 Go to buffer 7' },
    { '<Leader>b8', '<Cmd>BufferGoto 8<CR>', desc = '󰲮 Go to buffer 8' },
    { '<Leader>b9', '<Cmd>BufferGoto 9<CR>', desc = '󰲰 Go to buffer 9' },
    { '<Leader>bl', '<Cmd>BufferLast<CR>', desc = '󰘁 Go to last buffer' },

    -- Buffer management
    { '<Leader>bc', '<Cmd>BufferClose<CR>', desc = '󰅖 Close buffer' },
    { '<Leader>bC', '<Cmd>BufferRestore<CR>', desc = '󰁯 Restore buffer' },
    { '<Leader>bw', '<Cmd>BufferWipeout<CR>', desc = '󰩺 Wipeout buffer' },
    { '<Leader>bpin', '<Cmd>BufferPin<CR>', desc = '󰐃 Pin/unpin buffer' },

    -- Buffer operations
    { '<Leader>bpick', '<Cmd>BufferPick<CR>', desc = '󰒉 Pick buffer' },
    { '<Leader>bpd', '<Cmd>BufferPickDelete<CR>', desc = '󰒉 Pick delete buffer' },

    -- Close operations
    { '<Leader>bca', '<Cmd>BufferCloseAllButCurrent<CR>', desc = '󰅗 Close all but current' },
    { '<Leader>bcv', '<Cmd>BufferCloseAllButVisible<CR>', desc = '󰅗 Close all but visible' },
    { '<Leader>bcp', '<Cmd>BufferCloseAllButPinned<CR>', desc = '󰅗 Close all but pinned' },
    { '<Leader>bcc', '<Cmd>BufferCloseAllButCurrentOrPinned<CR>', desc = '󰅗 Close all but current/pinned' },
    { '<Leader>bcl', '<Cmd>BufferCloseBuffersLeft<CR>', desc = '󰅖 Close buffers left' },
    { '<Leader>bcr', '<Cmd>BufferCloseBuffersRight<CR>', desc = '󰅖 Close buffers right' },

    -- Sort operations
    { '<Leader>bsn', '<Cmd>BufferOrderByName<CR>', desc = '󰒺 Sort by name' },
    { '<Leader>bsd', '<Cmd>BufferOrderByDirectory<CR>', desc = '󰉋 Sort by directory' },
    { '<Leader>bsl', '<Cmd>BufferOrderByLanguage<CR>', desc = '󰗊 Sort by language' },
    { '<Leader>bsw', '<Cmd>BufferOrderByWindowNumber<CR>', desc = '󰖲 Sort by window' },
    { '<Leader>bsb', '<Cmd>BufferOrderByBufferNumber<CR>', desc = '󰎕 Sort by buffer number' },
  },
  opts = {
    animation = true,
    auto_hide = false,
    tabpages = true,
    clickable = true,
    focus_on_close = 'left',
    hide = { extensions = true, inactive = false },
    highlight_alternate = false,
    highlight_inactive_file_icons = false,
    highlight_visible = true,
    icons = {
      buffer_index = false,
      buffer_number = false,
      button = '',
      diagnostics = {
        [vim.diagnostic.severity.ERROR] = { enabled = true, icon = 'ﬀ' },
        [vim.diagnostic.severity.WARN] = { enabled = false },
        [vim.diagnostic.severity.INFO] = { enabled = false },
        [vim.diagnostic.severity.HINT] = { enabled = true },
      },
      gitsigns = {
        added = { enabled = true, icon = '+' },
        changed = { enabled = true, icon = '~' },
        deleted = { enabled = true, icon = '-' },
      },
      filetype = {
        custom_colors = false,
        enabled = true,
      },
      separator = { left = '▎', right = '' },
      separator_at_end = true,
      modified = { button = '●' },
      pinned = { button = '', filename = true },
      preset = 'default',
      alternate = { filetype = { enabled = false } },
      current = { buffer_index = true },
      inactive = { button = '×' },
      visible = { modified = { buffer_number = false } },
    },
    insert_at_end = false,
    insert_at_start = false,
    maximum_padding = 1,
    minimum_padding = 1,
    maximum_length = 30,
    minimum_length = 0,
    semantic_letters = true,
    sidebar_filetypes = {
      NvimTree = true,
      ['neo-tree'] = { event = 'BufWipeout' },
      Outline = { event = 'BufWinLeave', text = 'symbols-outline', align = 'right' },
    },
    letters = 'asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP',
    no_name_title = nil,
    sort = {
      ignore_case = true,
    },
  },
  version = '^1.0.0',
}
