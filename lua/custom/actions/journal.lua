local M = {}

local JOURNAL_BASE_PATH = vim.fn.expand('~/Programming/notes.md/journal')

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
    f:write(table.concat(lines, '\n'))
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
      return i
    end
  end
  return #lines + 1
end

function M.add_journal_entry()
  vim.ui.input({ prompt = 'Journal entry: ' }, function(input)
    if not input or input == '' then
      return
    end

    local filepath = get_journal_path()
    ensure_directory_exists(filepath)

    local today = tonumber(os.date('%d'))
    local lines = read_file(filepath)
    local existing_days = parse_existing_days(lines)

    if not existing_days[today] then
      local header = format_day_header()
      local insert_line, after_day = find_insertion_point(lines, today, existing_days)
      local new_content = { '## ' .. header, '', '' }

      if after_day then
        for i = #new_content, 1, -1 do
          table.insert(lines, insert_line, new_content[i])
        end
      else
        if insert_line <= #lines then
          for i = 1, #new_content do
            table.insert(lines, insert_line + i - 1, new_content[i])
          end
        else
          if #lines > 0 and lines[#lines] ~= '' then
            table.insert(lines, '')
          end
          for _, line in ipairs(new_content) do
            table.insert(lines, line)
          end
        end
      end

      existing_days = parse_existing_days(lines)
    end

    local entry_line = find_entry_insert_line(lines, today, existing_days)
    if entry_line then
      table.insert(lines, entry_line, '- ' .. input)
    end

    if write_file(filepath, lines) then
      vim.notify('Journal entry added', vim.log.levels.INFO)
    else
      vim.notify('Failed to write journal entry', vim.log.levels.ERROR)
    end
  end)
end

return M
