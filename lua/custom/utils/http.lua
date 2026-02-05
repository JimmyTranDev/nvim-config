local M = {}

local CHATGPT_CONFIG = {
  url = 'https://api.openai.com/v1/chat/completions',
  model = 'gpt-3.5-turbo',
  max_tokens = 500,
  temperature = 0.7,
}

local function build_curl_command(url, headers, data)
  local cmd = { 'curl', '-s', '-X', 'POST', url }

  for key, value in pairs(headers or {}) do
    table.insert(cmd, '-H')
    table.insert(cmd, string.format('%s: %s', key, value))
  end

  if data then
    table.insert(cmd, '-d')
    table.insert(cmd, vim.fn.json_encode(data))
  end

  return cmd
end

function M.chatgpt_request(prompt, callback, options)
  if not prompt or not callback then error('Prompt and callback are required') end

  local api_key = vim.env.OPENAI_API_KEY
  if not api_key then
    vim.notify('OPENAI_API_KEY environment variable not set', vim.log.levels.ERROR)
    callback(nil)
    return
  end

  local config = vim.tbl_extend('force', CHATGPT_CONFIG, options or {})

  local headers = {
    ['Authorization'] = 'Bearer ' .. api_key,
    ['Content-Type'] = 'application/json',
  }

  local request_data = {
    model = config.model,
    messages = { { role = 'user', content = prompt } },
    max_tokens = config.max_tokens,
    temperature = config.temperature,
  }

  vim.schedule(function()
    local cmd = build_curl_command(config.url, headers, request_data)
    local result = vim.fn.systemlist(cmd)

    if vim.v.shell_error ~= 0 then
      vim.notify('ChatGPT API request failed', vim.log.levels.ERROR)
      callback(nil)
      return
    end

    local ok, response = pcall(vim.fn.json_decode, table.concat(result, '\n'))

    if ok and response and response.choices and response.choices[1] then
      callback({
        content = response.choices[1].message.content,
        usage = response.usage,
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
