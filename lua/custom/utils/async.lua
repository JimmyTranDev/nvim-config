local M = {}

-- Execute curl command asynchronously
function M.execute_curl_async(cmd, callback)
  local stdout_data = {}
  local stderr_data = {}

  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line and line ~= '' then table.insert(stdout_data, line) end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line and line ~= '' then table.insert(stderr_data, line) end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        local result = table.concat(stdout_data, '\n')
        callback(true, result)
      else
        local error_msg = table.concat(stderr_data, '\n')
        if error_msg == '' then error_msg = 'Command failed with exit code: ' .. exit_code end
        callback(false, error_msg)
      end
    end,
  })
end

-- Execute command asynchronously
function M.execute_async(cmd, callback)
  local stdout_data = {}
  local stderr_data = {}

  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line and line ~= '' then table.insert(stdout_data, line) end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line and line ~= '' then table.insert(stderr_data, line) end
        end
      end
    end,
    on_exit = function(_, exit_code)
      local result = table.concat(stdout_data, '\n')
      local error_msg = table.concat(stderr_data, '\n')
      callback(exit_code == 0, result, error_msg, exit_code)
    end,
  })
end

return M
