local M = {}

local NOTES_PATH = vim.fn.expand('~/Programming/JimmyTranDev/notes/people')
local NOTES_REPO_PATH = vim.fn.expand('~/Programming/JimmyTranDev/notes')

local function get_iso_week()
  return tonumber(os.date('%W')), tonumber(os.date('%Y'))
end

local function sync_notes_repo()
  local repo = NOTES_REPO_PATH
  vim.system({ 'git', '-C', repo, 'add', '.' }, {}, function(add_result)
    if add_result.code ~= 0 then return end

    vim.system({ 'git', '-C', repo, 'log', '-1', '--format=%s' }, {}, function(log_result)
      local week, year = get_iso_week()
      local last_log = (log_result.stdout or ''):gsub('%s+$', '')
      local expected_prefix = 'journal: week '

      local commit_args
      if last_log:sub(1, #expected_prefix) == expected_prefix then
        commit_args = { 'git', '-C', repo, 'commit', '--amend', '--no-edit' }
      else
        local msg = string.format('journal: week %d %d', week, year)
        commit_args = { 'git', '-C', repo, 'commit', '-m', msg }
      end

      vim.system(commit_args, {}, function(commit_result)
        if commit_result.code ~= 0 then return end
        vim.system({ 'git', '-C', repo, 'push', '--force-with-lease' })
      end)
    end)
  end)
end

local function read_file(filepath)
  local lines = {}
  local f = io.open(filepath, 'r')
  if f then
    for line in f:lines() do
      table.insert(lines, line)
    end
    f:close()
  end
  return lines
end

local function write_file(filepath, lines)
  local f = io.open(filepath, 'w')
  if f then
    f:write(table.concat(lines, '\n') .. '\n')
    f:close()
    return true
  end
  return false
end

local function capitalize_first_char(str)
  if not str or str == '' then
    return str
  end
  return str:sub(1, 1):upper() .. str:sub(2)
end

local function get_notes_files()
  local files = {}
  local handle = vim.loop.fs_scandir(NOTES_PATH)
  if not handle then return files end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if type == 'file' and name:match('%.md$') then
      table.insert(files, name)
    end
  end

  table.sort(files)
  return files
end

function M.add_notes_entry()
  local files = get_notes_files()
  if #files == 0 then
    vim.notify('No files found in notes/people', vim.log.levels.WARN)
    return
  end

  local display_names = {}
  for _, file in ipairs(files) do
    table.insert(display_names, file:gsub('%.md$', ''))
  end

  vim.ui.select(display_names, { prompt = 'Select note: ' }, function(choice, idx)
    if not choice then return end

    vim.ui.input({ prompt = 'Entry for ' .. choice .. ': ' }, function(input)
      if not input or input == '' then return end

      input = capitalize_first_char(input)

      local filepath = NOTES_PATH .. '/' .. files[idx]
      local lines = read_file(filepath)
      table.insert(lines, '🩷 ' .. input .. '  ')

      if write_file(filepath, lines) then
        vim.notify('Entry added to ' .. choice, vim.log.levels.INFO)
        sync_notes_repo()
      else
        vim.notify('Failed to write entry', vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
