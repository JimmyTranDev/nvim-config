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

local function findWorkspaceRoot(startPath)
  local path = startPath or vim.fn.getcwd()
  local lockfiles = {
    { file = 'bun.lockb', manager = 'bun' },
    { file = 'bun.lock', manager = 'bun' },
    { file = 'pnpm-lock.yaml', manager = 'pnpm' },
    { file = 'yarn.lock', manager = 'yarn' },
    { file = 'package-lock.json', manager = 'npm' },
  }

  while path ~= '/' and path ~= '' do
    for _, lockfile in ipairs(lockfiles) do
      local fullPath = path .. '/' .. lockfile.file
      if vim.fn.filereadable(fullPath) == 1 then return path, lockfile.manager end
    end

    local parent = vim.fn.fnamemodify(path, ':h')
    if parent == path then break end
    path = parent
  end

  return nil, nil
end

local function isWorkspace(rootPath)
  if not rootPath then return false end

  local workspaceFiles = {
    rootPath .. '/pnpm-workspace.yaml',
    rootPath .. '/lerna.json',
    rootPath .. '/nx.json',
    rootPath .. '/rush.json',
    rootPath .. '/turbo.json',
    rootPath .. '/.yarnrc.yml',
  }

  for _, file in ipairs(workspaceFiles) do
    if vim.fn.filereadable(file) == 1 then return true end
  end

  local packageJsonPath = rootPath .. '/package.json'
  if vim.fn.filereadable(packageJsonPath) == 1 then
    local ok, packageJson = pcall(vim.fn.json_decode, vim.fn.readfile(packageJsonPath))
    if ok and packageJson and packageJson.workspaces then return true end
  end

  return false
end

function M.getWorkspaceRoot()
  local rootPath, _ = findWorkspaceRoot()
  return rootPath
end

function M.isInWorkspace()
  local rootPath = M.getWorkspaceRoot()
  return isWorkspace(rootPath)
end

function M.getJavascriptPackageManager()
  local rootPath, packageManager = findWorkspaceRoot()

  if packageManager then
    if isWorkspace(rootPath) then return packageManager end

    return packageManager
  end

  if vim.fn.filereadable('bun.lockb') == 1 then
    return 'bun'
  elseif vim.fn.filereadable('bun.lock') == 1 then
    return 'bun'
  elseif vim.fn.filereadable('yarn.lock') == 1 then
    return 'yarn'
  elseif vim.fn.filereadable('package-lock.json') == 1 then
    return 'npm'
  elseif vim.fn.filereadable('pnpm-lock.yaml') == 1 then
    return 'pnpm'
  end

  return ''
end

function M.getJavascriptPackageManagerDevArg()
  local packageManager = M.getJavascriptPackageManager()

  if packageManager == 'yarn' then
    return '--dev'
  elseif packageManager == 'npm' then
    return '--save-dev'
  elseif packageManager == 'pnpm' then
    return '--save-dev'
  elseif packageManager == 'bun' then
    return '--dev'
  end
end

function M.getNpxEquivalent()
  local packageManager = M.getJavascriptPackageManager()

  if packageManager == 'yarn' then
    return 'yarn dlx'
  elseif packageManager == 'pnpm' then
    return 'pnpm dlx'
  elseif packageManager == 'bun' then
    return 'bunx'
  else
    return 'npx'
  end
end

function M.listPackageJsonCommands()
  local scripts = {}

  local current_package_json = vim.fn.getcwd() .. '/package.json'
  if vim.fn.filereadable(current_package_json) == 1 then
    local current_scripts = M.getScriptsFromPackageJson(current_package_json)
    if current_scripts and #current_scripts > 0 then scripts = current_scripts end
  end

  if #scripts == 0 then
    local workspaceRoot = M.getWorkspaceRoot()
    if workspaceRoot then
      local root_package_json = workspaceRoot .. '/package.json'
      if vim.fn.filereadable(root_package_json) == 1 then
        local root_scripts = M.getScriptsFromPackageJson(root_package_json)
        if root_scripts then scripts = root_scripts end
      end
    end
  end

  return scripts
end

function M.getScriptsFromPackageJson(packageJsonPath)
  local command = "jq '.scripts | keys' " .. packageJsonPath
  local handle = io.popen(command)
  if handle == nil then return {} end
  local result = handle:read('*a')
  handle:close()

  local ok, scripts = pcall(vim.fn.json_decode, result)
  if ok and scripts then return scripts end
  return {}
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
