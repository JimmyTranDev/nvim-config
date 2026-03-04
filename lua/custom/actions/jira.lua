local inputUtils = require('custom.utils.input')
local git_utils = require('custom.utils.git')

local M = {}

local CONFIG = {
  CACHE_DIR = vim.fn.stdpath('data'),
  PARENT_ISSUE = 'BW-6111',
  JIRA_BASE_URL = 'https://' .. (os.getenv('ORG_NAME') or 'unknown') .. '.atlassian.net/browse',
  DEFAULT_PROJECT = 'BW',
  LIMIT = 50,
  AUTO_TRANSITION_TO_DONE = true,
  TRANSITION_STATUSES = { 'In Progress Concept', 'Done Concept' },
  EXCLUDED_EPIC_STATUSES = { 'Received', 'Closed' },
}

local ISSUE_TYPES = {
  { name = 'Task', value = 'Task' },
  { name = 'Bug', value = 'Bug' },
  { name = 'Subtask', value = 'Subtask' },
  { name = 'Story', value = 'Story' },
  { name = 'Epic', value = 'Epic' },
}

local LABELS = {
  { name = 'None', value = nil },
  { name = 'Frontend', value = 'Frontend' },
  { name = 'Backend', value = 'Backend' },
}

local cache_files = {
  last_parent = CONFIG.CACHE_DIR .. '/jira_last_parent.txt',
  parents = CONFIG.CACHE_DIR .. '/jira_parents_cache.txt',
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

local function build_status_exclusion_jql()
  local exclusions = {}
  for _, status in ipairs(CONFIG.EXCLUDED_EPIC_STATUSES) do
    table.insert(exclusions, 'status != "' .. status .. '"')
  end
  return table.concat(exclusions, ' AND ')
end

local function get_current_user_email()
  local email = os.getenv('ORG_EMAIL')
  return email and email:match('^%s*(.-)%s*$')
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
      table.insert(fields, field:match('^%s*(.-)%s*$'))
      field = ''
    else
      field = field .. char
    end
    i = i + 1
  end

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

local function add_back_option(options, text, value)
  table.insert(options, { name = '← ' .. text, value = value or '__back__' })
end

local function get_user_input(prompt, callback, default)
  inputUtils.get_input(prompt, function(input)
    if not input then
      vim.notify('Task creation cancelled', vim.log.levels.INFO)
      return
    end
    callback(input)
  end, default or '')
end

local function fetch_parent_issues(callback, force_refresh)
  if not force_refresh then
    local cached_parents = load_parents_cache()
    if cached_parents then
      vim.notify('Using cached parent issues', vim.log.levels.INFO)
      callback(cached_parents)
      return
    end
  end

  local status_exclusion = build_status_exclusion_jql()
  local jql_query = 'project = "'
    .. CONFIG.DEFAULT_PROJECT
    .. '" AND (issuekey in portfolioChildIssuesOf(BW-6111) OR issuekey in portfolioChildIssuesOf(BW-6716) OR issuekey in portfolioChildIssuesOf(BW-7069) OR issuekey in portfolioChildIssuesOf(BW-7217) OR issuekey in portfolioChildIssuesOf(BW-7890) OR issuekey in portfolioChildIssuesOf(BW-9748)) AND issuetype in (Initiative, Epic) AND '
    .. status_exclusion
    .. ' ORDER BY parent'
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
          if #fields >= 3 then table.insert(parents, create_parent_entry(fields[1], fields[3], fields[2])) end
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
  local select_project, select_type, select_label, select_parent

  select_project = function()
    get_user_input('Enter project key: ', function(project)
      select_type(project)
    end, fallback_project)
  end

  select_type = function(project)
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

      if selected_type.value == '__back__' then
        select_project()
        return
      end

      select_label(project, selected_type)
    end)
  end

  select_label = function(project, selected_type)
    local label_options = vim.tbl_deep_extend('force', {}, LABELS)
    add_back_option(label_options, 'Back to type')

    vim.ui.select(label_options, {
      prompt = 'Select label:',
      format_item = function(item) return item.name end,
    }, function(selected_label)
      if not selected_label then
        vim.notify('Task creation cancelled', vim.log.levels.INFO)
        return
      end

      if selected_label.value == '__back__' then
        select_type(project)
        return
      end

      select_parent(project, selected_type, selected_label)
    end)
  end

  select_parent = function(project, selected_type, selected_label)
    fetch_parent_issues(function(parents)
      if not parents then
        vim.notify('Failed to fetch parent issues - task creation cancelled', vim.log.levels.ERROR)
        return
      end

      local parent_options = build_parent_options(parents)
      add_back_option(parent_options, 'Back to label')

      vim.ui.select(parent_options, {
        prompt = 'Select parent issue:',
        format_item = function(item) return item.name end,
      }, function(selected_parent)
        if not selected_parent then
          vim.notify('Task creation cancelled', vim.log.levels.INFO)
          return
        end

        if selected_parent.value == '__back__' then
          select_label(project, selected_type)
          return
        end

        save_last_parent(selected_parent.value)

        local assignee_email = get_current_user_email()
        local assignee_flag = assignee_email and string.format(' --assignee "%s"', assignee_email) or ''
        local label_flag = selected_label.value and string.format(' --label "%s"', selected_label.value) or ''

        local cmd = string.format(
          'acli jira workitem create --summary "%s" --project "%s" --type "%s" --parent "%s"%s%s',
          summary:gsub('"', '\\"'),
          project,
          selected_type.value,
          selected_parent.value,
          assignee_flag,
          label_flag
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

                if CONFIG.AUTO_TRANSITION_TO_DONE then
                  local function run_transitions(statuses, index, on_complete)
                    if index > #statuses then
                      on_complete()
                      return
                    end

                    local status = statuses[index]
                    local transition_cmd = string.format('acli jira workitem transition --key "%s" --status "%s" --yes', work_item_id, status)

                    vim.system(
                      { 'sh', '-c', transition_cmd },
                      { text = true },
                      vim.schedule_wrap(function(transition_result)
                        if transition_result.code == 0 then
                          vim.notify(string.format('Task %s transitioned to %s', work_item_id, status), vim.log.levels.INFO)
                          run_transitions(statuses, index + 1, on_complete)
                        else
                          local transition_error = transition_result.stderr ~= '' and transition_result.stderr or transition_result.stdout
                          vim.notify(string.format('Task %s failed to transition to %s: %s', work_item_id, status, transition_error), vim.log.levels.WARN)
                          on_complete()
                        end
                      end)
                    )
                  end

                  run_transitions(CONFIG.TRANSITION_STATUSES, 1, function()
                    if should_open_link then
                      vim.system({ 'open', string.format('%s/%s', CONFIG.JIRA_BASE_URL, work_item_id) })
                    end
                  end)
                else
                  if should_open_link then
                    vim.system({ 'open', string.format('%s/%s', CONFIG.JIRA_BASE_URL, work_item_id) })
                  end
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
                  if choice and choice.value == 'retry' then select_project() end
                end
              )
            end
          end)
        )
      end)
    end)
  end

  select_project()
end

local function create_task_handler(should_open_link)
  return function(fallback_project)
    return function()
      get_user_input('Enter task summary: ', function(summary)
        create_jira_task_workflow(summary, fallback_project or CONFIG.DEFAULT_PROJECT, should_open_link)
      end)
    end
  end
end

M.create_jira_task = create_task_handler(false)
M.create_jira_task_with_link = create_task_handler(true)

M.refresh_jira_cache = function()
  local file = io.open(cache_files.parents, 'w')
  if file then
    file:close()
    vim.notify('Jira parent cache refreshed. Next task creation will fetch fresh data.', vim.log.levels.INFO)
  else
    vim.notify('Failed to clear Jira parent issues cache', vim.log.levels.ERROR)
  end
end

M.generate_done_md = function()
  local assignee_email = get_current_user_email()
  if not assignee_email then
    vim.notify('ORG_EMAIL environment variable not set', vim.log.levels.ERROR)
    return
  end

  local escaped_email = assignee_email:gsub('@', '\\u0040')
  local jql_query = string.format(
    "assignee was '%s' AND status changed to 'In Progress Development' AFTER -7d ORDER BY updated DESC",
    escaped_email
  )

  local cmd = string.format(
    "acli jira workitem search --jql \"%s\" --fields 'key,summary,status' --limit 100 --csv",
    jql_query
  )

  vim.notify('Fetching completed tasks...', vim.log.levels.INFO)

  vim.system(
    { 'sh', '-c', cmd },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        local error_msg = result.stderr ~= '' and result.stderr or result.stdout
        vim.notify('Failed to fetch tasks: ' .. error_msg, vim.log.levels.ERROR)
        return
      end

      local lines = vim.split(result.stdout, '\n', { trimempty = true })
      if #lines <= 1 then
        vim.notify('No completed tasks found', vim.log.levels.WARN)
        return
      end

      local md_lines = { '# Done Tasks', '', '| Ticket | Summary | Status |', '|--------|---------|--------|' }

      for i = 2, #lines do
        local fields = parse_csv_line(lines[i])
        if #fields >= 3 then
          local key = fields[1]
          local status = fields[2]
          local summary = fields[3]:gsub('|', '\\|')
          local ticket_link = string.format('[%s](%s/%s)', key, CONFIG.JIRA_BASE_URL, key)
          table.insert(md_lines, string.format('| %s | %s | %s |', ticket_link, summary, status))
        end
      end

      local root_dir = vim.fn.getcwd()
      local done_file = root_dir .. '/DONE.md'
      local content = table.concat(md_lines, '\n')

      local file = io.open(done_file, 'w')
      if file then
        file:write(content)
        file:close()
        vim.notify(string.format('Generated %s with %d tasks', done_file, #lines - 1), vim.log.levels.INFO)
      else
        vim.notify('Failed to write DONE.md', vim.log.levels.ERROR)
      end
    end)
  )
end

M.copy_ticket_with_title = function()
  local branch_name = git_utils.get_current_branch()
  if not branch_name or branch_name == '' then
    vim.notify('Not in a git repository or no branch found', vim.log.levels.WARN)
    return
  end

  local jira_ticket = git_utils.extract_jira_ticket(branch_name)
  if not jira_ticket or jira_ticket == '' then
    vim.notify('No JIRA ticket found in branch name: ' .. branch_name, vim.log.levels.WARN)
    return
  end

  local cmd = string.format("acli jira workitem view --key '%s' --fields 'summary' --csv", jira_ticket)

  vim.notify('Fetching ticket title...', vim.log.levels.INFO)

  vim.system(
    { 'sh', '-c', cmd },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        local error_msg = result.stderr ~= '' and result.stderr or result.stdout
        vim.notify('Failed to fetch ticket: ' .. error_msg, vim.log.levels.ERROR)
        return
      end

      local lines = vim.split(result.stdout, '\n', { trimempty = true })
      if #lines < 2 then
        vim.notify('No ticket data found', vim.log.levels.WARN)
        return
      end

      local fields = parse_csv_line(lines[2])
      local summary = fields[1] or ''
      local ticket_with_title = string.format('%s: %s', jira_ticket, summary)

      vim.fn.setreg('+', ticket_with_title)
      vim.notify('Copied: ' .. ticket_with_title, vim.log.levels.INFO)
    end)
  )
end

local COPY_FORMATS = {
  { name = 'Test', value = 'test' },
  { name = 'QUA', value = 'qua' },
}

local function fetch_assigned_issues(callback)
  local assignee_email = get_current_user_email()
  if not assignee_email then
    vim.notify('ORG_EMAIL environment variable not set', vim.log.levels.ERROR)
    return
  end

  local escaped_email = assignee_email:gsub('@', '\\u0040')
  local jql_query = string.format(
    "assignee = '%s' AND status NOT IN ('Done', 'Closed', 'Cancelled') ORDER BY updated DESC",
    escaped_email
  )

  local cmd = string.format(
    "acli jira workitem search --jql \"%s\" --fields 'key,summary,status' --limit 100 --csv",
    jql_query
  )

  vim.notify('Fetching assigned issues...', vim.log.levels.INFO)

  vim.system(
    { 'sh', '-c', cmd },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        local error_msg = result.stderr ~= '' and result.stderr or result.stdout
        vim.notify('Failed to fetch issues: ' .. error_msg, vim.log.levels.ERROR)
        callback(nil)
        return
      end

      local lines = vim.split(result.stdout, '\n', { trimempty = true })
      if #lines <= 1 then
        vim.notify('No assigned issues found', vim.log.levels.WARN)
        callback(nil)
        return
      end

      local issues = {}
      for i = 2, #lines do
        local fields = parse_csv_line(lines[i])
        if #fields >= 3 then
          table.insert(issues, {
            key = fields[1],
            status = fields[2],
            summary = fields[3],
            display = string.format('%s - %s (%s)', fields[1], fields[3], fields[2]),
          })
        end
      end

      callback(issues)
    end)
  )
end

local function format_issues_for_copy(issues, format_type)
  local formatted_lines = {}
  for _, issue in ipairs(issues) do
    local line
    if format_type == 'test' then
      line = string.format('test %s: %s', issue.key, issue.summary)
    else
      line = string.format('qua %s: %s', issue.key, issue.summary)
    end
    table.insert(formatted_lines, line)
  end
  return table.concat(formatted_lines, '\n')
end

M.copy_assigned_issues_for_testing = function()
  fetch_assigned_issues(function(issues)
    if not issues or #issues == 0 then return end

    local picker_items = {}
    for _, issue in ipairs(issues) do
      table.insert(picker_items, {
        text = issue.display,
        issue = issue,
      })
    end

    require('snacks').picker({
      title = 'Select Issues to Copy',
      items = picker_items,
      format = function(item) return { { item.text, 'Normal' } } end,
      multi = true,
      confirm = function(picker)
        local selected_items = picker:selected({ fallback = true })
        picker:close()

        if not selected_items or #selected_items == 0 then
          vim.notify('No issues selected', vim.log.levels.INFO)
          return
        end

        local selected_issues = {}
        for _, item in ipairs(selected_items) do
          table.insert(selected_issues, item.issue)
        end

        vim.ui.select(COPY_FORMATS, {
          prompt = 'Select format:',
          format_item = function(item) return item.name end,
        }, function(selected_format)
          if not selected_format then
            vim.notify('Cancelled', vim.log.levels.INFO)
            return
          end

          local formatted = format_issues_for_copy(selected_issues, selected_format.value)
          vim.fn.setreg('+', formatted)
          vim.notify(string.format('Copied %d issue(s) as %s format', #selected_issues, selected_format.name), vim.log.levels.INFO)
        end)
      end,
      layout = { preset = 'default', preview = false },
    })
  end)
end

return M
