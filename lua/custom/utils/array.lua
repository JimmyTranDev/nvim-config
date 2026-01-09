local M = {}

function M.removeFromArray(array, value)
  if not array or type(array) ~= 'table' then return false end

  for i, v in ipairs(array) do
    if v == value then
      table.remove(array, i)
      return true
    end
  end
  return false
end

function M.tableMerge(table1, table2, result)
  if not result or type(result) ~= 'table' then error('Result table must be provided') end

  if table1 and type(table1) == 'table' then
    for _, v in ipairs(table1) do
      table.insert(result, v)
    end
  end

  if table2 and type(table2) == 'table' then
    for _, v in ipairs(table2) do
      table.insert(result, v)
    end
  end
end

function M.hasValue(array, value)
  if not array or type(array) ~= 'table' then return false end

  for _, v in ipairs(array) do
    if v == value then return true end
  end
  return false
end

return M
