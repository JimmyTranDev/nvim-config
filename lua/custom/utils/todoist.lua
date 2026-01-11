local M = {}

local asyncUtils = require('custom.utils.async')

local projects_cache = nil
local sections_cache = {}

function M.get_projects(callback)
  if projects_cache then
    if callback then callback(true, projects_cache) end
    return
  end

  local token = os.getenv('PRI_TODOIST_API_TOKEN')
  if not token then
    if callback then callback(false, 'PRI_TODOIST_API_TOKEN environment variable not set') end
    return
  end

  local cmd = {
    'curl',
    '-X',
    'GET',
    'https://api.todoist.com/rest/v2/projects',
    '-H',
    'Authorization: Bearer ' .. token,
    '-H',
    'Content-Type: application/json',
  }

  asyncUtils.execute_curl(cmd, function(success, result)
    if not success then
      print('Error: Failed to fetch projects - ' .. result)
      if callback then callback(false, result) end
      return
    end

    local json_result = result:match('^%s*%[.*%]%s*$')
    if json_result then
      local projects = {}
      for project_json in result:gmatch('{[^}]*"name"[^}]*}') do
        local id = project_json:match('"id":%s*"([^"]*)"') or project_json:match('"id":%s*([^,}]+)')
        local name = project_json:match('"name":%s*"([^"]*)"')
        local color = project_json:match('"color":%s*"([^"]*)"')
        local child_order = project_json:match('"child_order":%s*([%d]+)')
        local view_order = project_json:match('"view_order":%s*([%d]+)')

        if id and name then table.insert(projects, {
          id = id,
          name = name,
          color = color or 'grey',
          child_order = tonumber(child_order) or 0,
          view_order = tonumber(view_order) or 0,
        }) end
      end

      projects_cache = projects
      print('Successfully fetched ' .. #projects .. ' projects')
      if callback then callback(true, projects) end
    else
      print('Error: Invalid JSON response for projects - ' .. result)
      if callback then callback(false, 'Invalid JSON response') end
    end
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

    print('Successfully filtered ' .. #salmon_projects .. ' salmon projects out of ' .. #projects .. ' total projects')
    if callback then callback(true, salmon_projects) end
  end)
end

function M.get_sections(project_id, callback)
  if sections_cache[project_id] then
    if callback then callback(true, sections_cache[project_id]) end
    return
  end

  local token = os.getenv('PRI_TODOIST_API_TOKEN')
  if not token then
    if callback then callback(false, 'PRI_TODOIST_API_TOKEN environment variable not set') end
    return
  end

  local cmd = {
    'curl',
    '-X',
    'GET',
    'https://api.todoist.com/rest/v2/sections?project_id=' .. project_id,
    '-H',
    'Authorization: Bearer ' .. token,
    '-H',
    'Content-Type: application/json',
  }

  asyncUtils.execute_curl(cmd, function(success, result)
    if not success then
      print('Error: Failed to fetch sections - ' .. result)
      if callback then callback(false, result) end
      return
    end

    local json_result = result:match('^%s*%[.*%]%s*$')
    if json_result then
      local sections = {}
      for section_json in result:gmatch('{[^}]*"name"[^}]*}') do
        local id = section_json:match('"id":%s*"([^"]*)"') or section_json:match('"id":%s*([^,}]+)')
        local name = section_json:match('"name":%s*"([^"]*)"')
        local order = section_json:match('"order":%s*([%d]+)')

        if id and name then table.insert(sections, {
          id = id,
          name = name,
          project_id = project_id,
          order = tonumber(order) or 0,
        }) end
      end

      -- Sort sections by their order index
      table.sort(sections, function(a, b)
        if a.order ~= b.order then
          return a.order < b.order
        end
        return a.name < b.name
      end)

      sections_cache[project_id] = sections
      print('Successfully fetched ' .. #sections .. ' sections for project ' .. project_id)
      if callback then callback(true, sections) end
    else
      print('Error: Invalid JSON response for sections - ' .. result)
      if callback then callback(false, 'Invalid JSON response') end
    end
  end)
end

function M.debug_project_ordering(callback)
  M.get_projects(function(success, projects)
    if not success then
      if callback then callback(false, projects) end
      return
    end
    
    print('Project ordering debug:')
    for i, project in ipairs(projects) do
      print(string.format('%d. %s (child_order: %d, view_order: %d)', 
        i, project.name, project.child_order or 0, project.view_order or 0))
    end
    
    if callback then callback(true, projects) end
  end)
end

function M.clear_cache()
  projects_cache = nil
  sections_cache = {}
  print('Todoist cache cleared - next API call will fetch fresh data with index ordering')
end

function M.create_task_with_project(content, project_id, section_id, priority, due_string, callback)
  if not content or content == '' then
    if callback then callback(false, 'Task content cannot be empty') end
    return
  end

  local token = os.getenv('PRI_TODOIST_API_TOKEN')
  if not token then
    if callback then callback(false, 'PRI_TODOIST_API_TOKEN environment variable not set') end
    return
  end

  local task_data = {
    content = content,
  }

  if project_id and project_id ~= '' then task_data.project_id = project_id end

  if section_id and section_id ~= '' then task_data.section_id = section_id end

  if priority and priority ~= '' and priority ~= 'p4' then
    local priority_map = { p1 = '4', p2 = '3', p3 = '2', p4 = '1' }
    task_data.priority = priority_map[priority] or '1'
  end

  if due_string and due_string ~= '' then task_data.due_string = due_string end

  local json_parts = {}
  for key, value in pairs(task_data) do
    table.insert(json_parts, string.format('"%s": "%s"', key, tostring(value):gsub('"', '\\"')))
  end
  local json_data = '{' .. table.concat(json_parts, ', ') .. '}'

  local cmd = {
    'curl',
    '-X',
    'POST',
    'https://api.todoist.com/rest/v2/tasks',
    '-H',
    'Authorization: Bearer ' .. token,
    '-H',
    'Content-Type: application/json',
    '-d',
    json_data,
  }

  asyncUtils.execute_curl(cmd, function(success, result)
    if not success then
      print('Error: Failed to create task - ' .. result)
      if callback then callback(false, result) end
      return
    end

    local json_result = result:match('^%s*{.*}%s*$')
    if json_result and json_result:match('"id"') then
      print('Task created successfully: ' .. content)
      if callback then callback(true, result) end
    else
      print('Error: Failed to create task - ' .. result)
      if callback then callback(false, result) end
    end
  end)
end

function M.create_task(text, callback)
  if not text or text == '' then
    if callback then callback(false, 'Task text cannot be empty') end
    return
  end

  local token = os.getenv('PRI_TODOIST_API_TOKEN')
  if not token then
    if callback then callback(false, 'PRI_TODOIST_API_TOKEN environment variable not set') end
    return
  end

  local cmd = {
    'curl',
    '-X',
    'POST',
    'https://api.todoist.com/rest/v2/tasks',
    '-H',
    'Authorization: Bearer ' .. token,
    '-H',
    'Content-Type: application/json',
    '-d',
    string.format('{"content": "%s"}', text:gsub('"', '\\"')),
  }

  asyncUtils.execute_curl(cmd, function(success, result)
    if not success then
      print('Error: Failed to create task - ' .. result)
      if callback then callback(false, result) end
      return
    end

    local json_result = result:match('^%s*{.*}%s*$')
    if json_result and json_result:match('"id"') then
      print('Task created successfully: ' .. text)
      if callback then callback(true, result) end
    else
      print('Error: Failed to create task - ' .. result)
      if callback then callback(false, result) end
    end
  end)
end

function M.create_task_quick(text, callback)
  if not text or text == '' then
    if callback then callback(false, 'Task text cannot be empty') end
    return
  end

  local token = os.getenv('PRI_TODOIST_API_TOKEN')
  if not token then
    if callback then callback(false, 'PRI_TODOIST_API_TOKEN environment variable not set') end
    return
  end

  local cmd = {
    'curl',
    '-X',
    'POST',
    'https://api.todoist.com/sync/v9/quick/add',
    '-H',
    'Authorization: Bearer ' .. token,
    '-d',
    'text=' .. text:gsub(' ', '%%20'):gsub('"', '%%22'),
  }

  asyncUtils.execute_curl(cmd, function(success, result)
    if not success then
      print('Error: Failed to create task - ' .. result)
      if callback then callback(false, result) end
      return
    end

    if result:match('"id"') or result:match('sync_token') then
      print('Task created successfully: ' .. text)
      if callback then callback(true, result) end
    else
      print('Error: Failed to create task - ' .. result)
      if callback then callback(false, result) end
    end
  end)
end

function M.create_task_sync(text)
  vim.notify('Warning: create_task_sync is deprecated. Use create_task with callback instead.', vim.log.levels.WARN)
  local success = false
  M.create_task(text, function(ok, _) success = ok end)
  return success
end

function M.create_task_quick_sync(text)
  vim.notify('Warning: create_task_quick_sync is deprecated. Use create_task_quick with callback instead.', vim.log.levels.WARN)
  local success = false
  M.create_task_quick(text, function(ok, _) success = ok end)
  return success
end

return M
