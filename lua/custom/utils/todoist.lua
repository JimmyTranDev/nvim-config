local M = {}

local asyncUtils = require('custom.utils.async')

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
    if callback then callback(false, err) end
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

  asyncUtils.execute_curl(cmd, function(success, result)
    if not success then
      if callback then callback(false, result) end
      return
    end

    local ok, decoded = pcall(vim.fn.json_decode, result)
    if not ok then
      if callback then callback(false, 'Invalid JSON response') end
      return
    end

    callback(true, decoded.results or decoded)
  end)
end

function M.get_projects(callback)
  if projects_cache then
    if callback then callback(true, projects_cache) end
    return
  end

  todoist_request('GET', 'projects', nil, function(success, data)
    if not success then
      if callback then callback(false, data) end
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
    if callback then callback(true, projects) end
  end)
end

function M.get_salmon_projects(callback)
  M.get_projects(function(success, projects)
    if not success then
      if callback then callback(false, projects) end
      return
    end

    local salmon_projects = {}
    for _, project in ipairs(projects) do
      if project.color == 'salmon' then table.insert(salmon_projects, project) end
    end

    if callback then callback(true, salmon_projects) end
  end)
end

function M.get_sections(project_id, callback)
  if sections_cache[project_id] then
    if callback then callback(true, sections_cache[project_id]) end
    return
  end

  todoist_request('GET', 'sections?project_id=' .. project_id, nil, function(success, data)
    if not success then
      if callback then callback(false, data) end
      return
    end

    local sections = {}
    for _, section in ipairs(data) do
      if section.id and section.name then
        table.insert(sections, {
          id = tostring(section.id),
          name = section.name,
          project_id = project_id,
          order = tonumber(section.section_order) or tonumber(section.order) or 0,
        })
      end
    end

    table.sort(sections, function(a, b)
      if a.order ~= b.order then return a.order < b.order end
      return a.name < b.name
    end)

    sections_cache[project_id] = sections
    if callback then callback(true, sections) end
  end)
end

function M.clear_cache()
  projects_cache = nil
  sections_cache = {}
end

function M.create_task_with_project(content, project_id, section_id, priority, due_string, callback)
  if not content or content == '' then
    if callback then callback(false, 'Task content cannot be empty') end
    return
  end

  local task_data = { content = content }
  if project_id and project_id ~= '' then task_data.project_id = project_id end
  if section_id and section_id ~= '' then task_data.section_id = section_id end
  if priority and priority ~= '' and priority ~= 'p4' then
    local priority_map = { p1 = '4', p2 = '3', p3 = '2', p4 = '1' }
    task_data.priority = priority_map[priority] or '1'
  end
  if due_string and due_string ~= '' then task_data.due_string = due_string end

  local json_data = vim.fn.json_encode(task_data)

  local token, err = get_token()
  if not token then
    if callback then callback(false, err) end
    return
  end

  local cmd = {
    'curl', '-X', 'POST',
    'https://api.todoist.com/api/v1/tasks',
    '-H', 'Authorization: Bearer ' .. token,
    '-H', 'Content-Type: application/json',
    '-d', json_data,
  }

  asyncUtils.execute_curl(cmd, function(success, result)
    if not success then
      if callback then callback(false, result) end
      return
    end

    if result:match('"id"') then
      if callback then callback(true, result) end
    else
      if callback then callback(false, result) end
    end
  end)
end

return M
