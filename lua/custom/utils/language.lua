local linkConstants = require('custom.constants.links')
local githubUtils = require('custom.utils.github')
local fileUtils = require('custom.utils.files')
local arrayUtils = require('custom.utils.array')
local M = {}

function M.getCurrentJavaClass()
  local currentFile = vim.fn.expand('%')
  local currentClass = vim.fn.substitute(currentFile, '.*/src/main/java/', '', '')
  currentClass = vim.fn.substitute(currentClass, '/', '.', 'g')
  currentClass = vim.fn.substitute(currentClass, '\\.java', '', '')
  return currentClass
end

function M.getJavascriptPackageManager()
  local packageManager = ''
  if vim.fn.filereadable('yarn.lock') == 1 then
    packageManager = 'yarn'
  elseif vim.fn.filereadable('package-lock.json') == 1 then
    packageManager = 'npm'
  elseif vim.fn.filereadable('pnpm-lock.yaml') == 1 then
    packageManager = 'pnpm'
  end
  return packageManager
end

function M.getJavascriptPackageManagerDevArg()
  local packageManager = M.getJavascriptPackageManager()

  if packageManager == 'yarn' then
    return '--dev'
  elseif packageManager == 'npm' then
    return '--save-dev'
  elseif packageManager == 'pnpm' then
    return '--save-dev'
  end
end

function M.listPackageJsonCommands()
  local package_json_path = vim.fn.getcwd() .. '/package.json'
  local command = "jq '.scripts | keys' " .. package_json_path
  local handle = io.popen(command)
  if handle == nil then return {} end
  local result = handle:read('*a')
  handle:close()
  local scripts = vim.fn.json_decode(result)
  return scripts
end

function M.openServerUrl(type)
  local projectNames = {}
  arrayUtils.tableMerge({ githubUtils.getRepoName() }, linkConstants.projectNames, projectNames)
  vim.ui.select(projectNames, {
    prompt = 'Select repo to open:',
  }, function(projectName)
    if projectName == nil then return end

    local url = linkConstants.projectNameToRouteObject[projectName][type]
    if url == nil then
      print('No url found for type ' .. type .. ' of project: ' .. projectName)
      return
    end
    fileUtils.open(url)
  end)
end

return M
