local M = {}

local file_utils = require('custom.utils.files')
local string_utils = require('custom.utils.string')
local git_utils = require('custom.utils.git')

local NOTES_PATH = vim.fn.expand('~/Programming/JimmyTranDev/notes/people')

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

      input = string_utils.capitalize_first_char(input)

      local filepath = NOTES_PATH .. '/' .. files[idx]
      local lines = file_utils.read_lines(filepath)
      table.insert(lines, '🩷 ' .. input .. '  ')

      if file_utils.write_lines(filepath, lines) then
        vim.notify('Entry added to ' .. choice, vim.log.levels.INFO)
        git_utils.sync_notes_repo()
      else
        vim.notify('Failed to write entry', vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
