local M = {}

function M.logHistory(_, commitMessage)
  local notesDir = vim.fn.expand('~/Programming/notes.md')
  local message = commitMessage .. '  '

  local ignoreFiles = { 'notes.md' }
  for _, fileName in ipairs(ignoreFiles) do
    if string.find(message, fileName) then return end
  end

  local currentWeek = os.date('%V')
  local currentYear = os.date('%Y')
  local shortDate = os.date('%d.%m.%Y')
  local dayName = os.date('%A')

  local title = string.format('# Week %s, %s', currentWeek, currentYear)
  local dayTitle = string.format('## %s (%s)', dayName, shortDate)
  local logFile = string.format('%s-%s.md', currentYear, currentWeek)
  local repoName = require('custom.utils.github').getRepoName()
  local logFilePath = string.format('%s/%s/%s', notesDir, repoName, logFile)

  if vim.fn.filereadable(logFilePath) == 0 then
    vim.fn.writefile({ title, '', dayTitle, message }, logFilePath)
  else
    local lines = vim.fn.readfile(logFilePath)
    local hasTitle, hasDay = false, false

    for _, line in ipairs(lines) do
      if line == title then hasTitle = true end
      if line == dayTitle then hasDay = true end
      if hasTitle and hasDay then break end
    end

    if not hasTitle then table.insert(lines, title) end
    if not hasDay then
      if #lines > 0 then table.insert(lines, '') end
      table.insert(lines, dayTitle)
    end

    table.insert(lines, message)
    vim.fn.writefile(lines, logFilePath)
  end

  local gitCmd = string.format('git -C %s', notesDir)
  local termExec = function(cmd) vim.cmd(string.format("TermExec5 open=0 cmd='%s %s'", gitCmd, cmd)) end

  termExec('pull --no-rebase')
  termExec('add .')
  termExec([[commit --no-verify -m "feat: ✨ update"]])
  termExec('push')

  vim.notify('Log entry added to ' .. logFile, vim.log.levels.INFO, { title = 'Programming Log' })
end

return M
