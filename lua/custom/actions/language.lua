local languageUtils = require('custom.utils.language')
local inputUtils = require('custom.utils.input')
local toggleTermActions = require('custom.actions.toggleterm')

local M = {}

function M.runJavaClassMvn()
  local currentClass = languageUtils.getCurrentJavaClass()
  vim.cmd(":3TermExec cmd='mvn compile'")
  vim.cmd(':3TermExec mvn exec:java -Dexec.mainClass=' .. currentClass)
end

function M.runJavaClassJavac()
  local currentClass = languageUtils.getCurrentJavaClass()
  local command = [[:terminal javac ]] .. currentClass .. [[; java ]] .. currentClass
  vim.cmd(command)
end

function M.runMarkdownFileFolder()
  local currentFolder = vim.fn.expand('%:p:h')
  local command = ':4TermExec cmd="markserv -b -p 5454 ' .. currentFolder .. '"<CR>'
  vim.cmd(command)
end

function M.compileMjmlFile()
  local mjmlFile = vim.fn.expand('%')
  local htmlFile = mjmlFile:gsub('.mjml', '.html')
  local ftlhFile = mjmlFile:gsub('.mjml', '.ftlh')

  vim.cmd('!mjml -r' .. mjmlFile .. ' -o ' .. htmlFile)
  vim.cmd('!mjml -r' .. mjmlFile .. ' -o ' .. ftlhFile)
end

function M.installJavascriptPackage()
  local packageManager = languageUtils.getJavascriptPackageManager()
  local packageTypes = { 'dev', 'prod' }

  vim.ui.select(packageTypes, {
    prompt = 'Select package type',
  }, function(packageType)
    if packageType == nil then return end

    local packageName = inputUtils.getInputFromUser('Package name')

    if packageType == 'dev' then
      local devArg = languageUtils.getJavascriptPackageManagerDevArg()
      vim.cmd(":3TermExec cmd='" .. packageManager .. ' add ' .. packageName .. ' ' .. devArg .. "'")
    end

    vim.cmd(":3TermExec cmd='" .. packageManager .. ' add ' .. packageName .. "'")
  end)
end

function M.runPackageJsonScript(terminalIndex)
  local scripts = languageUtils.listPackageJsonCommands()

  if #scripts == 0 then
    vim.notify('No scripts found in package.json', vim.log.levels.WARN)
    return
  end

  vim.ui.select(scripts, {
    prompt = 'Select a script to run:',
  }, function(choice)
    if choice then
      local package_manager = languageUtils.getJavascriptPackageManager()
      local command = package_manager .. ' ' .. choice
      vim.cmd(':' .. terminalIndex .. "TermExec cmd='" .. command .. "'")
    end
  end)
end

function M.runCommandInTerminal(terminalIndex, command, shouldExit, args)
  return function()
    if not args then args = '' end

    local curwin = vim.api.nvim_get_current_win()
    if not command or command == '' then
      vim.notify('No command provided to run', vim.log.levels.WARN)
      return
    end

    local package_manager = languageUtils.getJavascriptPackageManager()
    if not package_manager or package_manager == '' then
      vim.notify('No JavaScript package manager found', vim.log.levels.ERROR)
      return
    end
    command = package_manager .. ' ' .. command

    vim.cmd(':' .. terminalIndex .. 'TermExec ' .. args .. " cmd='" .. command .. "' ")

    if shouldExit then
      toggleTermActions.createKillToggleTerm(terminalIndex)()
      vim.cmd(':' .. terminalIndex .. "TermExec cmd='exit'")
    end
    vim.api.nvim_set_current_win(curwin)
  end
end

function M.nextEslintQuickfix()
  vim.cmd("cgetexpr system('eslint -f unix .')")
  vim.cmd('cnext')
end

function M.run_eslint()
  print('Running ESLint...')
  local cmd = 'npx eslint ./src --ext ts,tsx,js,jsx | grep /jimmy'
  local file_links = vim.fn.systemlist(cmd)

  local items = {}
  for idx, file_path in ipairs(file_links) do
    local item = {
      idx = idx,
      text = vim.fn.fnamemodify(file_path, ':~'), -- Display path relative to home
      file = file_path, -- Full path for opening the file
    }
    table.insert(items, item)
  end

  local snacks = require('snacks')
  snacks.picker({
    title = 'Preselected Files',
    layout = {
      preset = 'default', -- Use default layout (can be changed to "ivy", "select", etc.)
      -- preview = true,     -- Enable preview pane
    },
    items = items,
    format = function(item, _)
      local a = snacks.picker.util.align
      local icon, icon_hl = snacks.util.icon(item.file, 'file')
      return {
        { a(icon, 3), icon_hl }, -- File icon
        { ' ' },
        { item.text }, -- Display relative path
      }
    end,
    confirm = function(picker, item)
      picker:close()
      vim.cmd('edit ' .. vim.fn.fnameescape(item.file)) -- Open the selected file
    end,
  })

  -- Snacks.picker.files({ hidden = true, items = output })
  print('ESLint completed. Check the quickfix list for results.')
end

-- Function to filter npm packages starting with a given string
function M.filter_npm_packages(start_str)
  -- Validate input
  if not start_str or start_str == '' then
    vim.notify('Error: Please provide a valid starting string for package filtering', vim.log.levels.ERROR)
    return
  end

  -- Escape special characters in the input string to prevent command injection
  local escaped_str = vim.fn.shellescape(start_str .. '*')

  -- Construct the npm-check-updates command with filter
  local cmd = string.format('npx npm-check-updates -u --filter %s', escaped_str)

  -- Execute the command in a terminal, consistent with provided keymappings
  vim.cmd(string.format("2TermExec cmd='%s'", vim.fn.shellescape(cmd)))

  -- Notify user of the action
  vim.notify(string.format('Filtering npm packages starting with: %s', start_str), vim.log.levels.INFO)
end

function M.launch_android_emulator()
  -- Path to your Android SDK emulator folder
  local sdk_path = os.getenv('HOME') .. '/Library/Android/sdk/emulator' -- macOS/Linux
  local emulator_exe = sdk_path .. '/emulator'

  -- Get list of available AVDs
  local handle = io.popen(emulator_exe .. ' -list-avds')
  if not handle then
    print('Could not find emulator executable at ' .. emulator_exe)
    return
  end

  local avds = {}
  for line in handle:lines() do
    table.insert(avds, line)
  end
  handle:close()

  if #avds == 0 then
    print('No AVDs found.')
    return
  end

  -- Use vim.ui.select to pick one
  vim.ui.select(avds, { prompt = 'Select Android Emulator:' }, function(choice)
    if choice then
      -- Run the emulator in the background
      vim.fn.jobstart({ emulator_exe, '-avd', choice }, { detach = true })
      print('Launching emulator: ' .. choice)
    else
      print('No emulator selected.')
    end
  end)
end

function M.fix_and_organize_ts()
  local import_pattern = [[import%s+.-;%s*]]

  -- Collect all .ts and .tsx files under cwd, ignoring node_modules
  local files = vim.fn.systemlist("find . -type f \\( -name '*.ts' -o -name '*.tsx' \\) -not -path '*/node_modules/*'")
  if #files == 0 then
    print('No TypeScript files found')
    return
  end

  local function process_file(filepath, callback)
    vim.cmd('edit ' .. filepath)
    local bufnr = vim.api.nvim_get_current_buf()

    -- Delete all imports
    vim.api.nvim_buf_call(bufnr, function() vim.cmd(string.format('%%s/%s//ge', import_pattern)) end)

    -- Trigger LSP organize imports
    local params = {
      command = '_typescript.organizeImports',
      arguments = { vim.api.nvim_buf_get_name(bufnr) },
      title = '',
    }
    vim.lsp.buf.execute_command(params)

    -- Save & close after short delay (let LSP apply changes)
    vim.defer_fn(function()
      vim.cmd('silent write')
      vim.cmd('bdelete')
      if callback then callback() end
    end, 500)
  end

  -- Sequentially walk through files
  local i = 1
  local function step()
    if i <= #files then
      process_file(files[i], function()
        i = i + 1
        step()
      end)
    else
      print('✅ Finished cleaning imports in ' .. #files .. ' files')
    end
  end

  step()
end

-- Function to find and delete unused npm packages
function M.find_and_delete_unused_packages()
  -- Check if package.json exists
  if vim.fn.filereadable('package.json') == 0 then
    vim.notify('No package.json found in current directory', vim.log.levels.ERROR)
    return
  end

  -- First, run depcheck to identify unused packages
  local depcheck_cmd = 'npx depcheck --json'

  vim.notify('🔍 Analyzing unused packages...', vim.log.levels.INFO)

  -- Run depcheck and capture output
  vim.fn.jobstart(depcheck_cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local json_str = table.concat(data, '\n')
        if json_str:match('^%s*$') then return end

        -- Parse the JSON output
        local success, result = pcall(vim.fn.json_decode, json_str)
        if not success or not result.dependencies then
          vim.notify('Failed to parse depcheck output', vim.log.levels.ERROR)
          return
        end

        local unused_deps = result.dependencies or {}
        local unused_dev_deps = result.devDependencies or {}

        -- Combine all unused dependencies
        local all_unused = {}
        for _, dep in ipairs(unused_deps) do
          table.insert(all_unused, { name = dep, type = 'dependency' })
        end
        for _, dep in ipairs(unused_dev_deps) do
          table.insert(all_unused, { name = dep, type = 'devDependency' })
        end

        if #all_unused == 0 then
          vim.notify('✅ No unused packages found!', vim.log.levels.INFO)
          return
        end

        -- Create options for vim.ui.select
        local options = {}
        for i, pkg in ipairs(all_unused) do
          table.insert(options, string.format('%s (%s)', pkg.name, pkg.type))
        end
        table.insert(options, '🗑️  DELETE ALL UNUSED PACKAGES')
        table.insert(options, '❌ Cancel')

        -- Let user select which packages to uninstall
        vim.ui.select(options, {
          prompt = string.format('Found %d unused packages. Select action:', #all_unused),
          format_item = function(item) return item end,
        }, function(choice, idx)
          if not choice or choice == '❌ Cancel' then return end

          local packageManager = languageUtils.getJavascriptPackageManager()
          local uninstall_cmd = packageManager == 'npm' and 'npm uninstall'
            or packageManager == 'yarn' and 'yarn remove'
            or packageManager == 'pnpm' and 'pnpm remove'
            or 'npm uninstall'

          if choice == '🗑️  DELETE ALL UNUSED PACKAGES' then
            -- Uninstall all unused packages
            local deps_to_remove = {}
            for _, pkg in ipairs(all_unused) do
              table.insert(deps_to_remove, pkg.name)
            end

            if #deps_to_remove > 0 then
              local cmd = uninstall_cmd .. ' ' .. table.concat(deps_to_remove, ' ')
              vim.notify('🗑️  Removing all unused packages: ' .. table.concat(deps_to_remove, ', '), vim.log.levels.INFO)
              vim.cmd(string.format("2TermExec cmd='%s'", cmd))
            end
          else
            -- Uninstall selected package
            local selected_pkg = all_unused[idx]
            if selected_pkg then
              local cmd = uninstall_cmd .. ' ' .. selected_pkg.name
              vim.notify('🗑️  Removing package: ' .. selected_pkg.name, vim.log.levels.INFO)
              vim.cmd(string.format("2TermExec cmd='%s'", cmd))
            end
          end
        end)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_msg = table.concat(data, '\n')
        if not error_msg:match('^%s*$') then vim.notify('Depcheck error: ' .. error_msg, vim.log.levels.WARN) end
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then vim.notify('Depcheck failed with exit code: ' .. code, vim.log.levels.ERROR) end
    end,
  })
end

function M.repeatLastCommand()
  -- Get the last command from command history
  local last_cmd = vim.fn.histget(':', -1)

  if not last_cmd or last_cmd == '' then
    vim.notify('No previous command found', vim.log.levels.WARN)
    return
  end

  -- Use vim.ui.input to prefill with the last command
  vim.ui.input({
    prompt = 'Repeat/Edit command: ',
    default = last_cmd,
    completion = 'command',
  }, function(input)
    if input and input ~= '' then
      -- Execute the command
      vim.cmd(input)
    end
  end)
end

function M.runNpmCheckUpdatesFilter()
  vim.ui.input({
    prompt = 'Filter packages to update (glob patterns, comma-separated, optional): ',
    default = '',
  }, function(filterList)
    if filterList == nil then return end

    local cmd = 'npx npm-check-updates'

    if filterList ~= '' then
      -- Clean up the filter list: remove spaces, split by comma
      local patterns = {}
      for pattern in string.gmatch(filterList, '([^,]+)') do
        table.insert(patterns, string.match(pattern, '^%s*(.-)%s*$')) -- trim whitespace
      end

      if #patterns > 0 then cmd = cmd .. ' --filter ' .. table.concat(patterns, ',') end
    end

    -- Run the command in a terminal
    vim.cmd('split')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  end)
end

function M.createRunMakeCommand(index)
  return function()
    local makefile = 'Makefile'
    if not vim.fn.filereadable(makefile) then
      vim.notify('No Makefile found in current directory', vim.log.levels.ERROR)
      return
    end
    local targets = {}
    for line in io.lines(makefile) do
      local target = line:match('^(%w[%w-_%.]*)%s*:%s*')
      if target and target ~= 'PHONY' then table.insert(targets, target) end
    end
    if #targets == 0 then
      vim.notify('No make targets found', vim.log.levels.ERROR)
      return
    end
    vim.ui.select(targets, { prompt = 'Select make target:' }, function(choice)
      if not choice then return end
      local term = require('toggleterm.terminal').Terminal
      local t = term:new({ cmd = 'make ' .. choice, count = index or 1, close_on_exit = false })
      t:toggle()
    end)
  end
end

return M
