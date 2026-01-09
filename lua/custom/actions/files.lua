local file_utils = require('custom.utils.files')

local M = {}

function M.open_current_dir()
  local current_dir = vim.fn.expand('%:p:h')
  if current_dir and current_dir ~= '' then
    file_utils.open(current_dir)
  else
    vim.notify('No current file directory found', vim.log.levels.WARN)
  end
end

function M.move_file_to_assets(source_dir)
  return function()
    if not source_dir then
      vim.notify('Source directory not specified', vim.log.levels.ERROR)
      return
    end

    local cwd = vim.fn.getcwd()
    local asset_dirs = file_utils.find_dirs_with_name('assets')

    if #asset_dirs == 0 then
      vim.notify('No assets folder found in project', vim.log.levels.WARN)
      return
    end

    local target_dir = cwd .. '/' .. asset_dirs[1]
    local origin_dir = file_utils.get_path_from_home(source_dir)
    local file_names = file_utils.list_files(origin_dir)

    if #file_names == 0 then
      vim.notify('No files found in source directory', vim.log.levels.WARN)
      return
    end

    vim.ui.select(file_names, {
      prompt = 'Select file to move to assets:',
    }, function(filename)
      if not filename then return end

      local new_filename = file_utils.rename_file_interactive(filename, origin_dir, target_dir)
      if new_filename then
        file_utils.paste_markdown_link(new_filename)
        vim.notify('File moved and markdown link pasted', vim.log.levels.INFO)
      end
    end)
  end
end

function M.yank_word_and_open()
  vim.cmd('normal! "ayW')
  local yanked_word = vim.fn.getreg('a')

  if not yanked_word or yanked_word == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(vim.cmd, 'edit ' .. yanked_word)
  if not ok then vim.notify('Failed to open file: ' .. err, vim.log.levels.ERROR) end
end

function M.copy_all_files_content()
  local current_file = vim.fn.expand('%:p')
  if current_file == '' then
    vim.notify('No current file', vim.log.levels.WARN)
    return
  end

  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  local content = file_utils.get_recursive_file_contents()

  vim.fn.setreg('+', content)
  vim.notify('Copied content of all files in ' .. current_dir .. ' to clipboard', vim.log.levels.INFO)
end

function M.save_clipboard_to_file()
  local clipboard_content = vim.fn.getreg('+')

  if clipboard_content == '' then
    vim.notify('Clipboard is empty', vim.log.levels.WARN)
    return
  end

  vim.ui.input({
    prompt = 'Enter filename: ',
    default = '',
  }, function(filename)
    if not filename or filename == '' then
      vim.notify('No filename provided, operation cancelled', vim.log.levels.WARN)
      return
    end

    local current_dir = vim.fn.expand('%:p:h')
    local filepath = current_dir .. '/' .. filename

    local ok, err = pcall(function()
      local file = io.open(filepath, 'w')
      if not file then error('Could not create file: ' .. filepath) end
      file:write(clipboard_content)
      file:close()
    end)

    if ok then
      vim.notify('File saved: ' .. filepath, vim.log.levels.INFO)
    else
      vim.notify('Error saving file: ' .. err, vim.log.levels.ERROR)
    end
  end)
end

function M.copy_current_file_url()
  local current_file = vim.fn.expand('%:p')

  if current_file == '' then
    vim.notify('No file is currently open', vim.log.levels.WARN)
    return
  end

  local file_url = 'file://' .. current_file
  vim.fn.setreg('+', file_url)
  vim.notify('Copied file URL to clipboard: ' .. file_url, vim.log.levels.INFO)
end

function M.delete_all_comments()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if #lines == 0 then
    vim.notify('Buffer is empty', vim.log.levels.WARN)
    return
  end

  local comment_patterns = {
    lua = {
      single_line = '^%s*%-%-',
      block_start = '^%s*%-%-%[%[',
      block_end = '%]%]',
    },
    javascript = {
      single_line = '^%s*//',
      block_start = '^%s*/%*',
      block_end = '%*/',
    },
    typescript = {
      single_line = '^%s*//',
      block_start = '^%s*/%*',
      block_end = '%*/',
    },
    python = {
      single_line = '^%s*#',
      block_start = '^%s*"""',
      block_end = '"""',
      block_start_alt = "^%s*'''",
      block_end_alt = "'''",
    },
    vim = {
      single_line = '^%s*"',
    },
    sh = {
      single_line = '^%s*#',
    },
    bash = {
      single_line = '^%s*#',
    },
    css = {
      single_line = nil,
      block_start = '^%s*/%*',
      block_end = '%*/',
    },
  }

  local patterns = comment_patterns[filetype]
  if not patterns then
    vim.notify('Comment deletion not supported for filetype: ' .. filetype, vim.log.levels.WARN)
    return
  end

  local new_lines = {}
  local in_block_comment = false
  local removed_count = 0

  for _, line in ipairs(lines) do
    local should_keep = true

    if patterns.block_start and patterns.block_end then
      if in_block_comment then
        if line:find(patterns.block_end) then in_block_comment = false end
        should_keep = false
        removed_count = removed_count + 1
      elseif line:find(patterns.block_start) then
        in_block_comment = true
        if line:find(patterns.block_end) then in_block_comment = false end
        should_keep = false
        removed_count = removed_count + 1
      end
    end

    if patterns.block_start_alt and patterns.block_end_alt and should_keep then
      if in_block_comment then
        if line:find(patterns.block_end_alt) then in_block_comment = false end
        should_keep = false
        removed_count = removed_count + 1
      elseif line:find(patterns.block_start_alt) then
        in_block_comment = true
        if line:find(patterns.block_end_alt) then in_block_comment = false end
        should_keep = false
        removed_count = removed_count + 1
      end
    end

    if patterns.single_line and should_keep and not in_block_comment then
      if line:find(patterns.single_line) then
        should_keep = false
        removed_count = removed_count + 1
      end
    end

    if should_keep then table.insert(new_lines, line) end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)

  vim.notify(string.format('Deleted %d comment lines from %s file', removed_count, filetype), vim.log.levels.INFO)
end

function M.run_clipboard_command()
  local clipboard_content = vim.fn.getreg('+')

  if clipboard_content == '' then
    vim.notify('Clipboard is empty', vim.log.levels.WARN)
    return
  end

  clipboard_content = vim.fn.trim(clipboard_content)

  if clipboard_content == '' then
    vim.notify('Clipboard contains only whitespace', vim.log.levels.WARN)
    return
  end

  vim.notify('Running command from clipboard: ' .. clipboard_content, vim.log.levels.INFO)
  vim.cmd(':TermExec cmd="' .. clipboard_content .. '"')
end

function M.link_github_copilot_instructions()
  local source_path = '~/Programming/dotfiles/etc/.github/copilot-instructions.md'
  local target_path = './.github/copilot-instructions.md'

  vim.fn.system('mkdir -p ./.github')

  local cmd = string.format('ln -sf %s %s', vim.fn.shellescape(source_path), vim.fn.shellescape(target_path))
  local result = vim.fn.system(cmd)

  if vim.v.shell_error == 0 then
    vim.notify('Successfully linked copilot instructions from dotfiles', vim.log.levels.INFO)
  else
    vim.notify('Failed to link copilot instructions: ' .. result, vim.log.levels.ERROR)
  end
end

return M
