-- =============================================================================
-- String Utility Functions
-- =============================================================================

local M = {}

-- =============================================================================
-- Case Conversion Functions
-- =============================================================================

--- Convert snake_case to normal case (spaces)
---@param snakeCase string The snake_case string to convert
---@return string normalCase The string with underscores replaced by spaces
function M.convertSnakeCaseToNormalCase(snakeCase)
  if not snakeCase or type(snakeCase) ~= 'string' then return '' end
  return snakeCase:gsub('_', ' ')
end

-- =============================================================================
-- String Manipulation Functions
-- =============================================================================

--- Escape special characters for Lua pattern matching
---@param str string The string to escape
---@return string escaped The escaped string safe for pattern matching
function M.escape_string(str)
  if not str or type(str) ~= 'string' then return '' end
  return str:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
end

--- Escape pattern characters for search and replace operations
---@param str string The string to escape
---@return string escaped The escaped string safe for pattern operations
function M.escape_pattern(str)
  if not str or type(str) ~= 'string' then return '' end
  -- Escape all Lua pattern special characters
  return str:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')
end

return M
