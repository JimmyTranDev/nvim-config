local todoistUtils = require('custom.utils.todoist')

local M = {}

local PRIORITY_OPTIONS = {
  { name = 'Priority Top', value = 'p1' },
  { name = 'Priority None', value = 'p4' },
}

local RECENT_PROJECTS_FILE = vim.fn.stdpath('data') .. '/todoist_recent_projects.json'
local MAX_RECENT_PROJECTS = 10

local function get_user_input(prompt, callback)
  vim.ui.input({ prompt = prompt }, function(input)
    if not input or input == '' then
      vim.notify('Task creation cancelled', vim.log.levels.INFO)
      return
    end
    callback(input)
  end)
end

local function add_back_option(options, text)
  table.insert(options, { name = '← ' .. text, is_back = true })
end

local function get_recent_projects()
  local f = io.open(RECENT_PROJECTS_FILE, 'r')
  if f then
    local content = f:read('*a')
    f:close()
    local success, data = pcall(vim.fn.json_decode, content)
    if success and type(data) == 'table' and data.recent_projects then
      return data.recent_projects
    end
  end
  return {}
end

local function save_recent_projects(recent_projects)
  local f = io.open(RECENT_PROJECTS_FILE, 'w')
  if not f then
    vim.notify('Failed to save recent projects', vim.log.levels.WARN)
    return
  end
  f:write(vim.fn.json_encode({ recent_projects = recent_projects }))
  f:close()
end

local function add_recent_project_id(id)
  local recent_projects = get_recent_projects()

  for i, project_id in ipairs(recent_projects) do
    if project_id == id then
      table.remove(recent_projects, i)
      break
    end
  end

  table.insert(recent_projects, 1, id)

  while #recent_projects > MAX_RECENT_PROJECTS do
    table.remove(recent_projects, #recent_projects)
  end

  save_recent_projects(recent_projects)
end

local function build_project_priority_map()
  local recent_projects = get_recent_projects()
  local map = {}
  for i, project_id in ipairs(recent_projects) do
    map[project_id] = i - 1
  end
  return map
end

local function create_task_with_navigation(taskName, projects)
  local select_project, select_section, select_priority

  select_project = function()
    local priority_map = build_project_priority_map()

    table.sort(projects, function(a, b)
      local a_priority = priority_map[a.id] or 999
      local b_priority = priority_map[b.id] or 999

      if a_priority ~= b_priority then return a_priority < b_priority end
      if a.child_order ~= b.child_order then return a.child_order < b.child_order end
      if a.view_order ~= b.view_order then return a.view_order < b.view_order end
      return a.name < b.name
    end)

    local project_options = {}
    for _, project in ipairs(projects) do
      table.insert(project_options, {
        name = project.name .. ' (' .. (project.color or 'grey') .. ')',
        id = project.id,
        project = project,
      })
    end

    vim.ui.select(project_options, {
      prompt = 'Select a project:',
      format_item = function(item) return item.name end,
    }, function(selected_project)
      if not selected_project then
        vim.notify('Task creation cancelled', vim.log.levels.INFO)
        return
      end
      add_recent_project_id(selected_project.id)
      select_section(selected_project)
    end)
  end

  select_section = function(selected_project)
    todoistUtils.get_sections(selected_project.id, function(sections_success, sections)
      if not sections_success then
        vim.notify('Failed to fetch sections: ' .. sections, vim.log.levels.ERROR)
        return
      end

      local section_options = {}
      table.insert(section_options, { name = 'No section', id = nil })
      for _, section in ipairs(sections) do
        table.insert(section_options, { name = section.name, id = section.id })
      end
      add_back_option(section_options, 'Back to projects')

      vim.ui.select(section_options, {
        prompt = 'Select a section:',
        format_item = function(item) return item.name end,
      }, function(selected_section)
        if not selected_section then
          vim.notify('Task creation cancelled', vim.log.levels.INFO)
          return
        end

        if selected_section.is_back then
          select_project()
          return
        end

        select_priority(selected_project, selected_section)
      end)
    end)
  end

  select_priority = function(selected_project, selected_section)
    local priority_options = vim.list_extend({}, PRIORITY_OPTIONS)
    add_back_option(priority_options, 'Back to sections')

    vim.ui.select(priority_options, {
      prompt = 'Select a priority for the task:',
      format_item = function(item) return item.name end,
    }, function(selected_priority)
      if not selected_priority then
        vim.notify('Task creation cancelled', vim.log.levels.INFO)
        return
      end

      if selected_priority.is_back then
        select_section(selected_project)
        return
      end

      todoistUtils.create_task_with_project(
        taskName,
        selected_project.id,
        selected_section.id,
        selected_priority.value,
        '',
        function(task_success, response)
          if task_success then
            vim.notify(
              string.format(
                "Task '%s' created in project '%s'%s",
                taskName,
                selected_project.project.name,
                selected_section.id and (' > ' .. selected_section.name) or ''
              ),
              vim.log.levels.INFO
            )
          else
            vim.notify('Failed to create task: ' .. response, vim.log.levels.ERROR)
          end
        end
      )
    end)
  end

  select_project()
end

local function log_task_with_fetcher(fetch_projects, empty_message)
  return function()
    get_user_input('Enter task summary: ', function(taskName)
      fetch_projects(function(success, projects)
        if not success then
          vim.notify('Failed to fetch projects: ' .. projects, vim.log.levels.ERROR)
          return
        end
        if #projects == 0 then
          vim.notify(empty_message, vim.log.levels.WARN)
          return
        end

        create_task_with_navigation(taskName, projects)
      end)
    end)
  end
end

function M.log_todoist_task()
  return log_task_with_fetcher(todoistUtils.get_salmon_projects, 'No salmon projects found')
end

function M.log_todoist_task_all_projects()
  return log_task_with_fetcher(todoistUtils.get_projects, 'No projects found')
end

function M.refresh_todoist_cache()
  return function()
    todoistUtils.clear_cache()
    vim.notify('Todoist cache cleared. Next API call will fetch fresh data.', vim.log.levels.INFO)
  end
end

return M
