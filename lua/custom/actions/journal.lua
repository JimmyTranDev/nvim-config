local M = {}

local JOURNAL_BASE_PATH = vim.fn.expand('~/Programming/JimmyTranDev/notes.md/journal')
local NOTES_REPO_PATH = vim.fn.expand('~/Programming/JimmyTranDev/notes.md')

local function get_iso_week()
  return tonumber(os.date('%W')), tonumber(os.date('%Y'))
end

local function sync_journal_repo()
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

local function format_day_header()
  local weekday = os.date('%A')
  local day = tonumber(os.date('%d'))
  local month_name = os.date('%B')
  local year = os.date('%Y')
  return string.format('%s, %d %s %s', weekday, day, month_name, year)
end

local function get_journal_path()
  local year = os.date('%Y')
  local month = os.date('%m')
  return string.format('%s/%s/%s.md', JOURNAL_BASE_PATH, year, month)
end

local function ensure_directory_exists(filepath)
  local dir = vim.fn.fnamemodify(filepath, ':h')
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
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

local function parse_existing_days(lines)
  local days = {}
  for i, line in ipairs(lines) do
    local day = line:match('^## %a+, (%d+) %a+ %d%d%d%d$')
    if day then
      days[tonumber(day)] = i
    end
  end
  return days
end

local function find_insertion_point(lines, today, existing_days)
  for day = today - 1, 1, -1 do
    if existing_days[day] then
      local next_header_line = nil
      for i = existing_days[day] + 1, #lines do
        if lines[i]:match('^## %a+, %d+ %a+ %d%d%d%d$') then
          next_header_line = i
          break
        end
      end
      return next_header_line or (#lines + 1), day
    end
  end

  for day = today + 1, 31 do
    if existing_days[day] then
      return existing_days[day], nil
    end
  end

  return #lines + 1, nil
end

local function find_entry_insert_line(lines, today, existing_days)
  if not existing_days[today] then
    return nil
  end

  local header_line = existing_days[today]
  for i = header_line + 1, #lines do
    if lines[i]:match('^## %a+, %d+ %a+ %d%d%d%d$') then
      local insert_at = i
      while insert_at > header_line + 1 and lines[insert_at - 1] == '' do
        insert_at = insert_at - 1
      end
      return insert_at
    end
  end
  return #lines + 1
end

local function capitalize_first_char(str)
  if not str or str == '' then
    return str
  end
  return str:sub(1, 1):upper() .. str:sub(2)
end

local function ensure_today_header(filepath)
  ensure_directory_exists(filepath)
  local today = tonumber(os.date('%d'))
  local lines = read_file(filepath)
  local existing_days = parse_existing_days(lines)

  if not existing_days[today] then
    local header = format_day_header()
    local insert_line, after_day = find_insertion_point(lines, today, existing_days)

    if after_day then
      table.insert(lines, insert_line, '')
      table.insert(lines, insert_line + 1, '## ' .. header)
    elseif insert_line <= #lines then
      table.insert(lines, insert_line, '## ' .. header)
      table.insert(lines, insert_line + 1, '')
    else
      if #lines > 0 then
        table.insert(lines, '')
      end
      table.insert(lines, '## ' .. header)
    end

    write_file(filepath, lines)
    existing_days = parse_existing_days(lines)
  end

  return lines, existing_days, today
end

function M.add_journal_entry()
  vim.ui.input({ prompt = 'Journal entry: ' }, function(input)
    if not input or input == '' then
      return
    end

    input = capitalize_first_char(input)

    local filepath = get_journal_path()
    local lines, existing_days, today = ensure_today_header(filepath)

    local entry_line = find_entry_insert_line(lines, today, existing_days)
    if entry_line then
      table.insert(lines, entry_line, '- ' .. input)
    end

    if write_file(filepath, lines) then
      vim.notify('Journal entry added', vim.log.levels.INFO)
      sync_journal_repo()
    else
      vim.notify('Failed to write journal entry', vim.log.levels.ERROR)
    end
  end)
end

function M.open_journal()
  local filepath = get_journal_path()
  local _, existing_days, today = ensure_today_header(filepath)

  vim.cmd('edit ' .. vim.fn.fnameescape(filepath))

  if existing_days[today] then
    vim.api.nvim_win_set_cursor(0, { existing_days[today] + 1, 0 })
    vim.cmd('normal! zz')
  end
end

return M
