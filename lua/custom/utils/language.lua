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

-- Helper function to find workspace root by traversing up the directory tree
local function findWorkspaceRoot(startPath)
  local path = startPath or vim.fn.getcwd()
  local lockfiles = {
    { file = 'pnpm-lock.yaml', manager = 'pnpm' },
    { file = 'yarn.lock', manager = 'yarn' },
    { file = 'package-lock.json', manager = 'npm' }
  }
  
  -- Traverse up the directory tree
  while path ~= '/' and path ~= '' do
    -- Check for lockfiles in current directory
    for _, lockfile in ipairs(lockfiles) do
      local fullPath = path .. '/' .. lockfile.file
      if vim.fn.filereadable(fullPath) == 1 then
        return path, lockfile.manager
      end
    end
    
    -- Move up one directory
    local parent = vim.fn.fnamemodify(path, ':h')
    if parent == path then break end -- Reached root
    path = parent
  end
  
  return nil, nil
end

-- Helper function to detect if we're in a workspace/monorepo
local function isWorkspace(rootPath)
  if not rootPath then return false end
  
  local workspaceFiles = {
    rootPath .. '/pnpm-workspace.yaml',
    rootPath .. '/lerna.json'
  }
  
  -- Check for workspace config files
  for _, file in ipairs(workspaceFiles) do
    if vim.fn.filereadable(file) == 1 then
      return true
    end
  end
  
  -- Check for workspaces field in package.json
  local packageJsonPath = rootPath .. '/package.json'
  if vim.fn.filereadable(packageJsonPath) == 1 then
    local ok, packageJson = pcall(vim.fn.json_decode, vim.fn.readfile(packageJsonPath))
    if ok and packageJson and packageJson.workspaces then
      return true
    end
  end
  
  return false
end

-- Get the workspace root path (useful for monorepo operations)
function M.getWorkspaceRoot()
  local rootPath, _ = findWorkspaceRoot()
  return rootPath
end

-- Check if the current directory is within a monorepo workspace
function M.isInWorkspace()
  local rootPath = M.getWorkspaceRoot()
  return isWorkspace(rootPath)
end

function M.getJavascriptPackageManager()
  -- Try to find workspace root first
  local rootPath, packageManager = findWorkspaceRoot()
  
  if packageManager then
    -- If we found a lockfile in a parent directory, check if it's a workspace
    if isWorkspace(rootPath) then
      return packageManager
    end
    
    -- Even if not a workspace, use the detected package manager from root
    return packageManager
  end
  
  -- Fallback to original behavior - check current directory only
  if vim.fn.filereadable('yarn.lock') == 1 then
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
  end
end

-- Get the workspace root path (useful for monorepo operations)
function M.getWorkspaceRoot()
  local rootPath, _ = findWorkspaceRoot()
  return rootPath
end

-- Check if the current directory is within a monorepo workspace
function M.isInWorkspace()
  local rootPath = M.getWorkspaceRoot()
  return isWorkspace(rootPath)
end

function M.listPackageJsonCommands()
  -- First try to find package.json in current directory
  local package_json_path = vim.fn.getcwd() .. '/package.json'
  
  -- If not found, try workspace root
  if vim.fn.filereadable(package_json_path) ~= 1 then
    local workspaceRoot = M.getWorkspaceRoot()
    if workspaceRoot then
      package_json_path = workspaceRoot .. '/package.json'
    end
  end
  
  if vim.fn.filereadable(package_json_path) ~= 1 then
    return {}
  end
  
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
