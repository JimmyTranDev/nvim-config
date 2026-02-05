local M = {}

function M.remove(array, value)
  if type(array) ~= 'table' then return false end
  for i, v in ipairs(array) do
    if v == value then
      table.remove(array, i)
      return true
    end
  end
  return false
end

M.removeFromArray = M.remove

function M.merge(dest, ...)
  dest = dest or {}
  for _, src in ipairs({ ... }) do
    if type(src) == 'table' then
      for _, v in ipairs(src) do
        table.insert(dest, v)
      end
    end
  end
  return dest
end

function M.tableMerge(table1, table2, result)
  if type(result) ~= 'table' then error('Result table must be provided') end
  M.merge(result, table1, table2)
end

function M.contains(array, value)
  if type(array) ~= 'table' then return false end
  for _, v in ipairs(array) do
    if v == value then return true end
  end
  return false
end

M.hasValue = M.contains

return M
