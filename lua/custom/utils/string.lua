local M = {}

function M.escape_pattern(str)
  if type(str) ~= 'string' then return '' end
  return str:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')
end

return M
