local M = {}

function M.execute(cmd, callback)
  if not cmd or not callback then error('Command and callback are required') end

  local stdout, stderr = {}, {}
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then table.insert(stdout, line) end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then table.insert(stderr, line) end
        end
      end
    end,
    on_exit = function(_, code)
      callback(code == 0, table.concat(stdout, '\n'), table.concat(stderr, '\n'), code)
    end,
  })
end

function M.execute_curl(cmd, callback)
  if not cmd or not callback then error('Command and callback are required') end
  M.execute(cmd, function(success, stdout, stderr, code)
    if success then
      callback(true, stdout)
    else
      callback(false, stderr ~= '' and stderr or ('Command failed with exit code: ' .. code))
    end
  end)
end

return M
