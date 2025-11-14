-- =============================================================================
-- Async Execution Utilities
-- =============================================================================

local M = {}

-- =============================================================================
-- Private Helper Functions
-- =============================================================================

--- Collect non-empty lines from job output
---@param data table Raw output data from job
---@param collector table Table to collect lines into
local function collect_output(data, collector)
  if not data then return end
  
  for _, line in ipairs(data) do
    if line and line ~= '' then
      table.insert(collector, line)
    end
  end
end

--- Create job configuration for async execution
---@param stdout_collector table Table to collect stdout
---@param stderr_collector table Table to collect stderr  
---@param callback function Callback to execute on completion
---@return table job_config Configuration for vim.fn.jobstart
local function create_job_config(stdout_collector, stderr_collector, callback)
  return {
    on_stdout = function(_, data)
      collect_output(data, stdout_collector)
    end,
    on_stderr = function(_, data)
      collect_output(data, stderr_collector)
    end,
    on_exit = function(_, exit_code)
      local stdout_result = table.concat(stdout_collector, '\n')
      local stderr_result = table.concat(stderr_collector, '\n')
      callback(exit_code == 0, stdout_result, stderr_result, exit_code)
    end,
  }
end

-- =============================================================================
-- Public API Functions
-- =============================================================================

--- Execute command asynchronously with comprehensive callback
---@param cmd string|table Command to execute
---@param callback function Called with (success, stdout, stderr, exit_code)
function M.execute(cmd, callback)
  if not cmd or not callback then
    error('Command and callback are required')
  end
  
  local stdout_data = {}
  local stderr_data = {}
  local job_config = create_job_config(stdout_data, stderr_data, callback)
  
  vim.fn.jobstart(cmd, job_config)
end

--- Execute curl command asynchronously with simplified callback
---@param cmd string|table Curl command to execute
---@param callback function Called with (success, result_or_error)
function M.execute_curl(cmd, callback)
  if not cmd or not callback then
    error('Command and callback are required')
  end
  
  M.execute(cmd, function(success, stdout, stderr, exit_code)
    if success then
      callback(true, stdout)
    else
      local error_msg = stderr ~= '' and stderr or ('Command failed with exit code: ' .. exit_code)
      callback(false, error_msg)
    end
  end)
end

return M
