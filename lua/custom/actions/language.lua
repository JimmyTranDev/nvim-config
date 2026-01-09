local language_utils = require('custom.utils.language')
local input_utils = require('custom.utils.input')
local ui_utils = require('custom.utils.ui')
local validation = require('custom.utils.validation')

local M = {}

function M.run_java_class_maven()
  local current_class = language_utils.getCurrentJavaClass()
  if not current_class or current_class == '' then
    vim.notify('No Java class found', vim.log.levels.WARN)
    return
  end

  ui_utils.exec_background('mvn compile', 'Maven compile started')
  ui_utils.exec_with_feedback('mvn exec:java -Dexec.mainClass=' .. current_class, 'Running Java class: ' .. current_class, 3)
end

function M.run_java_class_javac()
  local current_class = language_utils.getCurrentJavaClass()
  if not current_class or current_class == '' then
    vim.notify('No Java class found', vim.log.levels.WARN)
    return
  end

  local command = string.format('terminal javac %s; java %s', current_class, current_class)
  vim.cmd(command)
  ui_utils.show_success('Running Java class with javac: ' .. current_class)
end

function M.serve_markdown_folder()
  local current_folder = vim.fn.expand('%:p:h')
  if not current_folder or current_folder == '' then
    vim.notify('Could not determine current folder', vim.log.levels.ERROR)
    return
  end

  local command = string.format('markserv -b -p 5454 "%s"', current_folder)
  ui_utils.exec_with_feedback(command, 'Markdown server started on port 5454', 4)
end

function M.compile_mjml_file()
  local mjml_file = vim.fn.expand('%')
  if not mjml_file or mjml_file == '' then
    vim.notify('No current file found', vim.log.levels.WARN)
    return
  end

  if not mjml_file:match('%.mjml$') then
    vim.notify('Current file is not an MJML file', vim.log.levels.WARN)
    return
  end

  local html_file = mjml_file:gsub('%.mjml$', '.html')
  local ftlh_file = mjml_file:gsub('%.mjml$', '.ftlh')

  local commands = {
    string.format('mjml -r "%s" -o "%s"', mjml_file, html_file),
    string.format('mjml -r "%s" -o "%s"', mjml_file, ftlh_file),
  }

  for _, cmd in ipairs(commands) do
    vim.cmd('!' .. cmd)
  end

  ui_utils.show_success('MJML compiled to HTML and FTLH formats')
end

function M.install_javascript_package()
  local package_manager = language_utils.getJavascriptPackageManager()
  if not package_manager then
    vim.notify('No JavaScript package manager found', vim.log.levels.ERROR)
    return
  end

  local isInWs = language_utils.isInWorkspace()
  local workspacePackages = {}

  if isInWs then workspacePackages = language_utils.getWorkspacePackages() end

  local package_types = { 'production', 'development' }

  ui_utils.safe_select(package_types, {
    prompt = 'Select package type:',
  }, function(package_type)
    ui_utils.safe_input({
      prompt = 'Enter package name: ',
    }, function(package_name)
      local is_valid, error_msg = validation.string(package_name, 1)
      if not is_valid then
        vim.notify('Invalid package name: ' .. error_msg, vim.log.levels.ERROR)
        return
      end

      if isInWs and #workspacePackages > 0 then
        local install_options = { 'Root workspace' }
        for _, pkg in ipairs(workspacePackages) do
          table.insert(install_options, pkg)
        end

        ui_utils.safe_select(install_options, {
          prompt = 'Install to which workspace:',
        }, function(selected_workspace)
          local cmd = M.build_workspace_install_command(package_manager, package_name, package_type, selected_workspace, workspacePackages)
          ui_utils.exec_with_feedback(cmd, string.format('Installing %s package %s to %s', package_type, package_name, selected_workspace), 3)
        end)
      else
        local base_cmd = package_manager .. ' add ' .. package_name

        if package_type == 'development' then
          local dev_arg = language_utils.getJavascriptPackageManagerDevArg()
          base_cmd = base_cmd .. ' ' .. dev_arg
        end

        ui_utils.exec_with_feedback(base_cmd, string.format('Installing %s package: %s', package_type, package_name), 3)
      end
    end)
  end)
end

function M.build_workspace_install_command(package_manager, package_name, package_type, selected_workspace, workspacePackages)
  local base_cmd = package_manager .. ' add ' .. package_name

  if package_type == 'development' then
    local dev_arg = language_utils.getJavascriptPackageManagerDevArg()
    base_cmd = base_cmd .. ' ' .. dev_arg
  end

  if selected_workspace == 'Root workspace' then return base_cmd end

  if package_manager == 'pnpm' then
    return 'pnpm --filter ' .. selected_workspace .. ' add ' .. package_name .. (package_type == 'development' and ' --save-dev' or '')
  elseif package_manager == 'yarn' then
    return 'yarn workspace ' .. selected_workspace .. ' add ' .. package_name .. (package_type == 'development' and ' --dev' or '')
  elseif package_manager == 'npm' then
    return 'npm --workspace=' .. selected_workspace .. ' install ' .. package_name .. (package_type == 'development' and ' --save-dev' or '')
  elseif package_manager == 'bun' then
    return 'bun --filter ' .. selected_workspace .. ' add ' .. package_name .. (package_type == 'development' and ' --dev' or '')
  else
    return base_cmd
  end
end

function M.run_package_script(terminal_index)
  local scripts = language_utils.listPackageJsonCommands()
  local term_id = terminal_index or 3

  if #scripts == 0 then
    vim.notify('No scripts found in package.json', vim.log.levels.WARN)
    return
  end

  ui_utils.safe_select(scripts, {
    prompt = 'Select a script to run:',
  }, function(selected_script)
    local package_manager = language_utils.getJavascriptPackageManager()
    if not package_manager then
      vim.notify('No JavaScript package manager found', vim.log.levels.ERROR)
      return
    end

    local command = package_manager .. ' ' .. selected_script
    ui_utils.exec_with_feedback(command, string.format('Running script: %s', selected_script), term_id)
  end)
end

function M.create_package_command_runner(terminal_index, command, should_exit, args)
  return function()
    if not command or command == '' then
      vim.notify('No command provided to run', vim.log.levels.WARN)
      return
    end

    local package_manager = language_utils.getJavascriptPackageManager()
    if not package_manager then
      vim.notify('No JavaScript package manager found', vim.log.levels.ERROR)
      return
    end

    local current_window = vim.api.nvim_get_current_win()
    local full_command = package_manager .. ' ' .. command
    local term_args = args or ''

    vim.cmd(string.format(":%dTermExec %s cmd='%s'", terminal_index, term_args, full_command))

    if should_exit then
      local toggleterm_actions = require('custom.actions.toggleterm')
      if toggleterm_actions.create_kill_toggle_term then toggleterm_actions.create_kill_toggle_term(terminal_index)() end
      vim.cmd(string.format(":%dTermExec cmd='exit'", terminal_index))
    end

    vim.api.nvim_set_current_win(current_window)
  end
end

function M.next_eslint_quickfix()
  local cmd = 'eslint -f unix .'
  vim.cmd("cgetexpr system('" .. cmd .. "')")

  local ok, err = pcall(vim.cmd, 'cnext')
  if not ok then vim.notify('No more ESLint errors', vim.log.levels.INFO) end
end

function M.run_eslint_picker()
  ui_utils.show_progress('Running ESLint...')

  local npx_cmd = language_utils.getNpxEquivalent()
  local cmd = npx_cmd .. ' eslint . --ext ts,tsx,js,jsx --format unix 2>&1 | grep -oE "^[^:]+:[0-9]+" | cut -d: -f1 | sort -u'
  local file_links = vim.fn.systemlist(cmd)

  local items = {}
  for idx, file_path in ipairs(file_links) do
    if file_path and file_path ~= '' then
      local item = {
        idx = idx,
        text = vim.fn.fnamemodify(file_path, ':~'),
        file = file_path,
      }
      table.insert(items, item)
    end
  end

  if #items == 0 then
    ui_utils.show_success('No ESLint issues found!')
    return
  end

  local ok, snacks = pcall(require, 'snacks')
  if not ok then
    vim.notify('Snacks plugin not available', vim.log.levels.ERROR)
    return
  end

  snacks.picker({
    title = 'ESLint Results',
    layout = { preset = 'default' },
    items = items,
    format = function(item, _)
      local a = snacks.picker.util.align
      local icon, icon_hl = snacks.util.icon(item.file, 'file')
      return {
        { a(icon, 3), icon_hl },
        { ' ' },
        { item.text },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      vim.cmd('edit ' .. vim.fn.fnameescape(item.file))
    end,
  })

  ui_utils.show_success('ESLint analysis complete')
end

function M.run_knip_picker()
  local package_manager = language_utils.getJavascriptPackageManager()
  if not package_manager or package_manager == '' then
    vim.notify('No JavaScript package manager found. Make sure you are in a JS/TS project with a lockfile.', vim.log.levels.ERROR)
    return
  end

  local cmd = package_manager .. ' dlx knip --reporter json'

  ui_utils.show_progress('Running knip analysis with: ' .. cmd)

  local stdout_data = {}
  local stderr_data = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then vim.list_extend(stdout_data, data) end
    end,
    on_stderr = function(_, data)
      if data then vim.list_extend(stderr_data, data) end
    end,
    on_exit = function(_, code)
      if code ~= 0 and code ~= 1 then
        local error_msg = 'Knip failed with exit code: ' .. code
        if #stderr_data > 0 then error_msg = error_msg .. '\nError output:\n' .. table.concat(stderr_data, '\n') end
        vim.notify(error_msg, vim.log.levels.ERROR)
        return
      end

      if not stdout_data or #stdout_data == 0 or (stdout_data[1] == '' and #stdout_data == 1) then
        vim.notify('No unused code found by knip!', vim.log.levels.INFO)
        return
      end

      local json_str = table.concat(stdout_data, '\n')
      local ok, result = pcall(vim.fn.json_decode, json_str)

      if not ok or not result then
        vim.notify('Failed to parse knip JSON output', vim.log.levels.ERROR)
        return
      end

      local items = {}

      if result.files and type(result.files) == 'table' then
        for _, file in ipairs(result.files) do
          table.insert(items, {
            file = file,
            line = 1,
            col = 1,
            type = 'orphaned file',
            name = file,
            text = string.format('[%s] Orphaned file (unused)', file),
          })
        end
      end

      if result.issues and type(result.issues) == 'table' then
        for _, issue in ipairs(result.issues) do
          local file = issue.file

          if issue.dependencies then
            for _, dep in ipairs(issue.dependencies) do
              table.insert(items, {
                file = file,
                line = dep.line or 1,
                col = dep.col or 1,
                type = 'unused dependency',
                name = dep.name or 'unknown',
                text = string.format('[%s:%d] Unused dependency: %s', file, dep.line or 1, dep.name or 'unknown'),
              })
            end
          end

          if issue.devDependencies then
            for _, dep in ipairs(issue.devDependencies) do
              table.insert(items, {
                file = file,
                line = dep.line or 1,
                col = dep.col or 1,
                type = 'unused devDependency',
                name = dep.name or 'unknown',
                text = string.format('[%s:%d] Unused devDependency: %s', file, dep.line or 1, dep.name or 'unknown'),
              })
            end
          end

          if issue.exports then
            for _, export in ipairs(issue.exports) do
              table.insert(items, {
                file = file,
                line = export.line or 1,
                col = export.col or 1,
                type = 'unused export',
                name = export.name or 'unknown',
                text = string.format('[%s:%d] Unused export: %s', file, export.line or 1, export.name or 'unknown'),
              })
            end
          end

          if issue.types then
            for _, typ in ipairs(issue.types) do
              table.insert(items, {
                file = file,
                line = typ.line or 1,
                col = typ.col or 1,
                type = 'unused type',
                name = typ.name or 'unknown',
                text = string.format('[%s:%d] Unused type: %s', file, typ.line or 1, typ.name or 'unknown'),
              })
            end
          end

          if issue.unlisted then
            for _, dep in ipairs(issue.unlisted) do
              table.insert(items, {
                file = file,
                line = dep.line or 1,
                col = dep.col or 1,
                type = 'unlisted dependency',
                name = dep.name or 'unknown',
                text = string.format('[%s:%d] Unlisted dependency: %s', file, dep.line or 1, dep.name or 'unknown'),
              })
            end
          end

          if issue.unresolved then
            for _, unres in ipairs(issue.unresolved) do
              table.insert(items, {
                file = file,
                line = unres.line or 1,
                col = unres.col or 1,
                type = 'unresolved import',
                name = unres.name or 'unknown',
                text = string.format('[%s:%d] Unresolved import: %s', file, unres.line or 1, unres.name or 'unknown'),
              })
            end
          end
        end
      end

      if #items == 0 then
        vim.notify('No unused code found by knip!', vim.log.levels.INFO)
        return
      end

      local ok_snacks, snacks = pcall(require, 'snacks')
      if not ok_snacks then
        vim.notify('Snacks plugin not available', vim.log.levels.ERROR)
        return
      end

      snacks.picker({
        title = string.format('Knip Results (%d items)', #items),
        layout = { preset = 'default' },
        items = items,
        format = function(item, _)
          local a = snacks.picker.util.align
          local icon, icon_hl = snacks.util.icon(item.file, 'file')
          local type_icon = item.type == 'unused export' and '󰏫'
            or item.type == 'unused dependency' and '󰏗'
            or item.type == 'unused devDependency' and '󰏗'
            or item.type == 'unused type' and '󰉉'
            or item.type == 'orphaned file' and '󰈚'
            or item.type == 'unlisted dependency' and '󰏗'
            or item.type == 'unresolved import' and '󰌘'
            or '󰊨'
          local type_hl = item.type == 'orphaned file' and 'DiagnosticError' or 'DiagnosticWarn'
          return {
            { a(icon, 3), icon_hl },
            { ' ' },
            { a(type_icon, 2), type_hl },
            { ' ' },
            { item.text },
          }
        end,
        confirm = function(picker, item)
          picker:close()
          vim.cmd('edit ' .. vim.fn.fnameescape(item.file))
          vim.api.nvim_win_set_cursor(0, { item.line, item.col - 1 })
        end,
      })

      ui_utils.show_success(string.format('Knip analysis complete - found %d issues', #items))
    end,
  })
end

function M.filter_npm_packages(pattern)
  local is_valid, error_msg = validation.string(pattern, 1)
  if not is_valid then
    vim.notify('Invalid pattern: ' .. error_msg, vim.log.levels.ERROR)
    return
  end

  local escaped_pattern = vim.fn.shellescape(pattern .. '*')
  local npx_cmd = language_utils.getNpxEquivalent()
  local cmd = string.format('%s npm-check-updates -u --filter %s', npx_cmd, escaped_pattern)

  ui_utils.exec_with_feedback(cmd, string.format('Filtering npm packages matching: %s', pattern), 2)
end

function M.update_npm_packages_interactive()
  ui_utils.safe_input({
    prompt = 'Filter packages to update (glob patterns, comma-separated, optional): ',
    default = '',
  }, function(filter_list)
    local npx_cmd = language_utils.getNpxEquivalent()
    local cmd = npx_cmd .. ' npm-check-updates'

    if filter_list and filter_list ~= '' then
      local patterns = {}
      for pattern in string.gmatch(filter_list, '([^,]+)') do
        local trimmed = pattern:match('^%s*(.-)%s*$')
        if trimmed and trimmed ~= '' then table.insert(patterns, trimmed) end
      end

      if #patterns > 0 then cmd = cmd .. ' --filter ' .. table.concat(patterns, ',') end
    end

    vim.cmd('split')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  end)
end

function M.remove_unused_packages()
  if vim.fn.filereadable('package.json') == 0 then
    vim.notify('No package.json found in current directory', vim.log.levels.ERROR)
    return
  end

  ui_utils.show_progress('🔍 Analyzing unused packages...')

  local npx_cmd = language_utils.getNpxEquivalent()
  vim.fn.jobstart(npx_cmd .. ' depcheck --json', {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data or #data == 0 then return end

      local json_str = table.concat(data, '\n')
      if json_str:match('^%s*$') then return end

      local success, result = pcall(vim.fn.json_decode, json_str)
      if not success or not result then
        vim.notify('Failed to parse depcheck output', vim.log.levels.ERROR)
        return
      end

      local unused_deps = result.dependencies or {}
      local unused_dev_deps = result.devDependencies or {}

      local all_unused = {}
      for _, dep in ipairs(unused_deps) do
        table.insert(all_unused, { name = dep, type = 'dependency' })
      end
      for _, dep in ipairs(unused_dev_deps) do
        table.insert(all_unused, { name = dep, type = 'devDependency' })
      end

      if #all_unused == 0 then
        ui_utils.show_success('✅ No unused packages found!')
        return
      end

      M._handle_unused_packages_selection(all_unused)
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_msg = table.concat(data, '\n')
        if not error_msg:match('^%s*$') then vim.notify('Depcheck warning: ' .. error_msg, vim.log.levels.WARN) end
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then vim.notify('Depcheck failed with exit code: ' .. code, vim.log.levels.ERROR) end
    end,
  })
end

function M._handle_unused_packages_selection(unused_packages)
  local options = {}
  for _, pkg in ipairs(unused_packages) do
    table.insert(options, string.format('%s (%s)', pkg.name, pkg.type))
  end
  table.insert(options, '🗑️  DELETE ALL UNUSED PACKAGES')
  table.insert(options, '❌ Cancel')

  ui_utils.safe_select(options, {
    prompt = string.format('Found %d unused packages. Select action:', #unused_packages),
  }, function(choice, idx)
    if not choice or choice == '❌ Cancel' then return end

    local package_manager = language_utils.getJavascriptPackageManager()
    local uninstall_cmd = M._get_uninstall_command(package_manager)

    if choice == '🗑️  DELETE ALL UNUSED PACKAGES' then
      M._remove_all_packages(unused_packages, uninstall_cmd)
    else
      M._remove_single_package(unused_packages[idx], uninstall_cmd)
    end
  end)
end

function M._get_uninstall_command(package_manager)
  local commands = {
    npm = 'npm uninstall',
    yarn = 'yarn remove',
    pnpm = 'pnpm remove',
    bun = 'bun remove',
  }
  return commands[package_manager] or 'npm uninstall'
end

function M._remove_all_packages(packages, uninstall_cmd)
  local package_names = {}
  for _, pkg in ipairs(packages) do
    table.insert(package_names, pkg.name)
  end

  if #package_names > 0 then
    local cmd = uninstall_cmd .. ' ' .. table.concat(package_names, ' ')
    ui_utils.exec_with_feedback(cmd, '🗑️  Removing all unused packages: ' .. table.concat(package_names, ', '), 2)
  end
end

function M._remove_single_package(package, uninstall_cmd)
  if package then
    local cmd = uninstall_cmd .. ' ' .. package.name
    ui_utils.exec_with_feedback(cmd, '🗑️  Removing package: ' .. package.name, 2)
  end
end

function M.launch_android_emulator()
  local sdk_path = os.getenv('HOME') .. '/Library/Android/sdk/emulator'
  local emulator_exe = sdk_path .. '/emulator'

  local handle = io.popen(emulator_exe .. ' -list-avds 2>/dev/null')
  if not handle then
    vim.notify('Could not find Android emulator at: ' .. emulator_exe, vim.log.levels.ERROR)
    return
  end

  local avds = {}
  for line in handle:lines() do
    if line and line ~= '' then table.insert(avds, line) end
  end
  handle:close()

  if #avds == 0 then
    vim.notify('No Android Virtual Devices found', vim.log.levels.WARN)
    return
  end

  ui_utils.safe_select(avds, {
    prompt = 'Select Android Emulator:',
  }, function(selected_avd)
    vim.fn.jobstart({ emulator_exe, '-avd', selected_avd }, { detach = true })
    ui_utils.show_success('Launching emulator: ' .. selected_avd)
  end)
end

function M.fix_and_organize_typescript_imports()
  local import_pattern = [[import%s+.-;%s*]]

  ui_utils.show_progress('🔍 Finding TypeScript files...')

  local find_cmd = "find . -type f \\( -name '*.ts' -o -name '*.tsx' \\) -not -path '*/node_modules/*'"
  local files = vim.fn.systemlist(find_cmd)

  if #files == 0 then
    vim.notify('No TypeScript files found', vim.log.levels.WARN)
    return
  end

  ui_utils.show_progress(string.format('🔧 Processing %d TypeScript files...', #files))

  local function process_file(filepath, callback)
    local ok = pcall(function()
      vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
      local bufnr = vim.api.nvim_get_current_buf()

      vim.api.nvim_buf_call(bufnr, function() vim.cmd(string.format('%%s/%s//ge', import_pattern)) end)

      local params = {
        command = '_typescript.organizeImports',
        arguments = { vim.api.nvim_buf_get_name(bufnr) },
        title = '',
      }
      vim.lsp.buf.execute_command(params)

      vim.defer_fn(function()
        vim.cmd('silent write')
        vim.cmd('bdelete')
        if callback then callback() end
      end, 500)
    end)

    if not ok and callback then
      callback() -- Continue even if one file fails
    end
  end

  local current_index = 1
  local function process_next()
    if current_index <= #files then
      process_file(files[current_index], function()
        current_index = current_index + 1
        process_next()
      end)
    else
      ui_utils.show_success(string.format('✅ Finished cleaning imports in %d files', #files))
    end
  end

  process_next()
end

function M.repeat_last_command()
  local last_cmd = vim.fn.histget(':', -1)

  if not last_cmd or last_cmd == '' then
    vim.notify('No previous command found', vim.log.levels.WARN)
    return
  end

  ui_utils.safe_input({
    prompt = 'Repeat/Edit command: ',
    default = last_cmd,
    completion = 'command',
  }, function(command) vim.cmd(command) end)
end

function M.create_make_command_runner(terminal_index)
  return function()
    local makefile = 'Makefile'
    if vim.fn.filereadable(makefile) == 0 then
      vim.notify('No Makefile found in current directory', vim.log.levels.ERROR)
      return
    end

    local targets = {}
    local file = io.open(makefile, 'r')
    if not file then
      vim.notify('Could not read Makefile', vim.log.levels.ERROR)
      return
    end

    for line in file:lines() do
      local target = line:match('^(%w[%w-_%.]*)%s*:%s*')
      if target and target ~= 'PHONY' then table.insert(targets, target) end
    end
    file:close()

    if #targets == 0 then
      vim.notify('No make targets found', vim.log.levels.ERROR)
      return
    end

    ui_utils.safe_select(targets, {
      prompt = 'Select make target:',
    }, function(selected_target)
      local ok, toggleterm = pcall(require, 'toggleterm.terminal')
      if not ok then
        vim.notify('ToggleTerm not available', vim.log.levels.ERROR)
        return
      end

      local term = toggleterm.Terminal:new({
        cmd = 'make ' .. selected_target,
        count = terminal_index or 1,
        close_on_exit = false,
      })
      term:toggle()
    end)
  end
end

function M.create_npm_update_command(update_type)
  local npx_cmd = language_utils.getNpxEquivalent()

  if update_type == 'minor' then
    return npx_cmd .. ' npm-check-updates -u -t minor'
  elseif update_type == 'major' then
    return npx_cmd .. ' npm-check-updates -u'
  elseif update_type == 'patch' then
    return npx_cmd .. ' npm-check-updates -u -t patch'
  elseif update_type == 'interactive' then
    return npx_cmd .. ' npm-check-updates -ui'
  else
    return npx_cmd .. ' npm-check-updates'
  end
end

function M.create_npm_update_executor(terminal_num, update_type)
  return function()
    local cmd = M.create_npm_update_command(update_type)
    vim.cmd(string.format(':%dTermExec cmd="%s"', terminal_num, cmd))
  end
end

return M
