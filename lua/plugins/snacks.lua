local function get_diagnostics_by_file()
  if vim.g.vscode then return {} end

  local diagnostics = vim.diagnostic.get()
  local by_file = {}

  for _, diag in ipairs(diagnostics) do
    local buf = diag.bufnr
    local filename = vim.api.nvim_buf_get_name(buf)
    if filename and filename ~= '' then
      if not by_file[filename] then by_file[filename] = { errors = 0, warnings = 0, info = 0, hints = 0, total = 0, diagnostics = {}, buf = buf } end
      by_file[filename].total = by_file[filename].total + 1
      if diag.severity == vim.diagnostic.severity.ERROR then
        by_file[filename].errors = by_file[filename].errors + 1
      elseif diag.severity == vim.diagnostic.severity.WARN then
        by_file[filename].warnings = by_file[filename].warnings + 1
      elseif diag.severity == vim.diagnostic.severity.INFO then
        by_file[filename].info = by_file[filename].info + 1
      else
        by_file[filename].hints = by_file[filename].hints + 1
      end
      table.insert(by_file[filename].diagnostics, diag)
    end
  end

  local items = {}
  for filename, data in pairs(by_file) do
    local max_severity = data.errors > 0 and 'error' or data.warnings > 0 and 'warn' or data.info > 0 and 'info' or 'hint'
    table.insert(items, {
      idx = #items + 1,
      text = vim.fn.fnamemodify(filename, ':~:.'),
      filename = filename,
      diagnostics = data.diagnostics,
      buf = data.buf,
      errors = data.errors,
      warnings = data.warnings,
      info = data.info,
      hints = data.hints,
      total = data.total,
      max_severity = max_severity,
    })
  end

  table.sort(items, function(a, b)
    local severity_order = { error = 1, warn = 2, info = 3, hint = 4 }
    local a_sev = severity_order[a.max_severity] or 5
    local b_sev = severity_order[b.max_severity] or 5
    if a_sev ~= b_sev then return a_sev < b_sev end
    return a.total > b.total
  end)

  return items
end

local function get_package_json_packages()
  local package_json_path = vim.fn.getcwd() .. '/package.json'
  local file = io.open(package_json_path, 'r')
  if not file then return nil end

  local content = file:read('*a')
  file:close()

  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok or not data then return nil end

  local packages = {}
  local function add_packages(deps, dep_type)
    if deps then
      for name, version in pairs(deps) do
        table.insert(packages, {
          name = name,
          version = version,
          type = dep_type,
          text = name .. ' @ ' .. version .. ' (' .. dep_type .. ')',
        })
      end
    end
  end

  add_packages(data.dependencies, 'dependencies')
  add_packages(data.devDependencies, 'devDependencies')
  add_packages(data.peerDependencies, 'peerDependencies')
  add_packages(data.optionalDependencies, 'optionalDependencies')

  table.sort(packages, function(a, b) return a.name < b.name end)
  return packages
end

local SEVERITY_HL = {
  error = 'DiagnosticError',
  warn = 'DiagnosticWarn',
  info = 'DiagnosticInfo',
  hint = 'DiagnosticHint',
}

local SEVERITY_ICON = {
  error = ' ',
  warn = '󰀨 ',
  info = ' ',
  hint = '󰠠 ',
}

local DEP_TYPE_HL = {
  dependencies = 'DiagnosticOk',
  devDependencies = 'DiagnosticInfo',
  peerDependencies = 'DiagnosticWarn',
  optionalDependencies = 'DiagnosticHint',
}

local function format_diagnostics_item(item)
  local parts = {}
  local hl = SEVERITY_HL[item.max_severity] or 'Normal'
  local icon = SEVERITY_ICON[item.max_severity] or ''

  table.insert(parts, { icon, hl })
  table.insert(parts, { item.text .. ' ', 'Normal' })

  if item.errors > 0 then table.insert(parts, { ' ' .. item.errors .. ' ', 'DiagnosticError' }) end
  if item.warnings > 0 then table.insert(parts, { '󰀨 ' .. item.warnings .. ' ', 'DiagnosticWarn' }) end
  if item.info > 0 then table.insert(parts, { ' ' .. item.info .. ' ', 'DiagnosticInfo' }) end
  if item.hints > 0 then table.insert(parts, { '󰠠 ' .. item.hints .. ' ', 'DiagnosticHint' }) end

  return parts
end

local function format_package_item(item)
  local type_hl = DEP_TYPE_HL[item.type] or 'Normal'
  return {
    { item.name, type_hl },
    { ' @ ', 'Comment' },
    { item.version, 'String' },
    { ' (' .. item.type .. ')', 'Comment' },
  }
end

local function show_package_json_picker()
  local packages = get_package_json_packages()
  if not packages then
    vim.notify('No package.json found in current directory', vim.log.levels.WARN)
    return
  end

  if #packages == 0 then
    vim.notify('No packages found in package.json', vim.log.levels.INFO)
    return
  end

  Snacks.picker({
    title = 'Package.json Packages',
    items = packages,
    format = function(item) return format_package_item(item) end,
    confirm = function(picker, item)
      picker:close()
      local actions = {
        { name = 'Update to latest', value = 'update' },
        { name = 'Delete package', value = 'delete' },
        { name = 'Open on npm', value = 'npm' },
        { name = 'Cancel', value = 'cancel' },
      }

      vim.ui.select(actions, {
        prompt = 'Action for ' .. item.name .. ':',
        format_item = function(a) return a.name end,
      }, function(action)
        if not action or action.value == 'cancel' then return end

        if action.value == 'update' then
          local cmd = 'npm install ' .. item.name .. '@latest'
          if item.type == 'devDependencies' then cmd = cmd .. ' --save-dev' end
          vim.notify('Running: ' .. cmd, vim.log.levels.INFO)
          vim.fn.jobstart(cmd, {
            on_exit = function(_, code)
              if code == 0 then
                vim.notify('Updated ' .. item.name .. ' to latest', vim.log.levels.INFO)
              else
                vim.notify('Failed to update ' .. item.name, vim.log.levels.ERROR)
              end
            end,
          })
        elseif action.value == 'delete' then
          local cmd = 'npm uninstall ' .. item.name
          vim.notify('Running: ' .. cmd, vim.log.levels.INFO)
          vim.fn.jobstart(cmd, {
            on_exit = function(_, code)
              if code == 0 then
                vim.notify('Removed ' .. item.name, vim.log.levels.INFO)
              else
                vim.notify('Failed to remove ' .. item.name, vim.log.levels.ERROR)
              end
            end,
          })
        elseif action.value == 'npm' then
          vim.fn.system('open https://www.npmjs.com/package/' .. item.name)
        end
      end)
    end,
  })
end

local function show_diagnostics_picker()
  local items = get_diagnostics_by_file()

  Snacks.picker({
    title = 'Diagnostics by File',
    items = items,
    format = function(item) return format_diagnostics_item(item) end,
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
          icon = ' ',
          title = 'Recent Files',
          section = 'recent_files',
          indent = 2,
          padding = 1,
          cwd = true,
        },
        { icon = ' ', title = 'Keymaps', section = 'keys', indent = 2, padding = 1 },
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
      '<leader>fs',
      function() Snacks.picker.lsp_symbols() end,
      desc = 'LSP Symbols',
    },
    {
      '<leader>fS',
      function() Snacks.picker.lsp_workspace_symbols() end,
      desc = 'LSP Workspace Symbols',
    },
    {
      'gx',
      require('custom.actions.files').yank_word_and_open,
      desc = 'Open File Under Cursor',
      mode = { 'n', 'v' },
    },

    {
      '<leader>ff',
      function() Snacks.picker.smart({ hidden = true, filter = { cwd = true } }) end,
      desc = 'Smart Find Files',
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
      '<leader>fw',
      function() Snacks.picker.grep_word() end,
      desc = 'Visual selection or word',
      mode = { 'n', 'x' },
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
      '<leader>fjd',
      function() Snacks.picker.git_status() end,
      desc = 'Git Status',
    },
    {
      '<leader>fjS',
      function() Snacks.picker.git_stash() end,
      desc = 'Git Stash',
    },
    {
      '<leader>fd',
      function() Snacks.picker.git_diff() end,
      desc = 'Git Diff (Hunks)',
    },
    {
      '<leader>fjH',
      function()
        local ok, gs = pcall(require, 'gitsigns')
        if not ok then
          vim.notify('gitsigns not available', vim.log.levels.ERROR)
          return
        end

        local hunks = gs.get_hunks()
        if not hunks or #hunks == 0 then
          vim.notify('No hunks in current buffer', vim.log.levels.INFO)
          return
        end

        local items = {}
        local bufnr = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        for i, hunk in ipairs(hunks) do
          local start_line = hunk.added and hunk.added.start or 1
          local preview_line = lines[start_line] or ''
          local type_indicator = hunk.type == 'add' and '+' or (hunk.type == 'delete' and '-' or '~')
          table.insert(items, {
            idx = i,
            text = string.format('%s L%d: %s', type_indicator, start_line, preview_line:sub(1, 60)),
            line = start_line,
            hunk = hunk,
          })
        end

        Snacks.picker({
          title = 'Git Hunks (Current Buffer)',
          items = items,
          format = function(item) return { { item.text, 'Normal' } } end,
          confirm = function(picker, item)
            picker:close()
            vim.api.nvim_win_set_cursor(0, { item.line, 0 })
          end,
        })
      end,
      desc = 'Find Hunks (Buffer)',
    },
    {
      '<leader>fjD',
      function()
        local ref = vim.fn.system('git rev-parse --verify origin/HEAD 2>/dev/null'):gsub('%s+', '')
        if vim.v.shell_error ~= 0 or ref == '' then
          ref = vim.fn.system('git rev-parse --verify origin/main 2>/dev/null'):gsub('%s+', '')
          if vim.v.shell_error ~= 0 or ref == '' then ref = vim.fn.system('git rev-parse --verify origin/master 2>/dev/null'):gsub('%s+', '') end
        end
        if vim.v.shell_error ~= 0 or ref == '' then
          vim.notify('Could not determine origin branch', vim.log.levels.ERROR)
          return
        end
        Snacks.picker.git_diff({ args = { ref } })
      end,
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
      '<leader>f/',
      function() Snacks.picker.search_history() end,
      desc = 'Search History',
    },
    {
      '<leader>fC',
      function() Snacks.picker.command_history() end,
      desc = 'Command History',
    },
    {
      '<leader>fi',
      function() Snacks.picker.icons() end,
      desc = 'Icons',
    },
    {
      '<leader>fk',
      function() Snacks.picker.keymaps() end,
      desc = 'Keymaps',
    },
    {
      '<leader>fp',
      show_package_json_picker,
      desc = 'Package.json Packages',
    },
    -- {
    --   '<leader>fF',
    --   function() Snacks.picker.files({ hidden = true, filter = { cwd = true } }) end,
    --   desc = 'Find Files',
    -- },
    -- {
    --   '<leader>fC',
    --   function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end,
    --   desc = 'Find Config File',
    -- },
    -- {
    --   '<leader>fp',
    --   function() Snacks.picker.projects() end,
    --   desc = 'Projects',
    -- },
    -- {
    --   '<leader>fo',
    --   function()
    --     local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
    --     if vim.v.shell_error ~= 0 or not git_root or git_root == '' then
    --       Snacks.picker.recent()
    --       return
    --     end
    --     git_root = vim.fn.fnamemodify(git_root, ':p')
    --     Snacks.picker.recent({
    --       filter = { cwd = git_root },
    --     })
    --   end,
    --   desc = 'Recent (repo)',
    -- },
    -- {
    --   '<leader>fl',
    --   function() Snacks.picker.lines() end,
    --   desc = 'Buffer Lines',
    -- },
    -- {
    --   '<leader>fvj',
    --   function() Snacks.picker.jumps() end,
    --   desc = 'Jumps',
    -- },
    -- {
    --   '<leader><leader>D',
    --   function() Snacks.terminal('lazydocker', { win = { style = 'float' } }) end,
    --   desc = 'Lazydocker',
    -- },
    -- {
    --   '<leader><leader>S',
    --   function() Snacks.terminal('lazysql', { win = { style = 'float' } }) end,
    --   desc = 'Lazysql',
    -- },
    -- {
    --   '<leader>;D',
    --   function() Snacks.terminal('vd ' .. vim.fn.expand('%'), { win = { style = 'float' } }) end,
    --   desc = 'Visidata',
    -- },
    -- {
    --   '<leader>gL',
    --   function() Snacks.gitbrowse() end,
    --   desc = 'Git Browse',
    --   mode = { 'n', 'v' },
    -- },
    -- {
    --   '<leader>fH',
    --   function() Snacks.picker.highlights() end,
    --   desc = 'Highlights',
    -- },
    -- {
    --   '<leader>fM',
    --   function() Snacks.picker.man() end,
    --   desc = 'Man Pages',
    -- },
    -- {
    --   '<leader>f"',
    --   function() Snacks.picker.registers() end,
    --   desc = 'Registers',
    -- },
    -- {
    --   '<leader>fva',
    --   function() Snacks.picker.autocmds() end,
    --   desc = 'Autocmds',
    -- },
    -- {
    --   '<leader>fvf',
    --   function() Snacks.picker.colorschemes() end,
    --   desc = 'Colorschemes',
    -- },
    -- {
    --   '<leader>fvh',
    --   function() Snacks.picker.help() end,
    --   desc = 'Help Pages',
    -- },
    -- {
    --   '<leader>fvl',
    --   function() Snacks.picker.loclist() end,
    --   desc = 'Location List',
    -- },
    -- {
    --   '<leader>fvm',
    --   function() Snacks.picker.marks() end,
    --   desc = 'Marks',
    -- },
    -- {
    --   '<leader>fvp',
    --   function() Snacks.picker.lazy() end,
    --   desc = 'Search for Plugin Spec',
    -- },
    -- {
    --   '<leader>fvq',
    --   function() Snacks.picker.qflist() end,
    --   desc = 'Quickfix List',
    -- },
    -- {
    --   '<leader>fN',
    --   desc = 'Neovim News',
    --   function()
    --     Snacks.win({
    --       file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
    --       width = 0.6,
    --       height = 0.6,
    --       wo = {
    --         spell = false,
    --         wrap = false,
    --         signcolumn = 'yes',
    --         statuscolumn = ' ',
    --         conceallevel = 3,
    --       },
    --     })
    --   end,
    -- },
  },
}
