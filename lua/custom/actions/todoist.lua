-- Store last options for repeat
local last_todoist_options = nil

local inputUtils = require('custom.utils.input')
local todoistUtils = require('custom.utils.todoist')

local M = {}

local todoistPriorityOptions = {
  { name = 'Priority High', value = 'p1' },
  { name = 'Priority Medium', value = 'p2' },
  { name = 'Priority Low', value = 'p3' },
  { name = 'Priority None', value = 'p4' },
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

function M.logTodoistTask(fallbackProjectName)
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
          vim.notify('No project selected', vim.log.levels.WARN)
          return
        end
        set_recent_project_id(selected_project.id)

        -- Fetch sections for the selected project
        todoistUtils.get_sections(selected_project.id, function(sections_success, sections)
          if not sections_success then
            vim.notify('Failed to fetch sections: ' .. sections, vim.log.levels.ERROR)
            return
          end

          -- Add "No section" option
          local section_options = { { name = 'No section', id = nil } }
          for _, section in ipairs(sections) do
            table.insert(section_options, {
              name = section.name,
              id = section.id,
            })
          end

          vim.ui.select(section_options, {
            prompt = 'Select a section:',
            format_item = function(item) return item.name end,
          }, function(selected_section)
            if selected_section == nil then
              vim.notify('No section selected', vim.log.levels.WARN)
              return
            end

            -- Select priority
            vim.ui.select(todoistPriorityOptions, {
              prompt = 'Select a priority for the task:',
              format_item = function(item) return item.name end,
            }, function(priorityOption)
              if priorityOption == nil then
                vim.notify('No priority selected', vim.log.levels.WARN)
                return
              end

              -- Store last options and create task
              last_todoist_options = {
                taskName = taskName,
                projectId = selected_project.id,
                projectName = selected_project.project.name,
                sectionId = selected_section.id,
                sectionName = selected_section.name,
                priority = priorityOption.value,
                deadline = '',
              }
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
          end)
        end)
      end)
    end)
  end
end

-- Add function to refresh Todoist cache
function M.refreshTodoistCache()
  return function()
    todoistUtils.clear_cache()
    vim.notify('Todoist cache cleared. Next API call will fetch fresh data.', vim.log.levels.INFO)
  end
end

-- Function to create task with all projects (not just salmon)
function M.logTodoistTaskAllProjects(fallbackProjectName)
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

      -- Format projects for selection
      local project_options = {}
      for _, project in ipairs(projects) do
        table.insert(project_options, {
          name = project.name .. ' (' .. (project.color or 'grey') .. ')',
          id = project.id,
          project = project,
        })
      end

      vim.ui.select(project_options, {
        prompt = 'Select a project (all projects):',
        format_item = function(item) return item.name end,
      }, function(selected_project)
        if selected_project == nil then
          vim.notify('No project selected', vim.log.levels.WARN)
          return
        end

        -- Fetch sections for the selected project
        todoistUtils.get_sections(selected_project.id, function(sections_success, sections)
          if not sections_success then
            vim.notify('Failed to fetch sections: ' .. sections, vim.log.levels.ERROR)
            return
          end

          -- Add "No section" option
          local section_options = { { name = 'No section', id = nil } }
          for _, section in ipairs(sections) do
            table.insert(section_options, {
              name = section.name,
              id = section.id,
            })
          end

          vim.ui.select(section_options, {
            prompt = 'Select a section:',
            format_item = function(item) return item.name end,
          }, function(selected_section)
            if selected_section == nil then
              vim.notify('No section selected', vim.log.levels.WARN)
              return
            end

            -- Select priority
            vim.ui.select(todoistPriorityOptions, {
              prompt = 'Select a priority for the task:',
              format_item = function(item) return item.name end,
            }, function(priorityOption)
              if priorityOption == nil then
                vim.notify('No priority selected', vim.log.levels.WARN)
                return
              end

              -- Create task with all selected options (no deadline selection)
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
          end)
        end)
      end)
    end)
  end
end

function M.repeatLastTodoistOptions()
  return function()
    if not last_todoist_options then
      vim.notify('No previous Todoist options to repeat', vim.log.levels.WARN)
      return
    end
    vim.ui.input({ prompt = 'Task name: ', default = last_todoist_options.taskName }, function(input)
      local task_name = input or last_todoist_options.taskName
      todoistUtils.create_task_with_project(
        task_name,
        last_todoist_options.projectId,
        last_todoist_options.sectionId,
        last_todoist_options.priority,
        function(task_success, response)
          if task_success then
            vim.notify(
              string.format(
                "Task '%s' created in project '%s'%s",
                last_todoist_options.taskName,
                last_todoist_options.projectName,
                last_todoist_options.sectionName and (' > ' .. last_todoist_options.sectionName) or ''
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
end

return M
