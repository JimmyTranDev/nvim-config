-- =============================================================================
-- Prompt Management System
-- =============================================================================

local M = {}

-- Configuration constants
local PROMPTS_FILE = vim.fn.expand('~/Programming/secrets/prompts.json')
local SECRETS_DIR = vim.fn.expand('~/Programming/secrets')

---Check if a file exists and is readable
---@param filepath string Path to the file
---@return boolean exists Whether the file exists and is readable
local function file_exists(filepath)
  local stat = (vim.uv or vim.loop).fs_stat(filepath)
  return stat and stat.type == 'file'
end

---Check if a directory exists
---@param dirpath string Path to the directory
---@return boolean exists Whether the directory exists
local function directory_exists(dirpath)
  local stat = (vim.uv or vim.loop).fs_stat(dirpath)
  return stat and stat.type == 'directory'
end

---Safely read file contents
---@param filepath string Path to the file
---@return string|nil content File contents or nil if failed
---@return string|nil error Error message if failed
local function safe_read_file(filepath)
  local file, err = io.open(filepath, 'r')
  if not file then
    return nil, err
  end
  
  local content = file:read('*a')
  file:close()
  
  return content, nil
end

---Safely parse JSON content
---@param content string JSON content to parse
---@return table|nil data Parsed data or nil if failed
---@return string|nil error Error message if failed
local function safe_json_decode(content)
  if not content or content == '' then
    return nil, 'Empty content'
  end
  
  local ok, result = pcall(vim.json.decode, content)
  if not ok then
    return nil, 'Invalid JSON format: ' .. tostring(result)
  end
  
  return result, nil
end

---Validate prompts data structure
---@param data table Data to validate
---@return boolean valid Whether the data is valid
---@return string|nil error Error message if invalid
local function validate_prompts_data(data)
  if type(data) ~= 'table' then
    return false, 'Prompts data must be a table'
  end
  
  -- Check if promptRoles exists and is a table
  if data.promptRoles and type(data.promptRoles) ~= 'table' then
    return false, 'promptRoles must be a table'
  end
  
  return true, nil
end

---Provide helpful guidance when prompts are not available
---@param reason string Reason why prompts are not available
local function provide_guidance(reason)
  local messages = {
    no_secrets_dir = {
      message = 'Secrets directory does not exist. Use <Leader>;fI to initialize it.',
      level = vim.log.levels.INFO
    },
    no_prompts_file = {
      message = 'Could not find prompts.json file: ' .. PROMPTS_FILE,
      level = vim.log.levels.WARN
    },
    file_read_error = {
      message = 'Could not read prompts.json file: ' .. PROMPTS_FILE,
      level = vim.log.levels.ERROR
    },
    parse_error = {
      message = 'Could not parse prompts.json file - invalid JSON format',
      level = vim.log.levels.ERROR
    },
    validation_error = {
      message = 'prompts.json has invalid structure',
      level = vim.log.levels.ERROR
    }
  }
  
  local guidance = messages[reason] or {
    message = 'Unknown error loading prompts: ' .. reason,
    level = vim.log.levels.ERROR
  }
  
  vim.notify(guidance.message, guidance.level)
end

---Load prompts from the secrets directory
---@return table prompts Loaded prompts data (empty table if failed)
local function load_prompts()
  -- Check if secrets directory exists
  if not directory_exists(SECRETS_DIR) then
    -- Lazy load storage to avoid circular dependency
    local ok, storage = pcall(require, 'custom.utils.storage')
    if ok and not storage.secrets_directory_exists() then
      provide_guidance('no_secrets_dir')
    else
      provide_guidance('no_secrets_dir')
    end
    return {}
  end
  
  -- Check if prompts file exists
  if not file_exists(PROMPTS_FILE) then
    provide_guidance('no_prompts_file')
    return {}
  end
  
  -- Read file contents
  local content, read_err = safe_read_file(PROMPTS_FILE)
  if not content then
    provide_guidance('file_read_error')
    return {}
  end
  
  -- Parse JSON
  local data, parse_err = safe_json_decode(content)
  if not data then
    provide_guidance('parse_error')
    return {}
  end
  
  -- Validate structure
  local valid, validation_err = validate_prompts_data(data)
  if not valid then
    provide_guidance('validation_error')
    return {}
  end
  
  return data
end

---Get all available prompt roles
---@return table roles Available prompt roles
function M.get_prompt_roles()
  return M.prompt_roles or {}
end

---Check if prompts are available
---@return boolean available Whether prompts are loaded and available
function M.has_prompts()
  return next(M.prompt_roles) ~= nil
end

---Reload prompts from file
---@return boolean success Whether reload was successful
function M.reload_prompts()
  local prompts_data = load_prompts()
  M.prompt_roles = prompts_data.promptRoles or {}
  
  if M.has_prompts() then
    vim.notify('Prompts reloaded successfully', vim.log.levels.INFO)
    return true
  else
    vim.notify('Failed to reload prompts', vim.log.levels.WARN)
    return false
  end
end

-- =============================================================================
-- Initialization
-- =============================================================================

-- Load prompts on module initialization
local prompts_data = load_prompts()
M.prompt_roles = prompts_data.promptRoles or {}

-- Legacy compatibility (maintain camelCase for existing usage)
M.promptRoles = M.prompt_roles

return M
