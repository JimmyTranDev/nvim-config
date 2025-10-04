local M = {}

local inputUtils = require('custom.utils.input')
local httpUtils = require('custom.utils.http')

-- Function to add convention to README with ChatGPT API integration
function M.addConventionToReadme()
  -- Get user input for the convention
  local conventionName = inputUtils.getInputFromUser('Enter convention name: ')
  if not conventionName or conventionName == '' then
    vim.notify('Convention name is required', vim.log.levels.WARN)
    return
  end

  local conventionDescription = inputUtils.getInputFromUser('Enter convention description: ')
  if not conventionDescription or conventionDescription == '' then
    vim.notify('Convention description is required', vim.log.levels.WARN)
    return
  end

  -- Prepare ChatGPT API request to generate an example
  local prompt = string.format(
    'Create a practical code example for this convention:\n\n'
      .. 'Convention Name: %s\n'
      .. 'Description: %s\n\n'
      .. 'Please provide a clear, concise code example that demonstrates this convention. '
      .. 'Include comments if necessary. Format it as a code block.',
    conventionName,
    conventionDescription
  )

  vim.notify('Generating example with ChatGPT...', vim.log.levels.INFO)

  -- Make API request to ChatGPT
  httpUtils.chatgpt_request(prompt, function(response)
    if response and response.content then
      local example = response.content

      -- Format the convention entry
      local conventionEntry = string.format('\n## %s\n\n%s\n\n### Example\n\n%s\n', conventionName, conventionDescription, example)

      -- Find README file
      local readmeFiles = { 'README.md', 'readme.md', 'Readme.md' }
      local readmePath = nil

      for _, filename in ipairs(readmeFiles) do
        local path = vim.fn.getcwd() .. '/' .. filename
        if vim.fn.filereadable(path) == 1 then
          readmePath = path
          break
        end
      end

      if not readmePath then
        -- Create README.md if it doesn't exist
        readmePath = vim.fn.getcwd() .. '/README.md'
        local initialContent = '# ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t') .. '\n\n'
        vim.fn.writefile(vim.split(initialContent, '\n'), readmePath)
      end

      -- Read current README content
      local currentContent = vim.fn.readfile(readmePath)
      local contentStr = table.concat(currentContent, '\n')

      -- Add convention section
      local newContent
      if contentStr:find('## Conventions') then
        -- Insert after existing Conventions section
        newContent = contentStr:gsub('(## Conventions.-)\n', '%1' .. conventionEntry .. '\n')
      else
        -- Add new Conventions section at the end
        newContent = contentStr .. '\n\n## Conventions' .. conventionEntry
      end

      -- Write back to file
      vim.fn.writefile(vim.split(newContent, '\n'), readmePath)

      vim.notify(string.format('Added convention "%s" to %s', conventionName, vim.fn.fnamemodify(readmePath, ':t')), vim.log.levels.INFO)

      -- Open the README file
      vim.cmd('edit ' .. readmePath)
    else
      vim.notify('Failed to generate example with ChatGPT', vim.log.levels.ERROR)
    end
  end)
end

return M
