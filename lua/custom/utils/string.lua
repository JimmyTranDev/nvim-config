local M = {}

function M.snake_to_normal(str)
  if type(str) ~= 'string' then return '' end
  return str:gsub('_', ' ')
end

M.convertSnakeCaseToNormalCase = M.snake_to_normal

function M.escape_pattern(str)
  if type(str) ~= 'string' then return '' end
  return str:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')
end

M.escape_string = M.escape_pattern

return M
