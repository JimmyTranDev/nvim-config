local M = {}

local function execute_curl(method, url, headers, data)
  local cmd = { 'curl', '-s', '-X', method, url }

  if headers then
    for k, v in pairs(headers) do
      table.insert(cmd, '-H')
      table.insert(cmd, string.format('%s: %s', k, v))
    end
  end

  if data then
    table.insert(cmd, '-d')
    table.insert(cmd, vim.fn.json_encode(data))
  end

  local result = vim.fn.systemlist(table.concat(cmd, ' '))
  local response = table.concat(result, '\n')

  local ok, parsed = pcall(vim.fn.json_decode, response)
  if ok then
    return true, parsed
  else
    return false, response
  end
end

function M.get(url, headers, callback)
  vim.schedule(function()
    local success, response = execute_curl('GET', url, headers, nil)
    callback(success, response)
  end)
end

function M.post(url, data, headers, callback)
  headers = vim.tbl_extend('force', { ['Content-Type'] = 'application/json' }, headers or {})
  vim.schedule(function()
    local success, response = execute_curl('POST', url, headers, data)
    callback(success, response)
  end)
end

function M.patch(url, data, headers, callback)
  headers = vim.tbl_extend('force', { ['Content-Type'] = 'application/json' }, headers or {})
  vim.schedule(function()
    local success, response = execute_curl('PATCH', url, headers, data)
    callback(success, response)
  end)
end

function M.put(url, data, headers, callback)
  headers = vim.tbl_extend('force', { ['Content-Type'] = 'application/json' }, headers or {})
  vim.schedule(function()
    local success, response = execute_curl('PUT', url, headers, data)
    callback(success, response)
  end)
end

function M.delete(url, headers, callback)
  vim.schedule(function()
    local success, response = execute_curl('DELETE', url, headers, nil)
    callback(success, response)
  end)
end

-- ChatGPT API integration
function M.chatgpt_request(prompt, callback)
  local api_key = vim.env.OPENAI_API_KEY
  if not api_key then
    vim.notify('OPENAI_API_KEY environment variable not set', vim.log.levels.ERROR)
    callback(nil)
    return
  end
  
  local url = 'https://api.openai.com/v1/chat/completions'
  local headers = {
    ['Authorization'] = 'Bearer ' .. api_key,
    ['Content-Type'] = 'application/json'
  }
  
  local data = {
    model = 'gpt-3.5-turbo',
    messages = {
      {
        role = 'user',
        content = prompt
      }
    },
    max_tokens = 500,
    temperature = 0.7
  }
  
  M.post(url, data, headers, function(success, response)
    if success and response and response.choices and response.choices[1] then
      callback({
        content = response.choices[1].message.content
      })
    else
      local error_msg = 'ChatGPT API request failed'
      if response and response.error then
        error_msg = error_msg .. ': ' .. (response.error.message or 'Unknown error')
      end
      vim.notify(error_msg, vim.log.levels.ERROR)
      callback(nil)
    end
  end)
end

return M
