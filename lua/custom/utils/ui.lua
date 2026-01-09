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

function M.select_commit(include_all, callback)
  local git_utils = require('custom.utils.git')
  local commit_lines, line_to_sha = git_utils.get_commit_log(include_all)

  if #commit_lines == 0 then
    vim.notify('No commits found', vim.log.levels.WARN)
    return
  end

  M.safe_select(commit_lines, {
    prompt = 'Select commit:',
    format_item = function(item) return item end,
  }, function(selected_line)
    local sha = line_to_sha[selected_line]
    if sha then
      callback(selected_line, sha)
    else
      vim.notify('Failed to extract commit SHA', vim.log.levels.ERROR)
    end
  end)
end

function M.select_file(dir, prompt, callback)
  local file_utils = require('custom.utils.files')
  local files = file_utils.list_files(dir)

  M.safe_select(files, {
    prompt = prompt or 'Select file:',
  }, callback)
end

function M.safe_input(opts, validator, callback)
  if type(validator) == 'function' and not callback then
    callback = validator
    validator = nil
  end

  if not callback then error('Callback function is required') end

  vim.ui.input(opts, function(input)
    if not input or input == '' then
      return -- User cancelled or provided empty input
    end

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

function M.input_with_confirmation(opts, confirmation_prompt, callback)
  M.safe_input(opts, function(input)
    M.safe_input({
      prompt = confirmation_prompt .. ' (type "yes" to confirm): ',
    }, function(confirmation)
      if confirmation == 'yes' then
        callback(input)
      else
        vim.notify('Operation cancelled', vim.log.levels.INFO)
      end
    end)
  end)
end

function M.show_progress(message, level) return vim.notify(message, level or vim.log.levels.INFO) end

function M.update_progress(notification, message, level)
  vim.notify(message, level or vim.log.levels.INFO, {
    replace = notification,
  })
end

function M.show_success(message) vim.notify(message, vim.log.levels.INFO) end

function M.show_error(message) vim.notify(message, vim.log.levels.ERROR) end

function M.show_warning(message) vim.notify(message, vim.log.levels.WARN) end

function M.exec_with_feedback(cmd, success_msg, terminal_id)
  if not cmd then error('Command is required') end

  local term_id = terminal_id or 5
  local term_cmd = string.format("TermExec%d cmd='%s'", term_id, cmd)

  vim.cmd(term_cmd)

  if success_msg then
    vim.defer_fn(function() M.show_success(success_msg) end, 500) -- Small delay to let command start
  end
end

function M.exec_background(cmd, success_msg) M.exec_with_feedback(cmd, success_msg, 5) end

function M.create_workflow()
  local workflow = {
    steps = {},
    current_step = 1,
  }

  function workflow:add_step(name, fn)
    table.insert(self.steps, { name = name, fn = fn })
    return self
  end

  function workflow:next()
    if self.current_step > #self.steps then
      M.show_success('Workflow completed')
      return
    end

    local step = self.steps[self.current_step]
    M.show_progress('Executing: ' .. step.name)

    step.fn(function()
      self.current_step = self.current_step + 1
      self:next()
    end)
  end

  function workflow:execute()
    if #self.steps == 0 then
      M.show_warning('No steps defined in workflow')
      return
    end

    self.current_step = 1
    self:next()
  end

  return workflow
end

return M

