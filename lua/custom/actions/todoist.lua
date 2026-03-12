local todoist_utils = require('custom.utils.todoist')
local json_utils = require('custom.utils.json')
local ui_utils = require('custom.utils.ui')

local M = {}

local PRIORITY_OPTIONS = {
  { name = 'Priority Top', value = 'p1' },
  { name = 'Priority None', value = 'p4' },
}

local RECENT_PROJECTS_FILE = vim.fn.stdpath('data') .. '/todoist_recent_projects.json'
local MAX_RECENT_PROJECTS = 10

local format_by_name = function(item) return item.name end

local function add_back_option(options, text)
  table.insert(options, { name = '← ' .. text, is_back = true })
end

local function get_recent_projects()
  if not vim.uv.fs_stat(RECENT_PROJECTS_FILE) then return {} end
  local data = json_utils.parse_json_from_file(RECENT_PROJECTS_FILE)
  if type(data) == 'table' and data.recent_projects then return data.recent_projects end
  return {}
end

local function save_recent_projects(recent_projects)
  json_utils.write_json_to_file(RECENT_PROJECTS_FILE, { recent_projects = recent_projects })
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

local function create_task_with_navigation(task_name, projects)
  local select_project, select_section, select_priority

  select_project = function()
    local priority_map = build_project_priority_map()

    table.sort(projects, function(a, b)
      local a_priority = priority_map[a.id] or 999
      local b_priority = priority_map[b.id] or 999

      if a_priority ~= b_priority then return a_priority < b_priority end
      if a.child_order ~= b.child_order then return a.child_order < b.child_order end
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

    ui_utils.safe_select(project_options, {
      prompt = 'Select a project:',
      format_item = format_by_name,
    }, function(selected_project)
      add_recent_project_id(selected_project.id)
      select_section(selected_project)
    end)
  end

  select_section = function(selected_project)
    todoist_utils.get_sections(selected_project.id, function(sections_success, sections)
      if not sections_success then
        vim.notify('Failed to fetch sections: ' .. sections, vim.log.levels.ERROR)
        return
      end

      if #sections == 0 then
        select_priority(selected_project, { name = 'No section', id = nil })
        return
      end

      local section_options = {}
      for _, section in ipairs(sections) do
        table.insert(section_options, { name = section.name, id = section.id })
      end
      table.insert(section_options, { name = 'No section', id = nil })
      add_back_option(section_options, 'Back to projects')

      ui_utils.safe_select(section_options, {
        prompt = 'Select a section:',
        format_item = format_by_name,
      }, function(selected_section)
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

    ui_utils.safe_select(priority_options, {
      prompt = 'Select a priority for the task:',
      format_item = format_by_name,
    }, function(selected_priority)
      if selected_priority.is_back then
        select_section(selected_project)
        return
      end

      todoist_utils.create_task(
        task_name,
        selected_project.id,
        selected_section.id,
        selected_priority.value,
        function(task_success, response)
          if task_success then
            vim.notify(
              string.format(
                "Task '%s' created in project '%s'%s",
                task_name,
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
    ui_utils.safe_input({ prompt = 'Enter task summary: ' }, function(task_name)
      fetch_projects(function(success, projects)
        if not success then
          vim.notify('Failed to fetch projects: ' .. projects, vim.log.levels.ERROR)
          return
        end
        if #projects == 0 then
          vim.notify(empty_message, vim.log.levels.WARN)
          return
        end

        create_task_with_navigation(task_name, projects)
      end)
    end)
  end
end

function M.log_todoist_task()
  return log_task_with_fetcher(todoist_utils.get_salmon_projects, 'No salmon projects found')
end

function M.log_todoist_task_all_projects()
  return log_task_with_fetcher(todoist_utils.get_projects, 'No projects found')
end

function M.refresh_todoist_cache()
  return function()
    todoist_utils.clear_cache()
    vim.notify('Todoist cache cleared.', vim.log.levels.INFO)
  end
end

return M
