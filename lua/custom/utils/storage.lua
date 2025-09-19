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

return M
