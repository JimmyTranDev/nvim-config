local M = {}

-- B2 Cloud Storage sync utility
local function ensure_directory(dirpath)
  local cmd = string.format('mkdir -p "%s"', dirpath)
  local result = os.execute(cmd)
  if not result then
    print('Error: Failed to create directory: ' .. dirpath)
    return false
  end
  return true
end

-- Check if secrets directory exists and create it if it doesn't
function M.ensure_secrets_directory()
  local secrets_path = os.getenv('HOME') .. '/Programming/secrets'
  return ensure_directory(secrets_path)
end

-- Check if secrets directory exists
function M.secrets_directory_exists()
  local secrets_path = os.getenv('HOME') .. '/Programming/secrets'
  local stat = vim.loop.fs_stat(secrets_path)
  return stat and stat.type == 'directory'
end

-- Initialize secrets directory with template files
function M.init_secrets_directory()
  local secrets_path = os.getenv('HOME') .. '/Programming/secrets'

  if not ensure_directory(secrets_path) then return false end

  -- Create template files if they don't exist
  local template_files = {
    {
      name = 'prompts.json',
      content = vim.fn.json_encode({
        promptRoles = {},
        newsPrompt = '',
        marketStatusPrompt = '',
        storyGeneratePrompt = '',
        testIdsPrompt = '',
        accessibilityImproveReactPrompt = '',
        langaugePrompt = '',
      }),
    },
    {
      name = 'technical_links.json',
      content = vim.fn.json_encode({}),
    },
    {
      name = 'useful_links.json',
      content = vim.fn.json_encode({}),
    },
  }

  for _, template in ipairs(template_files) do
    local file_path = secrets_path .. '/' .. template.name
    local file = io.open(file_path, 'r')
    if not file then
      -- File doesn't exist, create it
      file = io.open(file_path, 'w')
      if file then
        file:write(template.content)
        file:close()
        print('Created template file: ' .. file_path)
      else
        print('Error: Failed to create template file: ' .. file_path)
        return false
      end
    else
      file:close()
    end
  end

  -- Reset notification flags so users see success message
  local jsonUtils = require('custom.utils.json')
  jsonUtils.reset_notification_flags()

  print('Secrets directory initialized successfully!')
  return true
end

-- Simplified sync that uses rsync-like behavior
function M.sync_secrets_simple()
  local local_path = os.getenv('HOME') .. '/Programming/secrets'
  local bucket_name = os.getenv('B2_BUCKET_NAME')
  local application_key_id = os.getenv('B2_APPLICATION_KEY_ID')
  local application_key = os.getenv('B2_APPLICATION_KEY')

  if not bucket_name or not application_key_id or not application_key then
    print('Error: B2 environment variables not set')
    return false
  end

  if not ensure_directory(local_path) then return false end

  -- Simple sync using B2 CLI sync command with exclusions
  local sync_cmd = string.format(
    'b2 account authorize "%s" "%s" && b2 sync "%s" "b2://%s" --excludeRegex ".*\\.m2/repository/.*"',
    application_key_id,
    application_key,
    local_path,
    bucket_name
  )

  print('Syncing secrets...')
  if os.execute(sync_cmd) then
    print('Secrets synchronized successfully')
    return true
  else
    print('Error: Failed to sync secrets')
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
