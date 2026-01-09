local fileAction = require('custom.actions.files')

local function get_diagnostics_by_file()
  if vim.g.vscode then return {} end

  local diagnostics = vim.diagnostic.get()
  local by_file = {}

  for _, diag in ipairs(diagnostics) do
    local buf = diag.bufnr
    local filename = vim.api.nvim_buf_get_name(buf)
    if filename and filename ~= '' then
      if not by_file[filename] then by_file[filename] = { count = 0, diagnostics = {}, buf = buf } end
      by_file[filename].count = by_file[filename].count + 1
      table.insert(by_file[filename].diagnostics, diag)
    end
  end

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

local function show_diagnostics_picker()
  local items = get_diagnostics_by_file()

  Snacks.picker({
    title = 'Diagnostics by File',
    items = items,
    format = function(item, _) return { { item.text, 'Normal' } } end,
    confirm = function(picker, item)
      picker:close()
      vim.api.nvim_set_current_buf(item.buf)
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
  lazy = true,
  priority = 1000,
  event = 'UIEnter',
  opts = {
    bigfile = { enabled = true },
    dashboard = {
      enabled = true,
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
      layout = {
        layout = {},
      },
      formatters = {
        file = {
          truncate = 60,
        },
      },
      sources = {
        files = {
          exclude = { 'pnpm-lock.yaml', 'yarn.lock', 'package-lock.json', 'bun.lockb', 'bun.lock' },
        },
        grep = {
          exclude = { 'pnpm-lock.yaml', 'yarn.lock', 'package-lock.json', 'bun.lockb', 'bun.lock' },
        },
        explorer = {
          exclude = { 'pnpm-lock.yaml', 'yarn.lock', 'package-lock.json', 'bun.lockb', 'bun.lock' },
        },
      },
      jump = {
        jumplist = true,
        tagstack = false,
        reuse_win = true,
        close = true,
        match = false,
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
      '<leader>fd',
      function() Snacks.picker.git_status() end,
      desc = 'Git Status',
    },
    {
      '<leader>fjS',
      function()
        local stashes = vim.fn.systemlist('git stash list --oneline')
        if #stashes == 0 then
          vim.notify('No stashes found', vim.log.levels.INFO)
          return
        end

        local items = {}
        for i, stash in ipairs(stashes) do
          local stash_ref = 'stash@{' .. (i - 1) .. '}'
          table.insert(items, {
            text = stash,
            stash_ref = stash_ref,
          })
        end

        Snacks.picker({
          title = 'Git Stashes',
          items = items,
          format = function(item) return item.text end,
          confirm = function(picker, item)
            picker:close()
            local choice = vim.fn.input('Action (apply/pop/show/drop): ', 'show')
            if choice == 'apply' then
              vim.cmd('!git stash apply ' .. item.stash_ref)
            elseif choice == 'pop' then
              vim.cmd('!git stash pop ' .. item.stash_ref)
            elseif choice == 'show' then
              vim.cmd('!git stash show -p ' .. item.stash_ref)
            elseif choice == 'drop' then
              local confirm = vim.fn.input('Drop stash ' .. item.stash_ref .. '? (y/N): ')
              if confirm:lower() == 'y' then vim.cmd('!git stash drop ' .. item.stash_ref) end
            end
          end,
        })
      end,
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
