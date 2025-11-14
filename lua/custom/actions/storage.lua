-- =============================================================================
-- Storage Action Functions
-- Cloud storage and secrets management utilities
-- =============================================================================

local storage_utils = require('custom.utils.storage')
local ui_utils = require('custom.utils.ui')
local validation = require('custom.utils.validation')

local M = {}

-- =============================================================================
-- Configuration
-- =============================================================================

local SECRETS_PATH = os.getenv('HOME') .. '/Programming/secrets'

local TEMPLATE_FILES = {
  -- prompts.json template removed (AI functionality removed)
  {
    name = 'technical_links.json',
    content = {},
  },
  {
    name = 'useful_links.json',
    content = {},
  },
}

-- =============================================================================
-- Private Helper Functions
-- =============================================================================

--- Get B2 environment variables
---@return table|nil credentials B2 credentials or nil if missing
local function get_b2_credentials()
  local bucket_name = os.getenv('B2_BUCKET_NAME')
  local application_key_id = os.getenv('B2_APPLICATION_KEY_ID')
  local application_key = os.getenv('B2_APPLICATION_KEY')
  
  if not validation.is_non_empty_string(bucket_name) or
     not validation.is_non_empty_string(application_key_id) or
     not validation.is_non_empty_string(application_key) then
    return nil
  end
  
  return {
    bucket_name = bucket_name,
    application_key_id = application_key_id,
    application_key = application_key,
  }
end

--- Create template file if it doesn't exist
---@param template table Template file configuration
---@param secrets_path string Base secrets directory path
---@return boolean success True if file was created or already exists
local function create_template_file(template, secrets_path)
  local file_path = secrets_path .. '/' .. template.name
  
  -- Check if file already exists
  local existing_file = io.open(file_path, 'r')
  if existing_file then
    existing_file:close()
    return true
  end
  
  -- Create new file
  local ok, err = pcall(function()
    local file = io.open(file_path, 'w')
    if not file then
      error('Could not create file: ' .. file_path)
    end
    
    local content = vim.fn.json_encode(template.content)
    file:write(content)
    file:close()
    
    ui_utils.show_info('Created template file: ' .. file_path)
  end)
  
  if not ok then
    vim.notify('Failed to create template file ' .. template.name .. ': ' .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  
  return true
end

--- Build B2 sync command
---@param credentials table B2 credentials
---@param local_path string Local directory path
---@return string command B2 sync command
local function build_sync_command(credentials, local_path)
  return string.format(
    'b2 account authorize "%s" "%s" && b2 sync "%s" "b2://%s" --excludeRegex ".*\\.m2/repository/.*"',
    credentials.application_key_id,
    credentials.application_key,
    local_path,
    credentials.bucket_name
  )
end

-- =============================================================================
-- Public API Functions
-- =============================================================================

--- Initialize secrets directory with template files
---@return boolean success True if initialization was successful
function M.init_secrets_directory()
  if not storage_utils.ensure_directory(SECRETS_PATH) then
    vim.notify('Failed to create secrets directory', vim.log.levels.ERROR)
    return false
  end
  
  ui_utils.show_info('Initializing secrets directory...')
  
  local success_count = 0
  for _, template in ipairs(TEMPLATE_FILES) do
    if create_template_file(template, SECRETS_PATH) then
      success_count = success_count + 1
    end
  end
  
  if success_count == #TEMPLATE_FILES then
    -- Reset notification flags for clean slate
    local json_utils = require('custom.utils.json')
    json_utils.reset_notification_flags()
    
    ui_utils.show_success('Secrets directory initialized successfully!')
    return true
  else
    vim.notify(
      string.format('Partial initialization: %d/%d files created', success_count, #TEMPLATE_FILES),
      vim.log.levels.WARN
    )
    return false
  end
end

--- Sync secrets to cloud storage using B2
---@return boolean success True if sync was successful
function M.sync_secrets_simple()
  local credentials = get_b2_credentials()
  if not credentials then
    vim.notify('B2 environment variables not set (B2_BUCKET_NAME, B2_APPLICATION_KEY_ID, B2_APPLICATION_KEY)', vim.log.levels.ERROR)
    return false
  end
  
  if not storage_utils.ensure_directory(SECRETS_PATH) then
    vim.notify('Secrets directory does not exist', vim.log.levels.ERROR)
    return false
  end
  
  local sync_cmd = build_sync_command(credentials, SECRETS_PATH)
  
  ui_utils.show_info('Syncing secrets to cloud storage...')
  
  local success = os.execute(sync_cmd)
  if success then
    ui_utils.show_success('Secrets synchronized successfully')
    return true
  else
    vim.notify('Failed to sync secrets to cloud storage', vim.log.levels.ERROR)
    return false
  end
end

-- Create user commands
vim.api.nvim_create_user_command('InitSecrets', M.init_secrets_directory, {
  desc = 'Initialize secrets directory with template files',
})

vim.api.nvim_create_user_command('SyncSecrets', M.sync_secrets_simple, {
  desc = 'Sync secrets to cloud storage',
})

return M
