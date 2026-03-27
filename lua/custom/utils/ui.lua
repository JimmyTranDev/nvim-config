local M = {}

function M.safe_select(items, opts, callback)
  if not items or #items == 0 then
    vim.notify('No items available for selection', vim.log.levels.WARN)
    return
  end
  if not callback then error('Callback function is required') end
  vim.ui.select(items, opts or {}, function(selected)
    if selected then callback(selected) end
  end)
end

function M.safe_input(opts, validator, callback)
  if type(validator) == 'function' and not callback then
    callback = validator
    validator = nil
  end
  if not callback then error('Callback function is required') end

  vim.ui.input(opts, function(input)
    if not input or input == '' then return end
    if validator then
      local is_valid, error_msg = validator(input)
      if not is_valid then
        vim.notify(error_msg or 'Invalid input', vim.log.levels.WARN)
        return
      end
    end
    callback(input)
  end)
end

M.show_success = function(msg) vim.notify(msg, vim.log.levels.INFO) end

function M.exec_in_terminal(cmd, success_msg, terminal_id)
  if not cmd then error('Command is required') end
  vim.cmd(string.format("TermExec%d cmd='%s'", terminal_id or 5, cmd))
  if success_msg then
    vim.defer_fn(function() vim.notify(success_msg, vim.log.levels.INFO) end, 500)
  end
end

function M.add_back_option(options, text, value)
  table.insert(options, { name = '← ' .. text, is_back = true, value = value or '__back__' })
end

return M
