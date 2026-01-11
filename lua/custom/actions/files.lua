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

-- Helper function to check if a comment should be ignored
local function should_ignore_comment(comment_content)
  if not comment_content then
    return false
  end
  
  -- Trim leading/trailing whitespace from comment content
  local trimmed_content = comment_content:match('^%s*(.-)%s*$')
  
  -- Debug output (uncomment for debugging)
  -- print("Checking comment content: '" .. (trimmed_content or "nil") .. "'")
  
  -- Define patterns to ignore (case-insensitive)
  local ignore_patterns = {
    '^[Nn]ote:',                           -- // Note: or // note:
    '^[Tt]his is a placeholder',           -- // This is a placeholder
    '^[Aa]ctual .* would use',            -- // Actual seeding would use...
    '^[Pp]laceholder',                     -- // Placeholder...
    '^TODO:',                              -- // TODO: (exact case)
    '^todo:',                              -- // todo: (lowercase)
    '^Todo:',                              -- // Todo: (title case)
    '^FIXME:',                             -- // FIXME: (exact case)
    '^fixme:',                             -- // fixme: (lowercase)
    '^Fixme:',                             -- // Fixme: (title case)
    '^HACK:',                              -- // HACK: (exact case)
    '^hack:',                              -- // hack: (lowercase)
    '^Hack:',                              -- // Hack: (title case)
    '^WARNING:',                           -- // WARNING:
    '^warning:',                           -- // warning:
    '^BUG:',                               -- // BUG:
    '^bug:',                               -- // bug:
    '^DEBUG:',                             -- // DEBUG:
    '^debug:',                             -- // debug:
    '^const ',                             -- // const variable = ...
    '^let ',                               -- // let variable = ...
    '^var ',                               -- // var variable = ...
    '^function ',                          -- // function name() {...}
    '^class ',                             -- // class Name {...}
    '^import ',                            -- // import ... from ...
    '^export ',                            -- // export ...
    '^return ',                            -- // return ...
    '^if ',                                -- // if (...) {...}
    '^for ',                               -- // for (...) {...}
    '^while ',                             -- // while (...) {...}
    '^await ',                             -- // await someFunction();
    '^console%.',                          -- // console.log(...) or console.error(...)
    '%.then%(',                            -- // promise.then(...)
    '%.catch%(',                           -- // promise.catch(...)
    '%.map%(',                             -- // array.map(...)
    '%.filter%(',                          -- // array.filter(...)
    '%.forEach%(',                         -- // array.forEach(...)
  }
  
  for _, pattern in ipairs(ignore_patterns) do
    if trimmed_content:match(pattern) then
      -- Debug output (uncomment for debugging)
      -- print("IGNORING: '" .. trimmed_content .. "' matched pattern: " .. pattern)
      return true
    end
  end
  
  -- Debug output (uncomment for debugging)  
  -- print("NOT IGNORING: '" .. trimmed_content .. "'")
  return false
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
      inline_single = '%s%-%-',
      block_start = '^%s*%-%-%[%[',
      block_end = '%]%]',
    },
    javascript = {
      single_line = '^%s*//',
      inline_single = '%s//',
      block_start = '^%s*/%*',
      block_end = '%*/',
      inline_block_start = '%s/%*',
    },
    typescript = {
      single_line = '^%s*//',
      inline_single = '%s//',
      block_start = '^%s*/%*',
      block_end = '%*/',
      inline_block_start = '%s/%*',
    },
    typescriptreact = {
      single_line = '^%s*//',
      inline_single = '%s//',
      block_start = '^%s*/%*',
      block_end = '%*/',
      inline_block_start = '%s/%*',
      jsx_comment = '{/%*.*%*/}',
    },
    javascriptreact = {
      single_line = '^%s*//',
      inline_single = '%s//',
      block_start = '^%s*/%*',
      block_end = '%*/',
      inline_block_start = '%s/%*',
      jsx_comment = '{/%*.*%*/}',
    },
    python = {
      single_line = '^%s*#',
      inline_single = '%s#',
      block_start = '^%s*"""',
      block_end = '"""',
      block_start_alt = "^%s*'''",
      block_end_alt = "'''",
    },
    vim = {
      single_line = '^%s*"',
      inline_single = '%s"',
    },
    sh = {
      single_line = '^%s*#',
      inline_single = '%s#',
    },
    bash = {
      single_line = '^%s*#',
      inline_single = '%s#',
    },
    css = {
      single_line = nil,
      block_start = '^%s*/%*',
      block_end = '%*/',
      inline_block_start = '%s/%*',
    },
  }

  local patterns = comment_patterns[filetype]
  if not patterns then
    vim.notify('Comment deletion not supported for filetype: ' .. filetype, vim.log.levels.WARN)
    return
  end

  local new_lines = {}
  local in_block_comment = false
  local in_ignore_block = false  -- Track if we're in a block of comments to ignore
  local removed_count = 0
  local modified_count = 0

  for _, line in ipairs(lines) do
    local should_keep = true
    local modified_line = line
    
    -- Check if this is a blank line (breaks ignore blocks)
    local is_blank_line = line:match('^%s*$')
    if is_blank_line then
      in_ignore_block = false
    end

    -- Handle block comments first
    if patterns.block_start and patterns.block_end then
      if in_block_comment then
        if line:find(patterns.block_end) then in_block_comment = false end
        should_keep = false
        removed_count = removed_count + 1
      elseif line:find(patterns.block_start) then
        -- Check if this is a single-line block comment that should be ignored
        local single_line_block = line:find(patterns.block_end)
        if single_line_block then
          -- Single-line block comment /* content */
          local comment_content = line:match('/%*%s*(.-)%s*%*/')
          if not should_ignore_comment(comment_content) then
            should_keep = false
            removed_count = removed_count + 1
          end
        else
          -- Multi-line block comment - check the content on this line
          local comment_content = line:match(patterns.block_start .. '%s*(.*)')
          if not should_ignore_comment(comment_content) then
            in_block_comment = true
            should_keep = false
            removed_count = removed_count + 1
          end
        end
      end
    end

    -- Handle alternative block comments (Python)
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

    -- Handle single-line comments (full line comments) with block tracking
    if patterns.single_line and should_keep and not in_block_comment then
      if line:find(patterns.single_line) then
        -- Extract the comment content to check if it should be ignored
        local comment_content
        if filetype == 'javascript' or filetype == 'typescript' or filetype == 'typescriptreact' or filetype == 'javascriptreact' then
          comment_content = line:match('//%s*(.*)')  -- Extract everything after //
        elseif filetype == 'lua' then
          comment_content = line:match('--%s*(.*)')  -- Extract everything after --
        elseif filetype == 'python' or filetype == 'sh' or filetype == 'bash' then
          comment_content = line:match('#%s*(.*)')   -- Extract everything after #
        else
          -- Generic fallback
          comment_content = line:match(patterns.single_line .. '%s*(.*)')
        end
        
        if should_ignore_comment(comment_content) then
          -- This comment should be ignored, start an ignore block
          in_ignore_block = true
        elseif in_ignore_block then
          -- We're in an ignore block, continue ignoring this comment line
          -- Keep the comment (don't set should_keep = false)
        else
          -- Regular comment, not in ignore block, remove it
          should_keep = false
          removed_count = removed_count + 1
        end
      else
        -- This line is not a comment, end the ignore block
        in_ignore_block = false
      end
    else
      -- This line is not a single-line comment, end the ignore block
      if not in_block_comment then
        in_ignore_block = false
      end
    end

    -- Handle inline comments if the line is being kept
    if should_keep and not in_block_comment then
      local original_line = modified_line
      
      -- Handle inline single-line comments
      if patterns.inline_single then
        local comment_start = modified_line:find(patterns.inline_single)
        if comment_start then
          -- Make sure we're not inside a string literal
          local before_comment = modified_line:sub(1, comment_start - 1)
          local in_string = false
          local quote_char = nil
          
          -- Simple string detection (handles basic cases)
          for i = 1, #before_comment do
            local char = before_comment:sub(i, i)
            if char == '"' or char == "'" then
              if not in_string then
                in_string = true
                quote_char = char
              elseif char == quote_char and before_comment:sub(i-1, i-1) ~= '\\' then
                in_string = false
                quote_char = nil
              end
            end
          end
          
          if not in_string then
            -- Extract the comment content to check if it should be ignored
            local comment_content = modified_line:sub(comment_start + 1) -- Skip the comment delimiter
            if not should_ignore_comment(comment_content) then
              modified_line = before_comment:gsub('%s+$', '') -- Remove trailing whitespace
              if modified_line ~= original_line then
                modified_count = modified_count + 1
              end
            end
          end
        end
      end
      
      -- Handle inline block comments
      if patterns.inline_block_start and patterns.block_end then
        local comment_start = modified_line:find(patterns.inline_block_start)
        local comment_end = modified_line:find(patterns.block_end)
        
        if comment_start and comment_end and comment_end > comment_start then
          -- Simple string detection for inline block comments
          local before_comment = modified_line:sub(1, comment_start - 1)
          local in_string = false
          local quote_char = nil
          
          for i = 1, #before_comment do
            local char = before_comment:sub(i, i)
            if char == '"' or char == "'" then
              if not in_string then
                in_string = true
                quote_char = char
              elseif char == quote_char and before_comment:sub(i-1, i-1) ~= '\\' then
                in_string = false
                quote_char = nil
              end
            end
          end
          
          if not in_string then
            -- Extract the comment content to check if it should be ignored
            local comment_content = modified_line:sub(comment_start + 2, comment_end - 1) -- Extract content between /* and */
            if not should_ignore_comment(comment_content) then
              local after_comment = modified_line:sub(comment_end + 2) -- +2 to skip */
              modified_line = before_comment:gsub('%s+$', '') .. after_comment
              if modified_line ~= original_line then
                modified_count = modified_count + 1
              end
            end
          end
        end
      end
      
      -- Handle JSX comments {/* comment */}
      if patterns.jsx_comment then
        local jsx_start, jsx_end = modified_line:find('{/%*.*%*/}')
        if jsx_start and jsx_end then
          -- Simple check to avoid removing from string literals
          local before_jsx = modified_line:sub(1, jsx_start - 1)
          local in_string = false
          local quote_char = nil
          
          for i = 1, #before_jsx do
            local char = before_jsx:sub(i, i)
            if char == '"' or char == "'" or char == '`' then
              if not in_string then
                in_string = true
                quote_char = char
              elseif char == quote_char and before_jsx:sub(i-1, i-1) ~= '\\' then
                in_string = false
                quote_char = nil
              end
            end
          end
          
          if not in_string then
            -- Extract the JSX comment content to check if it should be ignored
            local jsx_comment = modified_line:sub(jsx_start, jsx_end)
            local comment_content = jsx_comment:match('{/%*%s*(.-)%s*%*/}') -- Extract content between {/* and */}
            if not should_ignore_comment(comment_content) then
              local before_jsx_clean = before_jsx:gsub('%s+$', '')
              local after_jsx = modified_line:sub(jsx_end + 1)
              modified_line = before_jsx_clean .. after_jsx
              if modified_line ~= original_line then
                modified_count = modified_count + 1
              end
            end
          end
        end
      end
    end

    if should_keep then 
      table.insert(new_lines, modified_line)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)

  local total_changes = removed_count + modified_count
  if removed_count > 0 and modified_count > 0 then
    vim.notify(string.format('Deleted %d comment lines and removed inline comments from %d lines in %s file', 
      removed_count, modified_count, filetype), vim.log.levels.INFO)
  elseif removed_count > 0 then
    vim.notify(string.format('Deleted %d comment lines from %s file', removed_count, filetype), vim.log.levels.INFO)
  elseif modified_count > 0 then
    vim.notify(string.format('Removed inline comments from %d lines in %s file', modified_count, filetype), vim.log.levels.INFO)
  else
    vim.notify(string.format('No comments found in %s file', filetype), vim.log.levels.INFO)
  end
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

-- Function to get uncommitted files from git
local function get_uncommitted_files()
  local cmd = 'git status --porcelain'
  local output = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    vim.notify('Error running git status: ' .. output, vim.log.levels.ERROR)
    return {}
  end
  
  local files = {}
  for line in output:gmatch('[^\r\n]+') do
    -- Parse git status porcelain format
    -- Format: XY filename (or XY old_name -> new_name for renames)
    -- X = staged, Y = working tree
    -- We want files that are modified, added, or have changes
    local status = line:sub(1, 2)
    local filename = line:sub(4) -- Skip the status and space
    
    -- Include modified, added, untracked, or renamed files
    if status:match('[MAUR]') or status:match('.[MAUR]') then
      -- Handle renamed files: "old_name -> new_name"
      if status:match('R') then
        -- For renamed files, we want to process the new file (destination)
        -- Use plain text search to avoid pattern matching issues with dashes
        local arrow_pos = filename:find(' -> ', 1, true)
        if arrow_pos then
          local old_filename = filename:sub(1, arrow_pos - 1)
          filename = filename:sub(arrow_pos + 4) -- Get the new filename after " -> "
          vim.notify(string.format('Detected rename: %s -> %s', old_filename, filename), vim.log.levels.DEBUG)
        else
          -- Handle malformed rename line - fallback to original filename
          vim.notify(string.format('Malformed rename line: %s', line), vim.log.levels.WARN)
        end
      end
      
      -- Trim any whitespace from filename (defensive programming)
      filename = filename:match("^%s*(.-)%s*$") or filename
      
      -- Only add the file if it's readable (exists and accessible) and not empty
      if filename ~= "" and vim.fn.filereadable(filename) == 1 then
        table.insert(files, filename)
      else
        if filename == "" then
          vim.notify(string.format('Skipping empty filename from line: %s', line), vim.log.levels.WARN)
        else
          vim.notify(string.format('Skipping %s (file not found or not readable)', filename), vim.log.levels.DEBUG)
        end
      end
    end
  end
  
  return files
end

-- Function to delete comments from all uncommitted files
function M.delete_comments_from_uncommitted_files()
  local uncommitted_files = get_uncommitted_files()
  
  if #uncommitted_files == 0 then
    vim.notify('No uncommitted files found', vim.log.levels.WARN)
    return
  end
  
  local processed_count = 0
  local total_files = #uncommitted_files
  
  -- Get current buffer to restore later
  local original_buf = vim.api.nvim_get_current_buf()
  
  vim.notify(string.format('Processing %d uncommitted files...', total_files), vim.log.levels.INFO)
  
  for _, filepath in ipairs(uncommitted_files) do
    -- Open the file in a new buffer
    vim.cmd('silent! edit ' .. vim.fn.fnameescape(filepath))
    local bufnr = vim.api.nvim_get_current_buf()
    
    -- Check if the file has a supported filetype for comment removal
    local filetype = vim.bo[bufnr].filetype
    local supported_filetypes = {
      'lua', 'javascript', 'typescript', 'typescriptreact', 'javascriptreact',
      'python', 'vim', 'sh', 'bash', 'css'
    }
    
    local is_supported = false
    for _, supported_ft in ipairs(supported_filetypes) do
      if filetype == supported_ft then
        is_supported = true
        break
      end
    end
    
    if is_supported then
      -- Apply comment deletion to this buffer
      M.delete_all_comments()
      processed_count = processed_count + 1
      
      -- Save the file
      vim.cmd('silent! write')
    else
      vim.notify(string.format('Skipping %s (filetype: %s - not supported)', filepath, filetype), vim.log.levels.INFO)
    end
  end
  
  -- Restore original buffer
  vim.api.nvim_set_current_buf(original_buf)
  
  vim.notify(string.format('Processed %d out of %d uncommitted files', processed_count, total_files), vim.log.levels.INFO)
end

return M
