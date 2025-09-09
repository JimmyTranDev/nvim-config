local stringUtils = require('custom.utils.string')
local inputUtils = require('custom.utils.input')

local M = {}

function M.getCwdName()
  local currentWorkingDirectory = vim.fn.getcwd()
  return currentWorkingDirectory:match('([^/]+)$')
end

function M.listFiles(dir) return vim.fn.systemlist('ls -t ' .. dir) end

function M.listDirsWithName(folderName)
  local command = "git ls-files | xargs -n 1 dirname | uniq | grep '" .. folderName .. "'"
  return vim.fn.systemlist(command)
end

function M.getCurrentDir() return vim.cmd('pwd') end

function M.renameFile(oldFile, newFile) vim.fn.system('mv "' .. oldFile .. '" "' .. newFile .. '"') end

function M.getFileExtension(fileName) return fileName:match('^.+(%..+)$') end

function M.getPathFromRoot(path) return os.getenv('HOME') .. path end

function M.removeFileExtension(fileName) return fileName:gsub('%..*', '') end

function M.pasteMarkdownLink(fileName)
  local linkLabel = stringUtils.convertSnakeCaseToNormalCase(M.removeFileExtension(fileName))
  local markdownLink = string.format('![%s](assets/%s)', linkLabel, fileName)
  vim.fn.setreg('*', markdownLink)
  vim.cmd('normal! "*p')
end

function M.renameFileWithInput(fileName, originDir, targetDir)
  local fileExtension = M.getFileExtension(fileName)
  local rename = inputUtils.getInputFromUser('Enter new file name: ')
  local newFileName = rename .. fileExtension

  local originFile = originDir .. '/' .. fileName
  local targetFile = targetDir .. '/' .. newFileName

  M.renameFile(originFile, targetFile)
  return newFileName
end

function M.open(item)
  if vim.fn.has('mac') == 1 then
    vim.fn.system("open '" .. item .. "'")
  elseif vim.fn.has('wsl') == 1 then
    vim.fn.system("cmd.exe /c start '" .. item .. "'")
  elseif vim.fn.has('win32') == 1 then
    vim.fn.system("start '" .. item .. "'")
  elseif vim.fn.has('unix') == 1 and vim.fn.has('wsl') == 0 then
    vim.fn.system("xdg-open '" .. item .. "'")
  else
    vim.notify('Unsupported OS')
  end
end

function M.getRecusriveFileContents()
  -- Get the directory of the current file
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.fnamemodify(current_file, ':h')

  -- Initialize a table to store file contents
  local all_content = {}

  -- Helper function to recursively process directories
  local function process_directory(dir, prefix)
    -- Get all files and directories in the current directory
    local items = vim.fn.glob(dir .. '/*', false, true)

    for _, item in ipairs(items) do
      if vim.fn.isdirectory(item) == 1 then
        -- If it's a directory, recurse into it
        local dir_name = vim.fn.fnamemodify(item, ':t')
        table.insert(all_content, prefix .. '=== Directory: ' .. dir_name .. ' ===')
        table.insert(all_content, '')
        process_directory(item, prefix .. '  ') -- Add indentation for nested dirs
      else
        -- If it's a file, read its content
        local content = vim.fn.readfile(item)
        table.insert(all_content, prefix .. '=== ' .. vim.fn.fnamemodify(item, ':t') .. ' ===')
        vim.list_extend(all_content, content)
        table.insert(all_content, '') -- Add empty line between files
      end
    end
  end

  -- Start processing from the current directory
  process_directory(current_dir, '')

  -- Join all content with newlines
  local final_content = table.concat(all_content, '\n')
  return final_content
end

return M
