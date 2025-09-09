local fileUtils = require('custom.utils.files')

local M = {}

function M.openDir()
  local path = vim.fn.expand('%:p:h')
  fileUtils.open(path)
end

function M.moveFileToAsset(dir)
  return function()
    local currentDir = vim.fn.getcwd()
    local assetDirs = fileUtils.listDirsWithName('assets')
    if #assetDirs == 0 then
      vim.notify('No assets folder found in src')
      return
    end

    local targetDir = currentDir .. '/' .. assetDirs[1]
    local originDir = fileUtils.getPathFromRoot(dir)
    local fileNames = fileUtils.listFiles(originDir)

    vim.ui.select(fileNames, {
      prompt = 'Select file to move to assets:',
    }, function(fileName)
      local newFileName = fileUtils.renameFileWithInput(fileName, originDir, targetDir)
      fileUtils.pasteMarkdownLink(newFileName)
    end)
  end
end

function M.openFileWithClipboard()
  local yanked = vim.fn.getreg('"')
  yanked = vim.fn.trim(yanked)

  if yanked == '' then
    vim.notify('No yanked content found!', vim.log.levels.WARN)
    return
  end

  vim.cmd('e ' .. vim.fn.fnameescape(yanked))
end

function M.copyAllFilesInFolder()
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  local final_content = fileUtils.getRecusriveFileContents()

  vim.fn.setreg('+', final_content)
  vim.notify('Copied content of all files in ' .. current_dir .. ' to clipboard', vim.log.levels.INFO)
end

function M.saveClipboardToFile()
  local clipboard_content = vim.fn.getreg('+')

  if clipboard_content == '' then
    vim.notify('Clipboard is empty!', vim.log.levels.WARN)
    return
  end

  vim.ui.input({
    prompt = 'Enter filename: ',
    default = '',
  }, function(filename)
    if not filename or filename == '' then
      vim.notify('No filename provided, operation cancelled', vim.log.levels.WARN)
      return
    end

    -- Get directory of the currently opened file
    local current_file_dir = vim.fn.expand('%:p:h')
    local filepath = current_file_dir .. '/' .. filename

    local ok, err = pcall(function()
      local file = io.open(filepath, 'w')
      if not file then error('Could not open file: ' .. filepath) end
      file:write(clipboard_content)
      file:close()
    end)

    if ok then
      vim.notify('File saved successfully: ' .. filepath, vim.log.levels.INFO)
    else
      vim.notify('Error saving file: ' .. err, vim.log.levels.ERROR)
    end
  end)
end

function M.yankWordAndOpen()
  vim.cmd('normal! "ayW')
  local yanked_word = vim.fn.getreg('a')
  -- yanked_word = yanked_word:gsub('^%s*(.-)%s*$', '%1')
  vim.cmd('e ' .. yanked_word)
end

function M.runClipboardCommand()
  local clipboard_content = vim.fn.getreg('+')

  if clipboard_content == '' then
    vim.notify('Clipboard is empty!', vim.log.levels.WARN)
    return
  end

  -- Trim whitespace
  clipboard_content = vim.fn.trim(clipboard_content)

  if clipboard_content == '' then
    vim.notify('Clipboard contains only whitespace!', vim.log.levels.WARN)
    return
  end

  vim.notify('Running command from clipboard: ' .. clipboard_content, vim.log.levels.INFO)

  -- Run the command in terminal
  vim.cmd(':TermExec cmd="' .. clipboard_content .. '"')
end

function M.grepInCurrentFolder()
  local utils = require('core.utils')
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = vim.fn.fnamemodify(current_file, ':h')

  local snacks = utils.safe_require('snacks')
  if snacks and snacks.picker then
    snacks.picker.grep({ cwd = current_dir })
  else
    vim.notify('Snacks picker not available', vim.log.levels.WARN)
  end
end

return M
