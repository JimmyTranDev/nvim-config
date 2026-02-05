local string_utils = require('custom.utils.string')
local input_utils = require('custom.utils.input')

local M = {}

function M.get_cwd_name()
  return vim.fn.getcwd():match('([^/]+)$') or ''
end

function M.get_current_dir()
  return vim.cmd('pwd')
end

function M.get_path_from_home(relative_path)
  if not relative_path then error('Relative path is required') end
  local home = os.getenv('HOME')
  if not home then error('HOME environment variable not set') end
  return home .. relative_path
end

function M.list_files(dir)
  if type(dir) ~= 'string' then return {} end
  local result = vim.fn.systemlist('ls -t ' .. vim.fn.shellescape(dir))
  return vim.v.shell_error == 0 and result or {}
end

function M.find_dirs_with_name(folder_name)
  if type(folder_name) ~= 'string' then return {} end
  local result = vim.fn.systemlist(("git ls-files | xargs -n 1 dirname | uniq | grep '%s'"):format(folder_name))
  return vim.v.shell_error == 0 and result or {}
end

function M.get_file_extension(filename)
  if type(filename) ~= 'string' then return nil end
  return filename:match('^.+(%..+)$')
end

function M.remove_file_extension(filename)
  if type(filename) ~= 'string' then return '' end
  return filename:gsub('%..*', '')
end

function M.rename_file(old_path, new_path)
  if not old_path or not new_path then return false end
  vim.fn.system(('mv %s %s'):format(vim.fn.shellescape(old_path), vim.fn.shellescape(new_path)))
  return vim.v.shell_error == 0
end

function M.rename_file_interactive(filename, origin_dir, target_dir)
  if not filename or not origin_dir or not target_dir then return nil end

  local extension = M.get_file_extension(filename)
  local new_name = input_utils.get_input('Enter new file name: ')
  if not new_name or new_name == '' then return nil end

  local new_filename = new_name .. (extension or '')
  if M.rename_file(origin_dir .. '/' .. filename, target_dir .. '/' .. new_filename) then
    return new_filename
  end
  return nil
end

function M.open(item)
  if type(item) ~= 'string' then
    vim.notify('Invalid item to open', vim.log.levels.ERROR)
    return
  end

  local escaped = vim.fn.shellescape(item)
  local cmd = vim.fn.has('mac') == 1 and 'open '
    or vim.fn.has('wsl') == 1 and 'cmd.exe /c start '
    or vim.fn.has('win32') == 1 and 'start '
    or vim.fn.has('unix') == 1 and 'xdg-open '
    or nil

  if cmd then
    vim.fn.system(cmd .. escaped)
  else
    vim.notify('Unsupported operating system', vim.log.levels.ERROR)
  end
end

function M.paste_markdown_link(filename)
  if not filename then return end
  local label = string_utils.snake_to_normal(M.remove_file_extension(filename))
  local link = ('![%s](assets/%s)'):format(label, filename)
  vim.fn.setreg('*', link)
  vim.cmd('normal! "*p')
end

function M.get_recursive_file_contents()
  local current_dir = vim.fn.fnamemodify(vim.fn.expand('%:p'), ':h')
  local content = {}

  local function process_dir(dir, prefix)
    for _, item in ipairs(vim.fn.glob(dir .. '/*', false, true)) do
      if vim.fn.isdirectory(item) == 1 then
        table.insert(content, prefix .. '=== Directory: ' .. vim.fn.fnamemodify(item, ':t') .. ' ===')
        table.insert(content, '')
        process_dir(item, prefix .. '  ')
      else
        local ok, file_content = pcall(vim.fn.readfile, item)
        if ok then
          table.insert(content, prefix .. '=== ' .. vim.fn.fnamemodify(item, ':t') .. ' ===')
          vim.list_extend(content, file_content)
          table.insert(content, '')
        end
      end
    end
  end

  process_dir(current_dir, '')
  return table.concat(content, '\n')
end

return M
