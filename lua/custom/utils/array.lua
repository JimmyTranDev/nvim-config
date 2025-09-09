-- =============================================================================
-- Array Utility Functions
-- =============================================================================

local M = {}

-- =============================================================================
-- Array Manipulation Functions
-- =============================================================================

--- Remove first occurrence of value from array
---@param array table The array to modify
---@param value any The value to remove
---@return boolean removed True if value was found and removed
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

--- Merge two arrays into a result array
---@param table1 table First array to merge
---@param table2 table Second array to merge
---@param result table Target array to store the result
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

--- Check if array contains a specific value
---@param array table The array to search
---@param value any The value to find
---@return boolean has_value True if value exists in array
function M.hasValue(array, value)
  if not array or type(array) ~= 'table' then return false end

  for _, v in ipairs(array) do
    if v == value then return true end
  end
  return false
end

return M
