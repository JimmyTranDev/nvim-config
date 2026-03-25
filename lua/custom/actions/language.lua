local language_utils = require('custom.utils.language')
local ui_utils = require('custom.utils.ui')
local async_utils = require('custom.utils.async')
local validation = require('custom.utils.validation')

local M = {}

local function get_pm()
  local pm = language_utils.getJavascriptPackageManager()
  if not pm or pm == '' then
    vim.notify('No JavaScript package manager found', vim.log.levels.ERROR)
    return nil
  end
  return pm
end

function M.run_maven_spring_boot()
  local cwd = vim.fn.getcwd()
  local buf_path = vim.fn.expand('%:p')

  if vim.fn.filereadable(cwd .. '/pom.xml') ~= 1 then
    vim.notify('No pom.xml found in cwd', vim.log.levels.ERROR)
    return
  end

  local function get_submodules()
    local modules = {}
    local entries = vim.fn.readdir(cwd, function(name)
      return vim.fn.isdirectory(cwd .. '/' .. name) == 1
        and vim.fn.filereadable(cwd .. '/' .. name .. '/pom.xml') == 1
    end)
    for _, name in ipairs(entries) do
      table.insert(modules, name)
    end
    return modules
  end

  local function detect_submodule()
    if buf_path == '' or buf_path:sub(1, #cwd) ~= cwd then return nil end
    local relative = buf_path:sub(#cwd + 2)
    local module_name = relative:match('^([^/]+)/')
    if module_name and vim.fn.filereadable(cwd .. '/' .. module_name .. '/pom.xml') == 1 then
      return module_name
    end
    return nil
  end

  local function run_with_module(submodule)
    local cmd = 'mvn spring-boot:run'
    if submodule then cmd = cmd .. ' -pl ' .. submodule end
    cmd = cmd .. ' -Dspring-boot.run.profiles=local -Dmaven.test.skip=true'
    ui_utils.exec_in_terminal(cmd, 'Maven Spring Boot: ' .. (submodule or 'root'), 3)
  end

  local submodule = detect_submodule()
  if submodule then
    run_with_module(submodule)
    return
  end

  local modules = get_submodules()
  if #modules == 0 then
    run_with_module(nil)
    return
  end

  table.insert(modules, 1, '(root)')
  ui_utils.safe_select(modules, { prompt = 'Select Maven module:' }, function(selected)
    run_with_module(selected ~= '(root)' and selected or nil)
  end)
end

function M.run_java_class_maven()
  local class = language_utils.getCurrentJavaClass()
  if not class or class == '' then
    vim.notify('No Java class found', vim.log.levels.WARN)
    return
  end
  ui_utils.exec_in_terminal('mvn compile', 'Maven compile started')
  ui_utils.exec_in_terminal('mvn exec:java -Dexec.mainClass=' .. class, 'Running: ' .. class, 3)
end

function M.run_java_class_javac()
  local class = language_utils.getCurrentJavaClass()
  if not class or class == '' then
    vim.notify('No Java class found', vim.log.levels.WARN)
    return
  end
  vim.cmd(('terminal javac %s; java %s'):format(class, class))
end

function M.serve_markdown_folder()
  local folder = vim.fn.expand('%:p:h')
  if folder == '' then
    vim.notify('Could not determine current folder', vim.log.levels.ERROR)
    return
  end
  ui_utils.exec_in_terminal(('markserv -b -p 5454 "%s"'):format(folder), 'Markdown server started', 4)
end

function M.compile_mjml_file()
  local file = vim.fn.expand('%')
  if not file:match('%.mjml$') then
    vim.notify('Not an MJML file', vim.log.levels.WARN)
    return
  end
  vim.cmd('!mjml -r "' .. file .. '" -o "' .. file:gsub('%.mjml$', '.html') .. '"')
  vim.cmd('!mjml -r "' .. file .. '" -o "' .. file:gsub('%.mjml$', '.ftlh') .. '"')
  ui_utils.show_success('MJML compiled')
end

function M.install_javascript_package()
  local pm = get_pm()
  if not pm then return end

  local types = { 'production', 'development' }
  ui_utils.safe_select(types, { prompt = 'Package type:' }, function(pkg_type)
    ui_utils.safe_input({ prompt = 'Package name: ' }, function(pkg_name)
      if not validation.string(pkg_name, 1) then
        vim.notify('Invalid package name', vim.log.levels.ERROR)
        return
      end
      local cmd = pm .. ' add ' .. pkg_name
      if pkg_type == 'development' then
        cmd = cmd .. ' ' .. language_utils.getJavascriptPackageManagerDevArg()
      end
      ui_utils.exec_in_terminal(cmd, 'Installing: ' .. pkg_name, 3)
    end)
  end)
end

function M.run_package_script(term_id)
  local scripts = language_utils.listPackageJsonCommands()
  if #scripts > 0 then
    ui_utils.safe_select(scripts, { prompt = 'Select script:' }, function(script)
      local pm = get_pm()
      if pm then
        ui_utils.exec_in_terminal(pm .. ' ' .. script, 'Running: ' .. script, term_id or 3)
      end
    end)
    return
  end

  if vim.fn.filereadable('Makefile') == 1 then
    local targets = {}
    local ok, iter = pcall(io.lines, 'Makefile')
    if ok then
      for line in iter do
        local target = line:match('^(%w[%w-_%.]*)%s*:')
        if target and target ~= 'PHONY' then table.insert(targets, target) end
      end
    end

    if #targets > 0 then
      ui_utils.safe_select(targets, { prompt = 'Make target:' }, function(target)
        vim.cmd((':%dTermExec cmd="make %s"'):format(term_id or 1, target))
      end)
      return
    end
  end

  vim.notify('No package.json or Makefile found', vim.log.levels.WARN)
end

function M.create_package_command_runner(term_id, command, should_exit, args)
  return function()
    local pm = get_pm()
    if not pm or not command then return end
    vim.cmd((':%dTermExec %s cmd="%s %s"'):format(term_id, args or '', pm, command))
    if should_exit then vim.cmd((':%dTermExec cmd="exit"'):format(term_id)) end
  end
end

function M.run_eslint_picker()
  ui_utils.show_success('Running ESLint...')
  local npx = language_utils.getNpxEquivalent()
  local output = vim.fn.system(npx .. ' eslint . --ext ts,tsx,js,jsx --format stylish 2>&1')

  local files = {}
  for line in output:gmatch('[^\r\n]+') do
    local path = line:match('^([^%s].+%.tsx?)$') or line:match('^([^%s].+%.jsx?)$')
    if path then files[path] = true end
  end

  local items = {}
  for path in pairs(files) do
    table.insert(items, { text = vim.fn.fnamemodify(path, ':~'), file = path })
  end

  if #items == 0 then
    ui_utils.show_success('No ESLint issues found')
    return
  end

  local ok, snacks = pcall(require, 'snacks')
  if not ok then return end

  snacks.picker({
    title = 'ESLint Results',
    items = items,
    format = function(item)
      local icon, hl = snacks.util.icon(item.file, 'file')
      return { { icon, hl }, { ' ' }, { item.text } }
    end,
    confirm = function(picker, item)
      picker:close()
      vim.cmd('edit ' .. vim.fn.fnameescape(item.file))
    end,
  })
end

local function run_knip(args, _title, process_result)
  local pm = get_pm()
  if not pm then return end

  local cmd = pm .. ' dlx knip ' .. args
  ui_utils.show_success('Running knip...')

  async_utils.run(cmd, function(output, code)
    if output == '' then
      vim.notify('No issues found', vim.log.levels.INFO)
      return
    end

    local ok, result = pcall(vim.fn.json_decode, output)
    if not ok or not result then
      if code == 0 then
        ui_utils.show_success('Knip completed:\n' .. output:sub(1, 300))
      else
        vim.notify('Failed to parse output', vim.log.levels.ERROR)
      end
      return
    end

    process_result(result)
  end, function(_, err, code)
    vim.notify(('Knip failed (code %d): %s'):format(code, err), vim.log.levels.ERROR)
  end)
end

local function show_knip_picker(items, title)
  if #items == 0 then
    vim.notify('No issues found', vim.log.levels.INFO)
    return
  end

  local ok, snacks = pcall(require, 'snacks')
  if not ok then return end

  snacks.picker({
    title = title,
    items = items,
    format = function(item)
      local icon, hl = snacks.util.icon(item.file or '', 'file')
      return { { icon, hl }, { ' ' }, { item.text } }
    end,
    confirm = function(picker, item)
      picker:close()
      vim.cmd('edit ' .. vim.fn.fnameescape(item.file))
      if item.line then vim.api.nvim_win_set_cursor(0, { item.line, 0 }) end
    end,
  })
  ui_utils.show_success(('Found %d issues'):format(#items))
end

function M.run_knip_unused_files()
  run_knip('--reporter json', 'Knip Unused Files', function(result)
    local items = {}
    for _, file in ipairs(result.files or {}) do
      table.insert(items, { file = file, line = 1, text = file .. ' (orphaned)' })
    end
    show_knip_picker(items, 'Knip Unused Files')
  end)
end

function M.run_knip_unused_code()
  run_knip('--reporter json', 'Knip Unused Code', function(result)
    local items = {}
    for _, issue in ipairs(result.issues or {}) do
      local file = issue.file
      for _, export in ipairs(issue.exports or {}) do
        table.insert(items, { file = file, line = export.line or 1, text = ('%s:%d - export: %s'):format(file, export.line or 1, export.name or '?') })
      end
      for _, typ in ipairs(issue.types or {}) do
        table.insert(items, { file = file, line = typ.line or 1, text = ('%s:%d - type: %s'):format(file, typ.line or 1, typ.name or '?') })
      end
    end
    show_knip_picker(items, 'Knip Unused Code')
  end)
end

function M.run_knip_fix()
  local pm = get_pm()
  if not pm then return end
  ui_utils.show_success('Running knip fix...')
  async_utils.run(pm .. ' dlx knip --fix --allow-remove-files', function(out)
    ui_utils.show_success('Knip fix completed' .. (out ~= '' and ':\n' .. out or ''))
  end, function(_, err, code)
    vim.notify(('Knip fix failed (code %d): %s'):format(code, err), vim.log.levels.ERROR)
  end)
end

function M.run_knip_fix_current_folder()
  local pm = get_pm()
  if not pm then return end
  local dir = vim.fn.fnamemodify(vim.fn.expand('%:p'), ':h:.')
  if dir == '' then dir = '.' end
  ui_utils.show_success('Knip fix for: ' .. dir)
  vim.fn.jobstart(pm .. ' dlx knip --fix', { on_exit = function()
    vim.notify('Knip fix completed for ' .. dir, vim.log.levels.INFO)
  end })
end

function M.launch_android_emulator()
  local emulator = os.getenv('HOME') .. '/Library/Android/sdk/emulator/emulator'
  local avd_output = vim.fn.system(emulator .. ' -list-avds 2>/dev/null')
  local avds = {}
  for line in avd_output:gmatch('[^\n]+') do
    if line ~= '' then table.insert(avds, line) end
  end

  if #avds == 0 then
    vim.notify('No AVDs found', vim.log.levels.WARN)
    return
  end

  ui_utils.safe_select(avds, { prompt = 'Select emulator:' }, function(avd)
    vim.fn.jobstart({ emulator, '-avd', avd }, { detach = true })
    ui_utils.show_success('Launching: ' .. avd)
  end)
end

function M.fix_and_organize_typescript_imports()
  ui_utils.show_success('Finding TypeScript files...')
  local files = vim.fn.systemlist("find . -type f \\( -name '*.ts' -o -name '*.tsx' \\) -not -path '*/node_modules/*'")
  if #files == 0 then
    vim.notify('No TypeScript files found', vim.log.levels.WARN)
    return
  end

  local i = 1
  local function process_next()
    if i > #files then
      ui_utils.show_success(('Processed %d files'):format(#files))
      return
    end
    pcall(function()
      vim.cmd('edit ' .. vim.fn.fnameescape(files[i]))
      vim.lsp.buf.execute_command({
        command = '_typescript.organizeImports',
        arguments = { vim.api.nvim_buf_get_name(0) },
      })
      vim.defer_fn(function()
        vim.cmd('silent write')
        vim.cmd('bdelete')
        i = i + 1
        process_next()
      end, 300)
    end)
  end
  process_next()
end

function M.repeat_last_command()
  local last = vim.fn.histget(':', -1)
  if last == '' then
    vim.notify('No previous command', vim.log.levels.WARN)
    return
  end
  ui_utils.safe_input({ prompt = 'Command: ', default = last, completion = 'command' }, function(cmd)
    vim.cmd(cmd)
  end)
end

function M.create_make_command_runner(term_id)
  return function()
    if vim.fn.filereadable('Makefile') == 0 then
      vim.notify('No Makefile found', vim.log.levels.ERROR)
      return
    end

    local targets = {}
    local ok, iter = pcall(io.lines, 'Makefile')
    if ok then
      for line in iter do
        local target = line:match('^(%w[%w-_%.]*)%s*:')
        if target and target ~= 'PHONY' then table.insert(targets, target) end
      end
    end

    ui_utils.safe_select(targets, { prompt = 'Make target:' }, function(target)
      vim.cmd((':%dTermExec cmd="make %s"'):format(term_id or 1, target))
    end)
  end
end

function M.create_npm_update_command(type)
  local npx = language_utils.getNpxEquivalent()
  local flags = { minor = ' -t minor', major = '', patch = ' -t patch', interactive = 'i' }
  return npx .. ' npm-check-updates -u' .. (flags[type] or '')
end

function M.create_npm_update_executor(term_id, type)
  return function()
    vim.cmd((':%dTermExec cmd="%s"'):format(term_id, M.create_npm_update_command(type)))
  end
end

return M
