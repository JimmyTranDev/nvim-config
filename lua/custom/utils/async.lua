local M = {}

local function collect_output(data, collector)
  if not data then return end

  for _, line in ipairs(data) do
    if line and line ~= '' then table.insert(collector, line) end
  end
end

local function create_job_config(stdout_collector, stderr_collector, callback)
  return {
    on_stdout = function(_, data) collect_output(data, stdout_collector) end,
    on_stderr = function(_, data) collect_output(data, stderr_collector) end,
    on_exit = function(_, exit_code)
      local stdout_result = table.concat(stdout_collector, '\n')
      local stderr_result = table.concat(stderr_collector, '\n')
      callback(exit_code == 0, stdout_result, stderr_result, exit_code)
    end,
  }
end

function M.execute(cmd, callback)
  if not cmd or not callback then error('Command and callback are required') end

  local stdout_data = {}
  local stderr_data = {}
  local job_config = create_job_config(stdout_data, stderr_data, callback)

  vim.fn.jobstart(cmd, job_config)
end

function M.execute_curl(cmd, callback)
  if not cmd or not callback then error('Command and callback are required') end

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
