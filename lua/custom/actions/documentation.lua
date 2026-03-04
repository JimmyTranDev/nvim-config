local input_utils = require('custom.utils.input')
local http_utils = require('custom.utils.http')
local ui_utils = require('custom.utils.ui')
local validation = require('custom.utils.validation')

local M = {}

local function get_convention_input()
  local convention_name = input_utils.get_input('Enter convention name: ')
  if not validation.is_non_empty_string(convention_name) then
    vim.notify('Convention name is required', vim.log.levels.WARN)
    return nil
  end

  local convention_description = input_utils.get_input('Enter convention description: ')
  if not validation.is_non_empty_string(convention_description) then
    vim.notify('Convention description is required', vim.log.levels.WARN)
    return nil
  end

  return {
    name = convention_name,
    description = convention_description,
  }
end

local function generate_convention_prompt(convention)
  return string.format(
    'Create a practical code example for this convention:\n\n'
      .. 'Convention Name: %s\n'
      .. 'Description: %s\n\n'
      .. 'Please provide a clear, concise code example that demonstrates this convention. '
      .. 'Include comments if necessary. Format it as a code block.',
    convention.name,
    convention.description
  )
end

local function find_or_create_readme()
  local readme_files = { 'README.md', 'readme.md', 'Readme.md' }
  local cwd = vim.fn.getcwd()

  for _, filename in ipairs(readme_files) do
    local path = cwd .. '/' .. filename
    if vim.fn.filereadable(path) == 1 then return path end
  end

  local readme_path = cwd .. '/README.md'
  local project_name = vim.fn.fnamemodify(cwd, ':t')
  local initial_content = '# ' .. project_name .. '\n\n'

  local ok, err = pcall(function() vim.fn.writefile(vim.split(initial_content, '\n'), readme_path) end)

  if not ok then
    vim.notify('Failed to create README file: ' .. tostring(err), vim.log.levels.ERROR)
    return nil
  end

  return readme_path
end

local function format_convention_entry(convention, example)
  return string.format('\n## %s\n\n%s\n\n### Example\n\n%s\n', convention.name, convention.description, example)
end

local function update_readme_content(readme_path, convention_entry)
  local ok, current_content = pcall(function() return vim.fn.readfile(readme_path) end)

  if not ok then
    vim.notify('Failed to read README file', vim.log.levels.ERROR)
    return false
  end

  local content_str = table.concat(current_content, '\n')
  local new_content

  if content_str:find('## Conventions') then
    new_content = content_str:gsub('(## Conventions.-)\n', '%1' .. convention_entry .. '\n')
  else
    new_content = content_str .. '\n\n## Conventions' .. convention_entry
  end

  local write_ok, write_err = pcall(function() vim.fn.writefile(vim.split(new_content, '\n'), readme_path) end)

  if not write_ok then
    vim.notify('Failed to write README file: ' .. tostring(write_err), vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.add_convention_to_readme()
  local convention = get_convention_input()
  if not convention then return end

  local readme_path = find_or_create_readme()
  if not readme_path then return end

  local prompt = generate_convention_prompt(convention)
  ui_utils.show_success('Generating example with ChatGPT...')

  http_utils.chatgpt_request(prompt, function(response)
    if not response or not response.content then
      vim.notify('Failed to generate example with ChatGPT', vim.log.levels.ERROR)
      return
    end

    local convention_entry = format_convention_entry(convention, response.content)

    if update_readme_content(readme_path, convention_entry) then
      local filename = vim.fn.fnamemodify(readme_path, ':t')
      ui_utils.show_success(string.format('Added convention "%s" to %s', convention.name, filename))

      vim.cmd('edit ' .. readme_path)
    end
  end)
end

return M
