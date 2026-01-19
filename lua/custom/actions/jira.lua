local inputUtils = require('custom.utils.input')

local M = {}

local CONFIG = {
  CACHE_DIR = vim.fn.stdpath('data'),
  PARENT_ISSUE = 'BW-6111', -- Parent portfolio issue - update as needed for higher ticket numbers
  JIRA_BASE_URL = 'https://' .. os.getenv('ORG_NAME') .. '.atlassian.net/browse',
  DEFAULT_PROJECT = 'BW',
  LIMIT = 50,
}

local ISSUE_TYPES = {
  { name = 'Task', value = 'Task' },
  { name = 'Bug', value = 'Bug' },
  { name = 'Subtask', value = 'Subtask' },
  { name = 'Story', value = 'Story' },
  { name = 'Epic', value = 'Epic' },
}

local function save_to_file(filepath, content)
  local file = io.open(filepath, 'w')
  if file then
    file:write(content)
    file:close()
    return true
  end
  return false
end

local function load_from_file(filepath)
  local file = io.open(filepath, 'r')
  if file then
    local content = file:read('*all')
    file:close()
    return content and content:match('^%s*(.-)%s*$')
  end
  return nil
end

local cache_files = {
  last_parent = CONFIG.CACHE_DIR .. '/jira_last_parent.txt',
  parents = CONFIG.CACHE_DIR .. '/jira_parents_cache.txt',
}

local function save_last_parent(parent_key) save_to_file(cache_files.last_parent, parent_key) end

local function load_last_parent() return load_from_file(cache_files.last_parent) end

local function save_parents_cache(parents) save_to_file(cache_files.parents, vim.fn.json_encode(parents)) end

local function load_parents_cache()
  local content = load_from_file(cache_files.parents)
  if content then
    local success, parents = pcall(vim.fn.json_decode, content)
    if success and parents then return parents end
  end
  return nil
end

local function parse_csv_line(line)
  local fields = {}
  local field = ''
  local in_quotes = false
  local i = 1
  
  while i <= #line do
    local char = line:sub(i, i)
    
    if char == '"' then
      in_quotes = not in_quotes
    elseif char == ',' and not in_quotes then
      table.insert(fields, field:match('^%s*(.-)%s*$')) -- trim whitespace
      field = ''
    else
      field = field .. char
    end
    
    i = i + 1
  end
  
  -- Add the last field
  table.insert(fields, field:match('^%s*(.-)%s*$'))
  
  return fields
end

local function create_parent_entry(key, summary, status)
  return {
    key = key,
    summary = summary,
    status = status,
    display = string.format('%s - %s (%s)', key, summary, status),
  }
end

local function build_parent_options(parents)
  local last_parent = load_last_parent()
  local options = {}
  local last_used_option = nil

  for _, parent in ipairs(parents) do
    local option = { name = parent.display, value = parent.key }

    if last_parent and parent.key == last_parent then
      option.name = option.name .. ' (Last used)'
      last_used_option = option
    else
      table.insert(options, option)
    end
  end

  if last_used_option then table.insert(options, 1, last_used_option) end

  return options
end

local function add_back_option(options, text, value) table.insert(options, { name = '← ' .. text, value = value or '__back__' }) end

local function get_user_input(prompt, default)
  local input = inputUtils.getInputFromUser(prompt, default or '')
  if not input or input == '' then
    vim.notify('Task creation cancelled', vim.log.levels.INFO)
    return nil
  end
  return input
end

local function fetch_parent_issues(callback)
  local cached_parents = load_parents_cache()
  if cached_parents then
    vim.notify('Using cached parent issues', vim.log.levels.INFO)
    callback(cached_parents)
    return
  end

  local jql_query = string.format('issuekey in portfolioChildIssuesOf(%s) AND type = "Epic"', CONFIG.PARENT_ISSUE)
  local cmd = string.format('acli jira workitem search --jql "%s" --fields "key,summary,status" --limit %d --csv', jql_query, CONFIG.LIMIT)

  vim.notify('Fetching available parent issues...', vim.log.levels.INFO)

  vim.system(
    { 'sh', '-c', cmd },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        local error_msg = result.stderr ~= '' and result.stderr or result.stdout
        vim.notify('Failed to fetch parent issues: ' .. error_msg, vim.log.levels.ERROR)
        callback(nil)
        return
      end

      local parents = {}
      local lines = vim.split(result.stdout, '\n', { trimempty = true })

      for i = 2, #lines do
        local line = lines[i]
        if line:match('^[^,]*BW%-') then
          local fields = parse_csv_line(line)
          if #fields >= 3 then table.insert(parents, create_parent_entry(fields[1], fields[2], fields[3])) end
        end
      end

      if #parents > 0 then
        save_parents_cache(parents)
        callback(parents)
      else
        vim.notify(string.format('No parent issues found under %s', CONFIG.PARENT_ISSUE), vim.log.levels.WARN)
        callback(nil)
      end
    end)
  )
end

local function create_jira_task_workflow(summary, fallback_project, should_open_link)
  local project = get_user_input('Enter project key: ', fallback_project)
  if not project then return end

  local type_options = vim.tbl_deep_extend('force', {}, ISSUE_TYPES)
  add_back_option(type_options, 'Back to project')

  vim.ui.select(type_options, {
    prompt = 'Select work item type:',
    format_item = function(item) return item.name end,
  }, function(selected_type)
    if not selected_type then
      vim.notify('Task creation cancelled', vim.log.levels.INFO)
      return
    end

    if selected_type.value == '__back__' then return create_jira_task_workflow(summary, fallback_project, should_open_link) end

    fetch_parent_issues(function(parents)
      if not parents then
        vim.notify('Failed to fetch parent issues - task creation cancelled', vim.log.levels.ERROR)
        return
      end

      local parent_options = build_parent_options(parents)
      add_back_option(parent_options, 'Back to type')

      vim.ui.select(parent_options, {
        prompt = 'Select parent issue:',
        format_item = function(item) return item.name end,
      }, function(selected_parent)
        if not selected_parent then
          vim.notify('Task creation cancelled', vim.log.levels.INFO)
          return
        end

        if selected_parent.value == '__back__' then return create_jira_task_workflow(summary, fallback_project, should_open_link) end

        save_last_parent(selected_parent.value)

        local cmd = string.format(
          'acli jira workitem create --summary "%s" --project "%s" --type "%s" --parent "%s"',
          summary:gsub('"', '\\"'),
          project,
          selected_type.value,
          selected_parent.value
        )

        vim.notify('Creating Jira task...', vim.log.levels.INFO)

        vim.system(
          { 'sh', '-c', cmd },
          { text = true },
          vim.schedule_wrap(function(result)
            if result.code == 0 then
              local work_item_id = result.stdout:match('([A-Z]+-[0-9]+)')

              if work_item_id then
                vim.notify(string.format('Task %s created successfully', work_item_id), vim.log.levels.INFO)

                if should_open_link then
                  local jira_url = string.format('%s/%s', CONFIG.JIRA_BASE_URL, work_item_id)
                  vim.system({ 'open', jira_url })
                end
              else
                vim.notify(string.format("Jira task '%s' created in project '%s'", summary, project), vim.log.levels.INFO)
              end
            else
              local error_msg = result.stderr ~= '' and result.stderr or result.stdout
              vim.notify('Failed to create Jira task: ' .. error_msg, vim.log.levels.ERROR)

              vim.ui.select(
                { { name = 'Try again', value = 'retry' }, { name = 'Cancel', value = 'cancel' } },
                { prompt = 'Task creation failed. What would you like to do?' },
                function(choice)
                  if choice and choice.value == 'retry' then create_jira_task_workflow(summary, fallback_project, should_open_link) end
                end
              )
            end
          end)
        )
      end)
    end)
  end)
end

local function create_task_handler(should_open_link)
  return function(fallback_project)
    return function()
      local summary = get_user_input('Enter task summary: ')
      if summary then create_jira_task_workflow(summary, fallback_project or CONFIG.DEFAULT_PROJECT, should_open_link) end
    end
  end
end

M.create_jira_task = create_task_handler(false)
M.create_jira_task_with_link = create_task_handler(true)

return M
