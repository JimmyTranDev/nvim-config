local M = {}

local async_utils = require('custom.utils.async')
local json_utils = require('custom.utils.json')

vim.env.TODOIST_API_TOKEN = vim.env.PRI_TODOIST_API_TOKEN or vim.env.TODOIST_API_TOKEN

local PROJECTS_CACHE_FILE = vim.fn.stdpath('data') .. '/todoist_projects_cache.json'

local projects_cache = nil
local sections_cache = {}

local function load_projects_from_disk()
  if not vim.uv.fs_stat(PROJECTS_CACHE_FILE) then return nil end
  local data = json_utils.parse_json_from_file(PROJECTS_CACHE_FILE)
  if type(data) == 'table' and data.projects and #data.projects > 0 then return data.projects end
  return nil
end

local function save_projects_to_disk(projects)
  json_utils.write_json_to_file(PROJECTS_CACHE_FILE, { projects = projects })
end

local function td_command(args, callback)
  local cmd = vim.list_extend({ 'td' }, args)

  async_utils.execute(cmd, function(success, stdout, stderr)
    if not success then
      callback(false, stderr ~= '' and stderr or 'td command failed')
      return
    end

    local ok, decoded = pcall(vim.fn.json_decode, stdout)
    if not ok then
      callback(false, 'Invalid JSON response from td')
      return
    end

    callback(true, decoded)
  end)
end

function M.get_projects(callback)
  if projects_cache then
    callback(true, projects_cache)
    return
  end

  local disk_cache = load_projects_from_disk()
  if disk_cache then
    projects_cache = disk_cache
    callback(true, projects_cache)
    return
  end

  td_command({ 'project', 'list', '--json', '--full' }, function(success, data)
    if not success then
      callback(false, data)
      return
    end

    local results = data.results or data
    local projects = {}
    for _, project in ipairs(results) do
      if project.id and project.name and not project.isArchived then
        table.insert(projects, {
          id = tostring(project.id),
          name = project.name,
          color = project.color or 'grey',
          child_order = tonumber(project.childOrder) or 0,
        })
      end
    end

    projects_cache = projects
    save_projects_to_disk(projects)
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

  td_command({ 'section', 'list', 'id:' .. project_id, '--json', '--full' }, function(success, data)
    if not success then
      callback(false, data)
      return
    end

    local results = data.results or data
    local sections = {}
    for _, section in ipairs(results) do
      if section.id and section.name and not section.isArchived then
        table.insert(sections, {
          id = tostring(section.id),
          name = section.name,
          order = tonumber(section.sectionOrder) or 0,
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
  os.remove(PROJECTS_CACHE_FILE)
end

function M.create_task(content, project_id, section_id, priority, callback)
  if not content or content == '' then
    callback(false, 'Task content cannot be empty')
    return
  end

  local cmd = { 'task', 'add', content }

  if project_id and project_id ~= '' then
    table.insert(cmd, '--project')
    table.insert(cmd, 'id:' .. project_id)
  end

  if section_id and section_id ~= '' then
    table.insert(cmd, '--section')
    table.insert(cmd, 'id:' .. section_id)
  end

  if priority == 'p1' then
    table.insert(cmd, '--priority')
    table.insert(cmd, 'p1')
  end

  local full_cmd = vim.list_extend({ 'td' }, cmd)

  async_utils.execute(full_cmd, function(success, stdout, stderr)
    if success and stdout:match('Created:') then
      local task_id = stdout:match('ID:%s*(%S+)')
      callback(true, { id = task_id or 'unknown' })
    else
      callback(false, stderr ~= '' and stderr or stdout)
    end
  end)
end

return M
