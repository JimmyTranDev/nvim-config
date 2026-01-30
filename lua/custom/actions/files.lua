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

function M.copy_opencode_link()
  local current_file = vim.fn.expand('%:p')
  
  if current_file == '' then
    vim.notify('No file is currently open', vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.getcwd()
  local relative_path = vim.fn.fnamemodify(current_file, ':.')
  
  local current_line = vim.fn.line('.')
  
  local opencode_link = string.format('opencode://file?path=%s&line=%d', 
    vim.fn.shellescape(relative_path), current_line)
  
  vim.fn.setreg('+', opencode_link)
  vim.notify('Copied OpenCode link to clipboard: ' .. opencode_link, vim.log.levels.INFO)
end

-- Helper function to check if a comment should be ignored
local function should_ignore_comment(comment_content)
  if not comment_content then return false end
  
  local trimmed_content = comment_content:match('^%s*(.-)%s*$')
  
  local ignore_patterns = {
    '^[Nn]ote:', '^[Tt]his is a placeholder', '^[Aa]ctual .* would use', '^[Pp]laceholder',
    '^TODO:', '^todo:', '^Todo:', '^TODO ', '^todo ', '^Todo ',
    '^FIXME:', '^fixme:', '^Fixme:', '^FIXME ', '^fixme ', '^Fixme ',
    '^HACK:', '^hack:', '^Hack:', '^HACK ', '^hack ', '^Hack ',
    '^WARNING:', '^warning:', '^BUG:', '^bug:', '^DEBUG:', '^debug:',
    '^XXX:', '^XXX ', '^OPTIMIZE:', '^OPTIMIZE ', '^REVIEW:', '^REVIEW ',
    '^eslint%-disable', '^eslint%-enable',
    '^@ts%-ignore', '^@ts%-expect%-error', '^@ts%-nocheck',
    '^prettier%-ignore', '^stylelint%-disable',
    '^const ', '^let ', '^var ', '^function ', '^class ', '^import ', '^export ', '^return ',
    '^if ', '^for ', '^while ', '^await ', '^console%.', '%.then%(', '%.catch%(', '%.map%(',
    '%.filter%(', '%.forEach%(',
  }
  
  for _, pattern in ipairs(ignore_patterns) do
    if trimmed_content:match(pattern) then return true end
  end
  
  return false
end

-- Get comment patterns for different file types
local function get_comment_patterns(filetype)
  local patterns = {
    lua = { single_line = '^%s*%-%-', inline_single = '%s%-%-', block_start = '^%s*%-%-%[%[', block_end = '%]%]' },
    javascript = { single_line = '^%s*//', inline_single = '%s//', block_start = '^%s*/%*', block_end = '%*/', inline_block_start = '%s/%*', jsx_comment = '{/%*.*%*/}' },
    typescript = { single_line = '^%s*//', inline_single = '%s//', block_start = '^%s*/%*', block_end = '%*/', inline_block_start = '%s/%*' },
    python = { single_line = '^%s*#', inline_single = '%s#', block_start = '^%s*"""', block_end = '"""', block_start_alt = "^%s*'''", block_end_alt = "'''" },
    css = { block_start = '^%s*/%*', block_end = '%*/', inline_block_start = '%s/%*' },
    go = { single_line = '^%s*//', inline_single = '%s//', block_start = '^%s*/%*', block_end = '%*/', inline_block_start = '%s/%*' },
  }
  
  patterns.typescriptreact = { single_line = '^%s*//', inline_single = '%s//', block_start = '^%s*/%*', block_end = '%*/', inline_block_start = '%s/%*', jsx_comment = '{/%*.*%*/}' }
  patterns.javascriptreact = { single_line = '^%s*//', inline_single = '%s//', block_start = '^%s*/%*', block_end = '%*/', inline_block_start = '%s/%*', jsx_comment = '{/%*.*%*/}' }
  patterns.vim = { single_line = '^%s*"', inline_single = '%s"' }
  patterns.sh = { single_line = '^%s*#', inline_single = '%s#' }
  patterns.bash = patterns.sh
  
  return patterns[filetype]
end

function M.delete_all_comments()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if #lines == 0 then
    vim.notify('Buffer is empty', vim.log.levels.WARN)
    return
  end

  local patterns = get_comment_patterns(filetype)
  if not patterns then
    vim.notify('Comment deletion not supported for filetype: ' .. filetype, vim.log.levels.WARN)
    return
  end

  local new_lines = {}
  local in_block_comment = false
  local in_ignore_block = false
  local removed_count = 0
  local modified_count = 0

  for _, line in ipairs(lines) do
    local should_keep = true
    local modified_line = line
    
    -- Check if this is a blank line (breaks ignore blocks)
    local is_blank_line = line:match('^%s*$')
    if is_blank_line then in_ignore_block = false end

    should_keep, modified_line, in_block_comment, in_ignore_block = 
      M.process_line_comments(line, patterns, in_block_comment, in_ignore_block, filetype)
    
    if should_keep then
      if modified_line ~= line then modified_count = modified_count + 1 end
      table.insert(new_lines, modified_line)
    else
      removed_count = removed_count + 1
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
  M.show_deletion_summary(removed_count, modified_count, filetype)
end

-- Process a single line for comment removal
function M.process_line_comments(line, patterns, in_block_comment, in_ignore_block, filetype)
  local should_keep = true
  local modified_line = line
  
  -- Handle block comments first
  if patterns.block_start and patterns.block_end then
    should_keep, in_block_comment = M.handle_block_comments(line, patterns, in_block_comment)
    if not should_keep then return false, line, in_block_comment, in_ignore_block end
  end

  -- Handle alternative block comments (Python)
  if patterns.block_start_alt and patterns.block_end_alt and should_keep then
    should_keep, in_block_comment = M.handle_alt_block_comments(line, patterns, in_block_comment)
    if not should_keep then return false, line, in_block_comment, in_ignore_block end
  end

  -- Handle single-line comments
  if patterns.single_line and should_keep and not in_block_comment then
    should_keep, in_ignore_block = M.handle_single_line_comments(line, patterns, in_ignore_block, filetype)
    if not should_keep then return false, line, in_block_comment, in_ignore_block end
  else
    if not in_block_comment then in_ignore_block = false end
  end

  -- Handle inline comments if the line is being kept
  if should_keep and not in_block_comment then
    modified_line = M.remove_inline_comments(line, patterns)
  end

  return should_keep, modified_line, in_block_comment, in_ignore_block
end

-- Handle block comment processing
function M.handle_block_comments(line, patterns, in_block_comment)
  if in_block_comment then
    if line:find(patterns.block_end) then in_block_comment = false end
    return false, in_block_comment -- Remove this line
  elseif line:find(patterns.block_start) then
    local single_line_block = line:find(patterns.block_end)
    if single_line_block then
      local comment_content = line:match('/%*%s*(.-)%s*%*/')
      if not should_ignore_comment(comment_content) then return false, in_block_comment end
    else
      local comment_content = line:match(patterns.block_start .. '%s*(.*)')
      if not should_ignore_comment(comment_content) then
        in_block_comment = true
        return false, in_block_comment
      end
    end
  end
  return true, in_block_comment
end

-- Handle alternative block comments (Python docstrings)
function M.handle_alt_block_comments(line, patterns, in_block_comment)
  if in_block_comment then
    if line:find(patterns.block_end_alt) then in_block_comment = false end
    return false, in_block_comment
  elseif line:find(patterns.block_start_alt) then
    in_block_comment = true
    if line:find(patterns.block_end_alt) then in_block_comment = false end
    return false, in_block_comment
  end
  return true, in_block_comment
end

-- Handle single-line comment processing
function M.handle_single_line_comments(line, patterns, in_ignore_block, filetype)
  if line:find(patterns.single_line) then
    local comment_content = M.extract_comment_content(line, filetype)
    
    if should_ignore_comment(comment_content) then
      in_ignore_block = true
    elseif in_ignore_block then
      -- Keep this comment (we're in an ignore block)
    else
      return false, in_ignore_block -- Remove this comment
    end
  else
    in_ignore_block = false
  end
  return true, in_ignore_block
end

-- Extract comment content based on filetype
function M.extract_comment_content(line, filetype)
  if filetype == 'javascript' or filetype == 'typescript' or filetype == 'typescriptreact' or filetype == 'javascriptreact' or filetype == 'go' then
    return line:match('//%s*(.*)')
  elseif filetype == 'lua' then
    return line:match('--%s*(.*)')
  elseif filetype == 'python' or filetype == 'sh' or filetype == 'bash' then
    return line:match('#%s*(.*)')
  else
    return line:match('%s*(.-)%s*$') -- Generic fallback
  end
end

-- Remove inline comments from a line
function M.remove_inline_comments(line, patterns)
  local modified_line = line
  
  -- Handle inline single-line comments
  if patterns.inline_single then
    modified_line = M.remove_inline_single_comments(modified_line, patterns)
  end
  
  -- Handle inline block comments
  if patterns.inline_block_start and patterns.block_end then
    modified_line = M.remove_inline_block_comments(modified_line, patterns)
  end
  
  -- Handle JSX comments
  if patterns.jsx_comment then
    modified_line = M.remove_jsx_comments(modified_line, patterns)
  end
  
  return modified_line
end

-- Remove inline single-line comments
function M.remove_inline_single_comments(line, patterns)
  local comment_start = line:find(patterns.inline_single)
  if not comment_start or M.is_in_string(line, comment_start) then return line end
  
  local comment_content = line:sub(comment_start + 1)
  if should_ignore_comment(comment_content) then return line end
  
  return line:sub(1, comment_start - 1):gsub('%s+$', '')
end

-- Remove inline block comments
function M.remove_inline_block_comments(line, patterns)
  local comment_start = line:find(patterns.inline_block_start)
  local comment_end = line:find(patterns.block_end)
  
  if not comment_start or not comment_end or comment_end <= comment_start or M.is_in_string(line, comment_start) then
    return line
  end
  
  local comment_content = line:sub(comment_start + 2, comment_end - 1)
  if should_ignore_comment(comment_content) then return line end
  
  local before_comment = line:sub(1, comment_start - 1):gsub('%s+$', '')
  local after_comment = line:sub(comment_end + 2)
  return before_comment .. after_comment
end

-- Remove JSX comments
function M.remove_jsx_comments(line, patterns)
  local jsx_start, jsx_end = line:find('{/%*.*%*/}')
  if not jsx_start or not jsx_end or M.is_in_string(line, jsx_start) then return line end
  
  local jsx_comment = line:sub(jsx_start, jsx_end)
  local comment_content = jsx_comment:match('{/%*%s*(.-)%s*%*/}')
  if should_ignore_comment(comment_content) then return line end
  
  local before_jsx = line:sub(1, jsx_start - 1):gsub('%s+$', '')
  local after_jsx = line:sub(jsx_end + 1)
  return before_jsx .. after_jsx
end

-- Simple string detection to avoid removing comments inside strings
function M.is_in_string(line, pos)
  local before = line:sub(1, pos - 1)
  local in_string = false
  local quote_char = nil
  
  for i = 1, #before do
    local char = before:sub(i, i)
    if char == '"' or char == "'" or char == '`' then
      if not in_string then
        in_string = true
        quote_char = char
      elseif char == quote_char and before:sub(i-1, i-1) ~= '\\' then
        in_string = false
        quote_char = nil
      end
    end
  end
  
  return in_string
end

-- Show summary of comment deletion results
function M.show_deletion_summary(removed_count, modified_count, filetype)
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
      'python', 'vim', 'sh', 'bash', 'css', 'go'
    }
    
    local is_supported = false
    for _, supported_ft in ipairs(supported_filetypes) do
      if filetype == supported_ft then
        is_supported = true
        break
      end
    end
    
    if is_supported then
      -- Use enhanced LSP + Tree-sitter approach for Go files
      if filetype == 'go' then
        M.delete_go_comments_with_lsp_context(bufnr)
      else
        -- Apply standard comment deletion to other supported files
        M.delete_all_comments()
      end
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

-- Enhanced Go comment removal using LSP + Tree-sitter
local function get_go_comment_nodes(bufnr)
  -- Check if tree-sitter parser is available for Go
  local has_parser, parser = pcall(vim.treesitter.get_parser, bufnr, 'go')
  if not has_parser then
    vim.notify('Tree-sitter Go parser not available, falling back to regex patterns', vim.log.levels.WARN)
    return nil
  end
  
  local tree = parser:parse()[1]
  local root = tree:root()
  local comments = {}
  
  -- Tree-sitter query to find all comments
  local has_query, query = pcall(vim.treesitter.query.parse, 'go', [[
    (comment) @comment
  ]])
  
  if not has_query then
    vim.notify('Tree-sitter Go query not available, falling back to regex patterns', vim.log.levels.WARN)
    return nil
  end
  
  for id, node in query:iter_captures(root, bufnr) do
    local name = query.captures[id]
    if name == 'comment' then
      local start_row, start_col, end_row, end_col = node:range()
      local comment_text = vim.treesitter.get_node_text(node, bufnr)
      table.insert(comments, {
        node = node,
        start_row = start_row,
        start_col = start_col,
        end_row = end_row,
        end_col = end_col,
        text = comment_text
      })
    end
  end
  
  return comments
end

-- Get LSP document symbols for context analysis
local function get_go_document_symbols(bufnr)
  local symbols = {}
  local params = vim.lsp.util.make_text_document_params(bufnr)
  
  -- Request document symbols from gopls
  local results = vim.lsp.buf_request_sync(bufnr, 'textDocument/documentSymbol', params, 2000)
  
  for _, result in pairs(results or {}) do
    if result.result and not result.err then
      symbols = result.result
      break
    end
  end
  
  return symbols
end

-- Check if comment should be preserved based on LSP context
local function should_preserve_go_comment_with_lsp_context(comment_node, document_symbols)
  local comment_row = comment_node.start_row
  local comment_text = comment_node.text
  
  -- First check existing ignore patterns
  if should_ignore_comment(comment_text) then
    return true
  end
  
  -- Check if comment is within or near important Go structures
  for _, symbol in ipairs(document_symbols or {}) do
    if symbol.range then
      local symbol_start = symbol.range.start.line
      local symbol_end = symbol.range['end'].line
      
      -- Preserve comments that are immediately before exported functions/types
      -- In Go, exported symbols start with uppercase letters
      if symbol.name and symbol.name:match('^[A-Z]') then
        -- Comment is on the line immediately before the symbol
        if comment_row == symbol_start - 1 then
          return true
        end
        -- Comment is within the symbol's range (like function body comments for exported functions)
        if comment_row >= symbol_start and comment_row <= symbol_end then
          -- Check if it's a function or type declaration
          local symbol_kind = symbol.kind
          if symbol_kind == vim.lsp.protocol.SymbolKind.Function or 
             symbol_kind == vim.lsp.protocol.SymbolKind.Struct or
             symbol_kind == vim.lsp.protocol.SymbolKind.Interface then
            return true
          end
        end
      end
    end
  end
  
  return false
end

-- Enhanced Go comment deletion using LSP + Tree-sitter
function M.delete_go_comments_with_lsp_context(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  
  if filetype ~= 'go' then
    vim.notify('This function is specifically for Go files', vim.log.levels.WARN)
    return
  end
  
  -- Try to get tree-sitter comment nodes
  local comment_nodes = get_go_comment_nodes(bufnr)
  
  -- If tree-sitter is not available, fall back to regex approach
  if not comment_nodes then
    vim.notify('Using fallback regex approach for Go comment removal', vim.log.levels.INFO)
    M.delete_all_comments()
    return
  end
  
  -- Get LSP document symbols for context
  local document_symbols = get_go_document_symbols(bufnr)
  
  -- Collect lines to remove
  local lines_to_remove = {}
  local preserved_count = 0
  
  for _, comment in ipairs(comment_nodes) do
    local should_preserve = should_preserve_go_comment_with_lsp_context(comment, document_symbols)
    
    if not should_preserve then
      -- Add all lines of this comment to removal list
      for row = comment.start_row, comment.end_row do
        table.insert(lines_to_remove, row + 1) -- Convert to 1-based indexing
      end
    else
      preserved_count = preserved_count + 1
    end
  end
  
  -- Remove duplicate line numbers and sort in reverse order
  local unique_lines = {}
  for _, line_num in ipairs(lines_to_remove) do
    unique_lines[line_num] = true
  end
  
  local sorted_lines = {}
  for line_num in pairs(unique_lines) do
    table.insert(sorted_lines, line_num)
  end
  table.sort(sorted_lines, function(a, b) return a > b end)
  
  -- Remove lines in reverse order to maintain line number integrity
  for _, line_num in ipairs(sorted_lines) do
    vim.api.nvim_buf_set_lines(bufnr, line_num - 1, line_num, false, {})
  end
  
  local removed_count = #sorted_lines
  vim.notify(string.format(
    'Go LSP + Tree-sitter: Removed %d comment lines, preserved %d important comments (exported symbols, etc.)',
    removed_count, preserved_count
  ), vim.log.levels.INFO)
end

return M
