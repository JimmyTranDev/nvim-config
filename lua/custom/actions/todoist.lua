local inputUtils = require('custom.utils.input')
local todoistUtils = require('custom.utils.todoist')

local M = {}

local todoistPriorityOptions = {
  { name = 'Priority None', value = 'p4' },
  { name = 'Priority High', value = 'p1' },
  { name = 'Priority Medium', value = 'p2' },
  { name = 'Priority Low', value = 'p3' },
}

-- Helper to get/set recent project
local RECENT_PROJECT_FILE = vim.fn.stdpath('data') .. '/todoist_recent_project.txt'
local function get_recent_project_id()
  local f = io.open(RECENT_PROJECT_FILE, 'r')
  if f then
    local id = f:read('*l')
    f:close()
    return id
  end
  return nil
end
local function set_recent_project_id(id)
  local f = io.open(RECENT_PROJECT_FILE, 'w')
  if f then
    f:write(id)
    f:close()
  end
end

-- Helper function to create task with navigation support
local function create_task_with_navigation(taskName, projects, fallbackProjectName)
  -- Forward declare functions to avoid scoping issues
  local select_project, select_section, select_priority
  
  select_project = function()
    -- Sort projects by recent usage
    local recent_id = get_recent_project_id()
    table.sort(projects, function(a, b)
      if a.id == recent_id then return true end
      if b.id == recent_id then return false end
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
      if selected_project == nil then
        vim.notify('Task creation cancelled', vim.log.levels.INFO)
        return
      end
      set_recent_project_id(selected_project.id)
      select_section(selected_project)
    end)
  end
  
  select_section = function(selected_project)
    todoistUtils.get_sections(selected_project.id, function(sections_success, sections)
      if not sections_success then
        vim.notify('Failed to fetch sections: ' .. sections, vim.log.levels.ERROR)
        return
      end

      local section_options = { 
        { name = 'No section', id = nil } 
      }
      for _, section in ipairs(sections) do
        table.insert(section_options, {
          name = section.name,
          id = section.id,
        })
      end
      table.insert(section_options, { name = '← Back to projects', id = '__back__' })

      vim.ui.select(section_options, {
        prompt = 'Select a section:',
        format_item = function(item) return item.name end,
      }, function(selected_section)
        if selected_section == nil then
          vim.notify('Task creation cancelled', vim.log.levels.INFO)
          return
        end
        
        if selected_section.id == '__back__' then
          select_project()
          return
        end

        select_priority(selected_project, selected_section)
      end)
    end)
  end
  
  select_priority = function(selected_project, selected_section)
    local priority_options = {}
    for _, option in ipairs(todoistPriorityOptions) do
      table.insert(priority_options, option)
    end
    table.insert(priority_options, { name = '← Back to sections', value = '__back__' })

    vim.ui.select(priority_options, {
      prompt = 'Select a priority for the task:',
      format_item = function(item) return item.name end,
    }, function(priorityOption)
      if priorityOption == nil then
        vim.notify('Task creation cancelled', vim.log.levels.INFO)
        return
      end
      
      if priorityOption.value == '__back__' then
        select_section(selected_project)
        return
      end

      todoistUtils.create_task_with_project(
        taskName,
        selected_project.id,
        selected_section.id,
        priorityOption.value,
        '', -- Empty deadline
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
  
  -- Start the navigation flow
  select_project()
end

function M.log_todoist_task(fallbackProjectName)
  return function()
    local taskName = inputUtils.getInputFromUser('Enter the task name: ')
    if taskName == nil then
      vim.notify('No task name provided', vim.log.levels.WARN)
      return
    end

    todoistUtils.get_salmon_projects(function(success, projects)
      if not success then
        vim.notify('Failed to fetch projects: ' .. projects, vim.log.levels.ERROR)
        return
      end
      if #projects == 0 then
        vim.notify('No salmon projects found, using fallback', vim.log.levels.WARN)
        M.logTodoistTaskLegacy(fallbackProjectName)()
        return
      end
      
      create_task_with_navigation(taskName, projects, fallbackProjectName)
    end)
  end
end

-- Add function to refresh Todoist cache
function M.refresh_todoist_cache()
  return function()
    todoistUtils.clear_cache()
    vim.notify('Todoist cache cleared. Next API call will fetch fresh data.', vim.log.levels.INFO)
  end
end

-- Function to create task with all projects (not just salmon)
function M.log_todoist_task_all_projects(fallbackProjectName)
  return function()
    local taskName = inputUtils.getInputFromUser('Enter the task name: ')
    if taskName == nil then
      vim.notify('No task name provided', vim.log.levels.WARN)
      return
    end

    -- Fetch ALL projects (not just salmon)
    todoistUtils.get_projects(function(success, projects)
      if not success then
        vim.notify('Failed to fetch projects: ' .. projects, vim.log.levels.ERROR)
        return
      end

      -- Add fallback option if projects are empty
      if #projects == 0 then
        vim.notify('No projects found, using fallback', vim.log.levels.WARN)
        M.logTodoistTaskLegacy(fallbackProjectName)()
        return
      end

      create_task_with_navigation(taskName, projects, fallbackProjectName)
    end)
  end
end

return M
