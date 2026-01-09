local M = {}

function M.required(value, name)
  local field_name = name or 'value'

  if value == nil then return false, field_name .. ' is required' end

  if type(value) == 'string' and value == '' then return false, field_name .. ' cannot be empty' end

  return true
end

function M.string(value, min_length, max_length)
  if type(value) ~= 'string' then return false, 'Expected string, got ' .. type(value) end

  local min_len = min_length or 1
  if #value < min_len then return false, string.format('String must be at least %d characters', min_len) end

  if max_length and #value > max_length then return false, string.format('String must be no more than %d characters', max_length) end

  return true
end

function M.table(value, min_items)
  if type(value) ~= 'table' then return false, 'Expected table, got ' .. type(value) end

  if min_items and #value < min_items then return false, string.format('Table must have at least %d items', min_items) end

  return true
end

function M.file_exists(path)
  local is_valid, error_msg = M.string(path)
  if not is_valid then return false, 'Invalid file path: ' .. error_msg end

  local stat = vim.loop.fs_stat(path)
  if not stat then return false, 'File does not exist: ' .. path end

  if stat.type ~= 'file' then return false, 'Path is not a file: ' .. path end

  return true
end

function M.directory_exists(path)
  local is_valid, error_msg = M.string(path)
  if not is_valid then return false, 'Invalid directory path: ' .. error_msg end

  local stat = vim.loop.fs_stat(path)
  if not stat then return false, 'Directory does not exist: ' .. path end

  if stat.type ~= 'directory' then return false, 'Path is not a directory: ' .. path end

  return true
end

function M.filename(filename)
  local is_valid, error_msg = M.string(filename)
  if not is_valid then return false, error_msg end

  if filename:match('[<>:"|?*]') then return false, 'Filename contains invalid characters' end

  local reserved = {
    'CON',
    'PRN',
    'AUX',
    'NUL',
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'LPT1',
    'LPT2',
    'LPT3',
    'LPT4',
    'LPT5',
    'LPT6',
    'LPT7',
    'LPT8',
    'LPT9',
  }

  local base_name = filename:match('^([^.]+)')
  if base_name then
    for _, reserved_name in ipairs(reserved) do
      if base_name:upper() == reserved_name then return false, 'Filename uses reserved name: ' .. reserved_name end
    end
  end

  return true
end

function M.git_repo()
  local git_utils = require('custom.utils.git')
  if not git_utils.is_git_repo() then return false, 'Not in a git repository' end

  return true
end

function M.git_branch_name(branch_name)
  local is_valid, error_msg = M.string(branch_name)
  if not is_valid then return false, error_msg end

  if branch_name:match('^%.') or branch_name:match('%.$') then return false, 'Branch name cannot start or end with a dot' end

  if branch_name:match('%.%.') then return false, 'Branch name cannot contain consecutive dots' end

  if branch_name:match('[~^:?*%[\\%s]') then return false, 'Branch name contains invalid characters' end

  if branch_name:match('^%-') or branch_name:match('%-$') then return false, 'Branch name cannot start or end with a hyphen' end

  return true
end

function M.git_sha(sha)
  local is_valid, error_msg = M.string(sha)
  if not is_valid then return false, error_msg end

  if not sha:match('^[a-fA-F0-9]+$') then return false, 'Invalid SHA format' end

  if #sha < 7 or #sha > 40 then return false, 'SHA must be between 7 and 40 characters' end

  return true
end

function M.url(url)
  local is_valid, error_msg = M.string(url)
  if not is_valid then return false, error_msg end

  if not url:match('^https?://') then return false, 'URL must start with http:// or https://' end

  if not url:match('://[%w.-]+') then return false, 'Invalid URL format' end

  return true
end

function M.github_url(url)
  local is_valid, error_msg = M.url(url)
  if not is_valid then return false, error_msg end

  if not url:match('github%.com') then return false, 'Not a GitHub URL' end

  return true
end

function M.chain(value, validators)
  if not validators or #validators == 0 then return true end

  for _, validator in ipairs(validators) do
    local is_valid, error_msg = validator(value)
    if not is_valid then return false, error_msg end
  end

  return true
end

function M.custom(constraints)
  return function(value)
    for constraint_name, constraint_value in pairs(constraints) do
      local validator = M[constraint_name]
      if validator then
        local is_valid, error_msg = validator(value, constraint_value)
        if not is_valid then return false, error_msg end
      end
    end
    return true
  end
end

function M.sanitize_string(input)
  if type(input) ~= 'string' then return '' end

  input = input:gsub('^%s+', ''):gsub('%s+$', '')

  input = input:gsub('[%c]', '')

  return input
end

function M.sanitize_filename(filename)
  if type(filename) ~= 'string' then return '' end

  filename = filename:gsub('[<>:"|?*]', '_')

  filename = filename:gsub('^[%. ]+', ''):gsub('[%. ]+$', '')

  filename = filename:gsub('_+', '_')

  return filename
end

return M

