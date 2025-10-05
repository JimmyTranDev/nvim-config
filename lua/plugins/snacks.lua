local fileAction = require('custom.actions.files')

-- Function to group diagnostics by file
local function get_diagnostics_by_file()
  -- Only run if not in VSCode (VSCode handles diagnostics UI)
  if vim.g.vscode then return {} end

  local diagnostics = vim.diagnostic.get() -- Get all diagnostics
  local by_file = {}

  -- Group diagnostics by buffer (file)
  for _, diag in ipairs(diagnostics) do
    local buf = diag.bufnr
    local filename = vim.api.nvim_buf_get_name(buf)
    if filename and filename ~= '' then
      if not by_file[filename] then by_file[filename] = { count = 0, diagnostics = {}, buf = buf } end
      by_file[filename].count = by_file[filename].count + 1
      table.insert(by_file[filename].diagnostics, diag)
    end
  end

  -- Convert to picker items
  local items = {}
  for filename, data in pairs(by_file) do
    table.insert(items, {
      idx = #items + 1,
      text = string.format('%s (%d diagnostics)', filename, data.count),
      filename = filename,
      diagnostics = data.diagnostics,
      buf = data.buf,
    })
  end

  return items
end

-- Custom picker to show diagnostics grouped by file
local function show_diagnostics_picker()
  local items = get_diagnostics_by_file()

  Snacks.picker({
    title = 'Diagnostics by File',
    items = items,
    format = function(item, _) return { { item.text, 'Normal' } } end,
    confirm = function(picker, item)
      picker:close()
      -- Open the file in the buffer
      vim.api.nvim_set_current_buf(item.buf)
      -- Optionally, show all diagnostics for this file using trouble.nvim
      require('trouble').open({
        mode = 'diagnostics',
        filter = { buf = item.buf },
      })
    end,
    layout = { preset = 'default', preview = false },
  })
end

return {
  'folke/snacks.nvim',
  lazy = true, -- Enable lazy loading
  priority = 1000,
  event = 'UIEnter',
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    -- TODO: make dashboard work
    dashboard = {
      enabled = false,
      sections = {
        { section = 'header' },
        {
          icon = ' ',
          title = 'Recent Files',
          section = 'recent_files',
          indent = 2,
          padding = 1,
          cwd = true,
        },
        -- { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
        { icon = ' ', title = 'Keymaps', section = 'keys', indent = 2, padding = 1 },
        { section = 'startup' },
      },
    },
    explorer = { enabled = false },
    indent = { enabled = true },
    input = { enabled = true },
    picker = {
      enabled = true,
      cwd = true,
      layout = { -- the layout config
        layout = { -- the layout itself
          -- width = 0, -- 0 is max
          -- height = 0,
        },
      },
      formatters = {
        file = {
          -- filename_first = false, -- display filename before the file path
          truncate = 60, -- truncate the file path to (roughly) this length
          -- filename_only = false,  -- only show the filename
          -- icon_width = 2,         -- width of the icon (in characters)
          -- git_status_hl = true,   -- use the git status highlight group for the filename
        },
      },
      sources = {
        files = {
          exclude = { 'pnpm-lock.yaml' }, -- Ignore package.json in file picker
        },
        grep = {
          exclude = { 'pnpm-lock.yaml' }, -- Ignore package.json in grep picker
        },
        explorer = {
          exclude = { 'pnpm-lock.yaml' }, -- Ignore package.json in explorer
        },
      },
      jump = {
        jumplist = true, -- save the current position in the jumplist
        tagstack = false, -- save the current position in the tagstack
        reuse_win = true, -- reuse an existing window if the buffer is already open
        close = true, -- close the picker when jumping/editing to a location (defaults to true)
        match = false, -- jump to the first match position. (useful for `lines`)
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
  },
  keys = {
    -- LSP
    {
      'ga',
      vim.lsp.buf.code_action,
      desc = 'LSP Code Action',
      mode = { 'n', 'v' },
    },
    {
      'gm',
      vim.diagnostic.open_float,
      desc = 'LSP Diagnostic',
      mode = { 'n', 'v' },
    },
    {
      'gh',
      vim.lsp.buf.hover,
      desc = 'LSP Hover',
      mode = { 'n', 'v' },
    },
    {
      'gl',
      vim.lsp.buf.format,
      desc = 'LSP Format',
      mode = { 'n', 'v' },
    },
    {
      'gd',
      function() Snacks.picker.lsp_definitions() end,
      desc = 'Goto Definition',
    },
    {
      'gD',
      function() Snacks.picker.lsp_declarations() end,
      desc = 'Goto Declaration',
    },
    {
      'gz',
      function() Snacks.picker.lsp_references() end,
      nowait = true,
      desc = 'References',
    },
    {
      'gi',
      function() Snacks.picker.lsp_implementations() end,
      desc = 'Goto Implementation',
    },
    {
      'gH',
      function() Snacks.picker.lsp_type_definitions() end,
      desc = 'Goto Type Definition',
    },
    {
      'gs',
      function() Snacks.picker.lsp_symbols() end,
      desc = 'LSP Symbols',
    },
    {
      'gS',
      function() Snacks.picker.lsp_workspace_symbols() end,
      desc = 'LSP Workspace Symbols',
    },
    {
      'gx',
      fileAction.yankWordAndOpen,
      desc = 'Open File Under Cursor',
      mode = { 'n', 'v' },
    },

    -- Top Pickers & Explorer
    {
      '<leader>ff',
      function() Snacks.picker.smart({ hidden = true, filter = { cwd = true } }) end,
      desc = 'Smart Find Files',
    },
    {
      '<leader>fF',
      function() Snacks.picker.files({ hidden = true, filter = { cwd = true } }) end,
      desc = 'Find Files',
    },
    {
      '<leader>fg',
      function() Snacks.picker.grep({ hidden = true }) end,
      desc = 'Grep',
    },
    {
      '<leader>fr',
      function() Snacks.picker.resume() end,
      desc = 'Resume',
    },
    {
      '<leader>fu',
      function() Snacks.picker.undo() end,
      desc = 'Undo History',
    },
    {
      '<leader>fe',
      function() Snacks.picker.diagnostics() end,
      desc = 'Diagnostics',
    },
    -- { "<leader>fE",   function() Snacks.picker.diagnostics_buffer() end,                      desc = "Buffer Diagnostics" },
    {
      '<leader>fE',
      show_diagnostics_picker,
      desc = 'Diagnostics',
    },

    {
      '<leader>fc',
      function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end,
      desc = 'Find Config File',
    },
    {
      '<leader>fp',
      function() Snacks.picker.projects() end,
      desc = 'Projects',
    },
    {
      '<leader>fo',
      function() Snacks.picker.recent() end,
      desc = 'Recent',
    },
    {
      '<leader>fg',
      function() Snacks.picker.grep() end,
      desc = 'Grep',
    },
    {
      '<leader>fw',
      function() Snacks.picker.grep_word() end,
      desc = 'Visual selection or word',
      mode = { 'n', 'x' },
    },
    {
      '<leader>fl',
      function() Snacks.picker.lines() end,
      desc = 'Buffer Lines',
    },
    {
      '<leader>fn',
      function() Snacks.picker.notifications({ preview = false }) end,
      desc = 'Notification History',
    },
    {
      '<leader>fc',
      function() Snacks.picker.commands() end,
      desc = 'Commands',
    },
    -- { "<leader>fe",        function() Snacks.explorer() end,                                       desc = "File Explorer" },
    -- { "<leader>fb,",       function() Snacks.picker.buffers() end,                                 desc = "Buffers" },
    -- { "<leader>fsB",       function() Snacks.picker.grep_buffers() end,                            desc = "Grep Open Buffers" },

    -- Git
    {
      '<leader>fjt',
      function() Snacks.picker.git_files() end,
      desc = 'Find Git Files',
    },
    {
      '<leader>fjb',
      function() Snacks.picker.git_branches() end,
      desc = 'Git Branches',
    },
    {
      '<leader>fjl',
      function() Snacks.picker.git_log() end,
      desc = 'Git Log',
    },
    {
      '<leader>fjL',
      function() Snacks.picker.git_log_line() end,
      desc = 'Git Log Line',
    },
    {
      '<leader>fjs',
      function() Snacks.picker.git_status() end,
      desc = 'Git Status',
    },
    {
      '<leader>fjS',
      function() Snacks.picker.git_stash() end,
      desc = 'Git Stash',
    },
    {
      '<leader>fjd',
      function() Snacks.picker.git_diff() end,
      desc = 'Git Diff (Hunks)',
    },
    {
      '<leader>fjD',
      function() Snacks.picker.git_diff({ args = { 'origin/HEAD' } }) end,
      desc = 'Git Diff vs Origin',
    },
    {
      '<leader>fjf',
      function() Snacks.picker.git_log_file() end,
      desc = 'Git Log File',
    },
    {
      '<leader>fjc',
      function() Snacks.picker.grep({ search = '<<<<<<<' }) end,
      desc = 'Find Git Conflicts',
    },
    {
      '<leader>fjh',
      function() require('custom.actions.github').open_current_commit_in_github() end,
      desc = 'Open Current Commit in GitHub',
    },

    -- Search
    {
      '<leader>fv/',
      function() Snacks.picker.search_history() end,
      desc = 'Search History',
    },
    {
      '<leader>fvC',
      function() Snacks.picker.command_history() end,
      desc = 'Command History',
    },
    {
      '<leader>fvH',
      function() Snacks.picker.highlights() end,
      desc = 'Highlights',
    },
    {
      '<leader>fvM',
      function() Snacks.picker.man() end,
      desc = 'Man Pages',
    },
    {
      '<leader>fv"',
      function() Snacks.picker.registers() end,
      desc = 'Registers',
    },
    {
      '<leader>fva',
      function() Snacks.picker.autocmds() end,
      desc = 'Autocmds',
    },
    {
      '<leader>fvf',
      function() Snacks.picker.colorschemes() end,
      desc = 'Colorschemes',
    },
    {
      '<leader>fvh',
      function() Snacks.picker.help() end,
      desc = 'Help Pages',
    },
    {
      '<leader>fvi',
      function() Snacks.picker.icons() end,
      desc = 'Icons',
    },
    {
      '<leader>fvj',
      function() Snacks.picker.jumps() end,
      desc = 'Jumps',
    },
    {
      '<leader>fvk',
      function() Snacks.picker.keymaps() end,
      desc = 'Keymaps',
    },
    {
      '<leader>fvl',
      function() Snacks.picker.loclist() end,
      desc = 'Location List',
    },
    {
      '<leader>fvm',
      function() Snacks.picker.marks() end,
      desc = 'Marks',
    },
    {
      '<leader>fvp',
      function() Snacks.picker.lazy() end,
      desc = 'Search for Plugin Spec',
    },
    {
      '<leader>fvq',
      function() Snacks.picker.qflist() end,
      desc = 'Quickfix List',
    },

    -- Other
    -- { "<leader>fz",        function() Snacks.zen() end,                                            desc = "Toggle Zen Mode" },
    -- { "<leader>fZ",        function() Snacks.zen.zoom() end,                                       desc = "Toggle Zoom" },
    -- { "<leader>f.",        function() Snacks.scratch() end,                                        desc = "Toggle Scratch Buffer" },
    -- { "<leader>fS",        function() Snacks.scratch.select() end,                                 desc = "Select Scratch Buffer" },
    -- { "<leader>fn",        function() Snacks.notifier.show_history() end,                          desc = "Notification History" },
    -- { "<leader>fbd",       function() Snacks.bufdelete() end,                                      desc = "Delete Buffer" },
    -- { "<leader>fcR",       function() Snacks.rename.rename_file() end,                             desc = "Rename File" },
    -- { "<leader>fgB",       function() Snacks.gitbrowse() end,                                      desc = "Git Browse",               mode = { "n", "v" } },
    -- { "<leader>fgg",       function() Snacks.lazygit() end,                                        desc = "Lazygit" },
    -- { "<leader>fun",       function() Snacks.notifier.hide() end,                                  desc = "Dismiss All Notifications" },
    -- { "<c-/>",             function() Snacks.terminal() end,                                       desc = "Toggle Terminal" },
    -- { "<c-_>",             function() Snacks.terminal() end,                                       desc = "which_key_ignore" },
    -- { "]]",                function() Snacks.words.jump(vim.v.count1) end,                         desc = "Next Reference",           mode = { "n", "t" } },
    -- { "[[",                function() Snacks.words.jump(-vim.v.count1) end,                        desc = "Prev Reference",           mode = { "n", "t" } },
    {
      '<leader>fN',
      desc = 'Neovim News',
      function()
        Snacks.win({
          file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = 'yes',
            statuscolumn = ' ',
            conceallevel = 3,
          },
        })
      end,
    },
  },
}
