local inputUtils = require('custom.utils.input')

local M = {}

local cache_file = vim.fn.stdpath('data') .. '/jira_last_parent.txt'

local function save_last_parent(parent_key)
  local file = io.open(cache_file, 'w')
  if file then
    file:write(parent_key)
    file:close()
  end
end

local function load_last_parent()
  local file = io.open(cache_file, 'r')
  if file then
    local content = file:read('*all')
    file:close()
    return content and content:match('^%s*(.-)%s*$')
  end
  return nil
end

local jiraTypeOptions = {
  { name = 'Task', value = 'Task' },
  { name = 'Bug', value = 'Bug' },
  { name = 'Subtask', value = 'Subtask' },
  { name = 'Story', value = 'Story' },
  { name = 'Epic', value = 'Epic' },
}

local function fetch_parent_issues(callback)
  local jql = 'issuekey in portfolioChildIssuesOf(BW-6111) AND type = "Epic"'
  local cmd = string.format('acli jira workitem search --jql "%s" --fields "key,summary,status" --limit 50 --csv', jql)

  vim.notify('Fetching available parent issues...', vim.log.levels.INFO)

  vim.system(
    { 'sh', '-c', cmd },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code == 0 then
        local parents = {}
        local lines = {}

        for line in result.stdout:gmatch('[^\r\n]+') do
          table.insert(lines, line)
        end

        for i = 2, #lines do
          local line = lines[i]
          if line and line:match('^[^,]*BW%-') then
            local key, summary, status = line:match('^([^,]+),([^,]+),(.+)')
            if key and summary and status then
              table.insert(parents, {
                key = key:gsub('"', ''),
                summary = summary:gsub('"', ''),
                status = status:gsub('"', ''),
                display = string.format('%s - %s (%s)', key:gsub('"', ''), summary:gsub('"', ''), status:gsub('"', '')),
              })
            end
          end
        end

        if #parents > 0 then
          callback(parents)
        else
          vim.notify('No parent issues found under BW-6111', vim.log.levels.WARN)
          callback(nil)
        end
      else
        local error_msg = result.stderr and result.stderr ~= '' and result.stderr or result.stdout
        vim.notify('Failed to fetch parent issues: ' .. error_msg, vim.log.levels.ERROR)
        callback(nil)
      end
    end)
  )
end

local function create_jira_task_with_navigation(summary, fallbackProject)
  local select_project, select_type, select_parent, create_task

  select_project = function()
    local default_project = fallbackProject or ''

    local project = inputUtils.getInputFromUser('Enter project key: ', default_project)
    if project == nil or project == '' then
      vim.notify('Task creation cancelled', vim.log.levels.INFO)
      return
    end

    select_type(project)
  end

  select_type = function(project)
    local type_options = {}
    for _, option in ipairs(jiraTypeOptions) do
      table.insert(type_options, option)
    end

    table.insert(type_options, { name = '← Back to project', value = '__back__' })

    vim.ui.select(type_options, {
      prompt = 'Select work item type:',
      format_item = function(item) return item.name end,
    }, function(selected_type)
      if selected_type == nil then
        vim.notify('Task creation cancelled', vim.log.levels.INFO)
        return
      end

      if selected_type.value == '__back__' then
        select_project()
        return
      end

      select_parent(project, selected_type.value)
    end)
  end

  select_parent = function(project, type)
    fetch_parent_issues(function(parents)
      if not parents then
        vim.notify('Failed to fetch parent issues - task creation cancelled', vim.log.levels.ERROR)
        return
      end

      local last_parent = load_last_parent()
      local parent_options = {}
      local default_index = 1

      for i, parent in ipairs(parents) do
        table.insert(parent_options, {
          name = parent.display,
          value = parent.key,
        })

        if last_parent and parent.key == last_parent then default_index = i end
      end

      table.insert(parent_options, { name = '← Back to type', value = '__back__' })

      if last_parent then
        for i, option in ipairs(parent_options) do
          if option.value == last_parent then
            option.name = option.name .. ' (Last used)'
            break
          end
        end
      end

      vim.ui.select(parent_options, {
        prompt = 'Select parent issue:',
        format_item = function(item) return item.name end,
      }, function(selected_parent)
        if selected_parent == nil then
          vim.notify('Task creation cancelled', vim.log.levels.INFO)
          return
        end

        if selected_parent.value == '__back__' then
          select_type(project)
          return
        end

        save_last_parent(selected_parent.value)
        create_task(project, type, selected_parent.value)
      end)
    end)
  end

  create_task = function(project, type, parent)
    local cmd =
      string.format('acli jira workitem create --summary "%s" --project "%s" --type "%s" --parent "%s"', summary:gsub('"', '\\"'), project, type, parent)

    vim.notify('Creating Jira task...', vim.log.levels.INFO)

    local function on_exit(result)
      if result.code == 0 then
        local work_item_id = result.stdout:match('([A-Z]+-[0-9]+)')

        if work_item_id then
          vim.notify(string.format('Task %s created successfully', work_item_id), vim.log.levels.INFO)

          local transition_cmd = string.format('acli jira workitem transition "%s" "In Progress Development"', work_item_id)

          vim.system(
            { 'sh', '-c', transition_cmd },
            { text = true },
            vim.schedule_wrap(function(transition_result)
              if transition_result.code == 0 then
                vim.notify(string.format('Task %s transitioned to Start Development', work_item_id), vim.log.levels.INFO)

                local jira_url = string.format('https://storebrand.atlassian.net/browse/%s', work_item_id)
                vim.system({ 'open', jira_url })
              else
                vim.notify(
                  string.format('Task %s created but failed to transition: %s', work_item_id, transition_result.stderr or transition_result.stdout),
                  vim.log.levels.WARN
                )

                local jira_url = string.format('https://storebrand.atlassian.net/browse/%s', work_item_id)
                vim.system({ 'open', jira_url })
              end
            end)
          )
        else
          vim.notify(string.format("Jira task '%s' created in project '%s'", summary, project), vim.log.levels.INFO)
        end
      else
        local error_msg = result.stderr and result.stderr ~= '' and result.stderr or result.stdout
        vim.notify('Failed to create Jira task: ' .. error_msg, vim.log.levels.ERROR)

        vim.ui.select(
          { { name = 'Try again', value = 'retry' }, { name = 'Cancel', value = 'cancel' } },
          { prompt = 'Task creation failed. What would you like to do?' },
          function(choice)
            if choice and choice.value == 'retry' then select_parent(project, type) end
          end
        )
      end
    end

    vim.system({ 'sh', '-c', cmd }, { text = true }, vim.schedule_wrap(on_exit))
  end

  select_project()
end

function M.create_jira_task(fallbackProject)
  return function()
    local summary = inputUtils.getInputFromUser('Enter task summary: ')
    if summary == nil or summary == '' then
      vim.notify('No task summary provided', vim.log.levels.WARN)
      return
    end

    create_jira_task_with_navigation(summary, fallbackProject or 'BW')
  end
end

return M
