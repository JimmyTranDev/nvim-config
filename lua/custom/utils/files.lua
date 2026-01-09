local string_utils = require('custom.utils.string')
local input_utils = require('custom.utils.input')

local M = {}

function M.get_cwd_name()
  local cwd = vim.fn.getcwd()
  return cwd:match('([^/]+)$') or ''
end

function M.get_current_dir() return vim.cmd('pwd') end

function M.get_path_from_home(relative_path)
  if not relative_path then error('Relative path is required') end

  local home = os.getenv('HOME')
  if not home then error('HOME environment variable not set') end

  return home .. relative_path
end

function M.list_files(dir)
  if not dir or type(dir) ~= 'string' then return {} end

  local result = vim.fn.systemlist('ls -t ' .. vim.fn.shellescape(dir))
  return vim.v.shell_error == 0 and result or {}
end

function M.find_dirs_with_name(folder_name)
  if not folder_name or type(folder_name) ~= 'string' then return {} end

  local command = string.format("git ls-files | xargs -n 1 dirname | uniq | grep '%s'", folder_name)
  local result = vim.fn.systemlist(command)
  return vim.v.shell_error == 0 and result or {}
end

function M.get_file_extension(filename)
  if not filename or type(filename) ~= 'string' then return nil end

  return filename:match('^.+(%..+)$')
end

function M.remove_file_extension(filename)
  if not filename or type(filename) ~= 'string' then return '' end

  return filename:gsub('%..*', '')
end

function M.rename_file(old_path, new_path)
  if not old_path or not new_path then return false end

  local result = vim.fn.system(string.format('mv %s %s', vim.fn.shellescape(old_path), vim.fn.shellescape(new_path)))

  return vim.v.shell_error == 0
end

function M.rename_file_interactive(filename, origin_dir, target_dir)
  if not filename or not origin_dir or not target_dir then return nil end

  local extension = M.get_file_extension(filename)
  local new_name = input_utils.get_input('Enter new file name: ')

  if not new_name or new_name == '' then return nil end

  local new_filename = new_name .. (extension or '')
  local origin_path = origin_dir .. '/' .. filename
  local target_path = target_dir .. '/' .. new_filename

  if M.rename_file(origin_path, target_path) then return new_filename end

  return nil
end

function M.open(item)
  if not item or type(item) ~= 'string' then
    vim.notify('Invalid item to open', vim.log.levels.ERROR)
    return
  end

  local escaped_item = vim.fn.shellescape(item)

  if vim.fn.has('mac') == 1 then
    vim.fn.system('open ' .. escaped_item)
  elseif vim.fn.has('wsl') == 1 then
    vim.fn.system('cmd.exe /c start ' .. escaped_item)
  elseif vim.fn.has('win32') == 1 then
    vim.fn.system('start ' .. escaped_item)
  elseif vim.fn.has('unix') == 1 then
    vim.fn.system('xdg-open ' .. escaped_item)
  else
    vim.notify('Unsupported operating system', vim.log.levels.ERROR)
  end
end

function M.paste_markdown_link(filename)
  if not filename then return end

  local name_without_ext = M.remove_file_extension(filename)
  local label = string_utils.convertSnakeCaseToNormalCase(name_without_ext)
  local markdown_link = string.format('![%s](assets/%s)', label, filename)

  vim.fn.setreg('*', markdown_link)
  vim.cmd('normal! "*p')
end

function M.get_recursive_file_contents()
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  local all_content = {}

  local function process_directory(dir, prefix)
    local items = vim.fn.glob(dir .. '/*', false, true)

    for _, item in ipairs(items) do
      if vim.fn.isdirectory(item) == 1 then
        local dir_name = vim.fn.fnamemodify(item, ':t')
        table.insert(all_content, prefix .. '=== Directory: ' .. dir_name .. ' ===')
        table.insert(all_content, '')
        process_directory(item, prefix .. '  ')
      else
        local ok, content = pcall(vim.fn.readfile, item)
        if ok then
          table.insert(all_content, prefix .. '=== ' .. vim.fn.fnamemodify(item, ':t') .. ' ===')
          vim.list_extend(all_content, content)
          table.insert(all_content, '')
        end
      end
    end
  end

  process_directory(current_dir, '')
  return table.concat(all_content, '\n')
end

return M
