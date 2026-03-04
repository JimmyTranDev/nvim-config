local M = {}

function M.tableMerge(table1, table2, result)
  if type(result) ~= 'table' then error('Result table must be provided') end
  for _, src in ipairs({ table1, table2 }) do
    if type(src) == 'table' then
      for _, v in ipairs(src) do
        table.insert(result, v)
      end
    end
  end
end

return M
