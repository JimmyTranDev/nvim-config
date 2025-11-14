-- =============================================================================
-- HTTP Client Utilities
-- =============================================================================

local M = {}

-- =============================================================================
-- Private Helper Functions
-- =============================================================================

--- Build curl command for HTTP requests
---@param method string HTTP method (GET, POST, etc.)
---@param url string Request URL
---@param headers? table Optional headers
---@param data? table Optional request body data
---@return table cmd Curl command as table
local function build_curl_command(method, url, headers, data)
  local cmd = { 'curl', '-s', '-X', method, url }

  -- Add headers
  if headers then
    for key, value in pairs(headers) do
      table.insert(cmd, '-H')
      table.insert(cmd, string.format('%s: %s', key, value))
    end
  end

  -- Add JSON data
  if data then
    table.insert(cmd, '-d')
    table.insert(cmd, vim.fn.json_encode(data))
  end

  return cmd
end

--- Execute curl command synchronously
---@param method string HTTP method
---@param url string Request URL  
---@param headers? table Optional headers
---@param data? table Optional request body
---@return boolean success, any response_or_error
local function execute_curl_sync(method, url, headers, data)
  if not method or not url then
    return false, 'Method and URL are required'
  end
  
  local cmd = build_curl_command(method, url, headers, data)
  local result = vim.fn.systemlist(cmd)
  
  if vim.v.shell_error ~= 0 then
    return false, 'HTTP request failed with exit code: ' .. vim.v.shell_error
  end
  
  local response_text = table.concat(result, '\n')
  
  -- Try to parse as JSON
  local ok, parsed_response = pcall(vim.fn.json_decode, response_text)
  if ok then
    return true, parsed_response
  else
    return true, response_text  -- Return raw text if not valid JSON
  end
end

--- Execute HTTP request asynchronously
---@param method string HTTP method
---@param url string Request URL
---@param headers? table Optional headers
---@param data? table Optional request body
---@param callback function Callback function (success, response)
local function execute_http_async(method, url, headers, data, callback)
  if not callback then
    error('Callback function is required')
  end
  
  vim.schedule(function()
    local success, response = execute_curl_sync(method, url, headers, data)
    callback(success, response)
  end)
end

--- Merge default JSON headers with provided headers
---@param provided_headers? table User-provided headers
---@return table merged_headers Headers with JSON content-type default
local function merge_json_headers(provided_headers)
  local default_headers = { ['Content-Type'] = 'application/json' }
  return vim.tbl_extend('force', default_headers, provided_headers or {})
end

-- =============================================================================
-- Public HTTP Methods
-- =============================================================================

--- Perform GET request
---@param url string Request URL
---@param headers? table Optional headers
---@param callback function Callback (success, response)
function M.get(url, headers, callback)
  execute_http_async('GET', url, headers, nil, callback)
end

--- Perform POST request
---@param url string Request URL
---@param data? table Request body data
---@param headers? table Optional headers
---@param callback function Callback (success, response)
function M.post(url, data, headers, callback)
  local merged_headers = merge_json_headers(headers)
  execute_http_async('POST', url, merged_headers, data, callback)
end

--- Perform PATCH request
---@param url string Request URL
---@param data? table Request body data
---@param headers? table Optional headers
---@param callback function Callback (success, response)
function M.patch(url, data, headers, callback)
  local merged_headers = merge_json_headers(headers)
  execute_http_async('PATCH', url, merged_headers, data, callback)
end

--- Perform PUT request
---@param url string Request URL
---@param data? table Request body data
---@param headers? table Optional headers
---@param callback function Callback (success, response)
function M.put(url, data, headers, callback)
  local merged_headers = merge_json_headers(headers)
  execute_http_async('PUT', url, merged_headers, data, callback)
end

--- Perform DELETE request
---@param url string Request URL
---@param headers? table Optional headers
---@param callback function Callback (success, response)
function M.delete(url, headers, callback)
  execute_http_async('DELETE', url, headers, nil, callback)
end

-- =============================================================================
-- External API Integrations
-- =============================================================================

--- OpenAI ChatGPT API configuration
local CHATGPT_CONFIG = {
  url = 'https://api.openai.com/v1/chat/completions',
  model = 'gpt-3.5-turbo',
  max_tokens = 500,
  temperature = 0.7
}

--- Make request to ChatGPT API
---@param prompt string User prompt
---@param callback function Callback (response_or_nil)
---@param options? table Optional configuration overrides
function M.chatgpt_request(prompt, callback, options)
  if not prompt or not callback then
    error('Prompt and callback are required')
  end
  
  local api_key = vim.env.OPENAI_API_KEY
  if not api_key then
    vim.notify('OPENAI_API_KEY environment variable not set', vim.log.levels.ERROR)
    callback(nil)
    return
  end
  
  local config = vim.tbl_extend('force', CHATGPT_CONFIG, options or {})
  
  local headers = {
    ['Authorization'] = 'Bearer ' .. api_key,
    ['Content-Type'] = 'application/json'
  }
  
  local request_data = {
    model = config.model,
    messages = {
      {
        role = 'user',
        content = prompt
      }
    },
    max_tokens = config.max_tokens,
    temperature = config.temperature
  }
  
  M.post(config.url, request_data, headers, function(success, response)
    if success and response and response.choices and response.choices[1] then
      callback({
        content = response.choices[1].message.content,
        usage = response.usage
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
