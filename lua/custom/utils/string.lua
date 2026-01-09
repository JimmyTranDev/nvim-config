local M = {}

function M.convertSnakeCaseToNormalCase(snakeCase)
  if not snakeCase or type(snakeCase) ~= 'string' then return '' end
  return snakeCase:gsub('_', ' ')
end

function M.escape_string(str)
  if not str or type(str) ~= 'string' then return '' end
  return str:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
end

function M.escape_pattern(str)
  if not str or type(str) ~= 'string' then return '' end
  return str:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')
end

return M
