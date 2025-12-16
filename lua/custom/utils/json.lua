local M = {}

-- Track notifications to avoid duplicates during the same session
local notified_secrets_missing = false
local missing_files = {}

function M.parse_json_from_file(file_path)
  local file, err = io.open(file_path, 'r')
  if not file then
    -- Check if it's a secrets directory issue and try to help
    if string.match(file_path, 'Programming/secrets') then
      local secrets_path = os.getenv('HOME') .. '/Programming/secrets'
      local stat = vim.loop.fs_stat(secrets_path)
      local secrets_dir_exists = stat and stat.type == 'directory'
      
      if not secrets_dir_exists then
        if not notified_secrets_missing then
          vim.notify('Secrets directory does not exist. Run: storage-init', vim.log.levels.INFO)
          notified_secrets_missing = true
        end
        -- Don't spam with individual file notifications if directory doesn't exist
        return {}
      else
        -- Directory exists but individual file is missing
        local filename = vim.fn.fnamemodify(file_path, ':t')
        if not missing_files[filename] then
          vim.notify('Missing secrets file: ' .. filename .. '. Run: storage-init', vim.log.levels.WARN)
          missing_files[filename] = true
        end
      end
    else
      -- Non-secrets file, show normal error
      vim.notify('Failed to open file: ' .. file_path .. ' (' .. (err or 'unknown error') .. ')', vim.log.levels.WARN)
    end
    return {}
  end

  local json_string = file:read('*a')
  file:close()

  local ok, result = pcall(vim.fn.json_decode, json_string)
  if ok then
    return result
  else
    vim.notify('Failed to parse JSON from ' .. file_path .. ': ' .. result, vim.log.levels.ERROR)
    return {}
  end
end

-- Reset notification flags (useful after initializing secrets directory)
function M.reset_notification_flags()
  notified_secrets_missing = false
  missing_files = {}
end

return M
