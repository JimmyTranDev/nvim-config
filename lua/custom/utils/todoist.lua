local M = {}

local async_utils = require('custom.utils.async')

local projects_cache = nil
local sections_cache = {}

local function get_token()
  local token = os.getenv('PRI_TODOIST_API_TOKEN')
  if not token then return nil, 'PRI_TODOIST_API_TOKEN environment variable not set' end
  return token
end

local function todoist_request(method, endpoint, data, callback)
  local token, err = get_token()
  if not token then
    callback(false, err)
    return
  end

  local cmd = {
    'curl', '-X', method,
    'https://api.todoist.com/api/v1/' .. endpoint,
    '-H', 'Authorization: Bearer ' .. token,
    '-H', 'Content-Type: application/json',
  }

  if data then
    table.insert(cmd, '-d')
    table.insert(cmd, data)
  end

  async_utils.execute_curl(cmd, function(success, result)
    if not success then
      callback(false, result)
      return
    end

    local ok, decoded = pcall(vim.fn.json_decode, result)
    if not ok then
      callback(false, 'Invalid JSON response')
      return
    end

    callback(true, decoded.results or decoded)
  end)
end

function M.get_projects(callback)
  if projects_cache then
    callback(true, projects_cache)
    return
  end

  todoist_request('GET', 'projects', nil, function(success, data)
    if not success then
      callback(false, data)
      return
    end

    local projects = {}
    for _, project in ipairs(data) do
      if project.id and project.name and not project.is_archived then
        table.insert(projects, {
          id = tostring(project.id),
          name = project.name,
          color = project.color or 'grey',
          child_order = tonumber(project.child_order) or 0,
          view_order = tonumber(project.view_order) or 0,
        })
      end
    end

    projects_cache = projects
    callback(true, projects)
  end)
end

function M.get_salmon_projects(callback)
  M.get_projects(function(success, projects)
    if not success then
      callback(false, projects)
      return
    end

    local salmon_projects = {}
    for _, project in ipairs(projects) do
      if project.color == 'salmon' then table.insert(salmon_projects, project) end
    end

    callback(true, salmon_projects)
  end)
end

function M.get_sections(project_id, callback)
  if sections_cache[project_id] then
    callback(true, sections_cache[project_id])
    return
  end

  todoist_request('GET', 'sections?project_id=' .. project_id, nil, function(success, data)
    if not success then
      callback(false, data)
      return
    end

    local sections = {}
    for _, section in ipairs(data) do
      if section.id and section.name then
        table.insert(sections, {
          id = tostring(section.id),
          name = section.name,
          order = tonumber(section.section_order) or tonumber(section.order) or 0,
        })
      end
    end

    table.sort(sections, function(a, b)
      if a.order ~= b.order then return a.order < b.order end
      return a.name < b.name
    end)

    sections_cache[project_id] = sections
    callback(true, sections)
  end)
end

function M.clear_cache()
  projects_cache = nil
  sections_cache = {}
end

function M.create_task(content, project_id, section_id, priority, callback)
  if not content or content == '' then
    callback(false, 'Task content cannot be empty')
    return
  end

  local task_data = { content = content }
  if project_id and project_id ~= '' then task_data.project_id = project_id end
  if section_id and section_id ~= '' then task_data.section_id = section_id end
  if priority == 'p1' then task_data.priority = '4' end

  todoist_request('POST', 'tasks', vim.fn.json_encode(task_data), function(success, data)
    if not success then
      callback(false, data)
      return
    end

    if data.id then
      callback(true, data)
    else
      callback(false, 'Unexpected response: missing task id')
    end
  end)
end

return M
