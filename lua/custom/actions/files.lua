local file_utils = require('custom.utils.files')

local M = {}

function M.open_current_dir()
  local dir = vim.fn.expand('%:p:h')
  if dir ~= '' then
    file_utils.open(dir)
  else
    vim.notify('No current file directory found', vim.log.levels.WARN)
  end
end

function M.yank_word_and_open()
  vim.cmd('normal! "ayW')
  local word = vim.fn.getreg('a')
  if word == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end
  local ok, err = pcall(vim.cmd, 'edit ' .. word)
  if not ok then vim.notify('Failed to open file: ' .. err, vim.log.levels.ERROR) end
end

M.yankWordAndOpen = M.yank_word_and_open

function M.copy_all_files_content()
  if vim.fn.expand('%:p') == '' then
    vim.notify('No current file', vim.log.levels.WARN)
    return
  end
  vim.fn.setreg('+', file_utils.get_recursive_file_contents())
  vim.notify('Copied all files content to clipboard', vim.log.levels.INFO)
end

function M.save_clipboard_to_file()
  local content = vim.fn.getreg('+')
  if content == '' then
    vim.notify('Clipboard is empty', vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = 'Enter filename: ' }, function(filename)
    if not filename or filename == '' then return end
    local path = vim.fn.expand('%:p:h') .. '/' .. filename
    local file = io.open(path, 'w')
    if file then
      file:write(content)
      file:close()
      vim.notify('File saved: ' .. path, vim.log.levels.INFO)
    else
      vim.notify('Could not create file', vim.log.levels.ERROR)
    end
  end)
end

function M.copy_current_file_url()
  local file = vim.fn.expand('%:p')
  if file == '' then
    vim.notify('No file is currently open', vim.log.levels.WARN)
    return
  end
  local url = 'file://' .. file
  vim.fn.setreg('+', url)
  vim.notify('Copied: ' .. url, vim.log.levels.INFO)
end

function M.copy_opencode_link()
  local file = vim.fn.expand('%:p')
  if file == '' then
    vim.notify('No file is currently open', vim.log.levels.WARN)
    return
  end
  local link = ('opencode://file?path=%s&line=%d'):format(
    vim.fn.shellescape(vim.fn.fnamemodify(file, ':.')),
    vim.fn.line('.')
  )
  vim.fn.setreg('+', link)
  vim.notify('Copied: ' .. link, vim.log.levels.INFO)
end

local IGNORE_PATTERNS = {
  '^[Nn]ote:', '^[Tt]his is a placeholder', '^[Pp]laceholder',
  '^TODO', '^todo', '^FIXME', '^fixme', '^HACK', '^hack',
  '^WARNING', '^warning', '^BUG', '^bug', '^DEBUG', '^debug',
  '^XXX', '^OPTIMIZE', '^REVIEW',
  '^eslint%-', '^@ts%-', '^prettier%-ignore', '^stylelint%-disable',
}

local function should_ignore_comment(content)
  if not content then return false end
  local trimmed = content:match('^%s*(.-)%s*$')
  for _, p in ipairs(IGNORE_PATTERNS) do
    if trimmed:match(p) then return true end
  end
  return false
end

local COMMENT_PATTERNS = {
  lua = { single = '^%s*%-%-', block_start = '^%s*%-%-%[%[', block_end = '%]%]' },
  javascript = { single = '^%s*//', block_start = '^%s*/%*', block_end = '%*/' },
  typescript = { single = '^%s*//', block_start = '^%s*/%*', block_end = '%*/' },
  typescriptreact = { single = '^%s*//', block_start = '^%s*/%*', block_end = '%*/' },
  javascriptreact = { single = '^%s*//', block_start = '^%s*/%*', block_end = '%*/' },
  python = { single = '^%s*#', block_start = '^%s*"""', block_end = '"""' },
  go = { single = '^%s*//', block_start = '^%s*/%*', block_end = '%*/' },
  vim = { single = '^%s*"' },
  sh = { single = '^%s*#' },
  bash = { single = '^%s*#' },
  css = { block_start = '^%s*/%*', block_end = '%*/' },
}

function M.delete_all_comments()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local patterns = COMMENT_PATTERNS[ft]

  if not patterns then
    vim.notify('Comment deletion not supported for: ' .. ft, vim.log.levels.WARN)
    return
  end

  local new_lines = {}
  local in_block = false
  local removed = 0

  for _, line in ipairs(lines) do
    local keep = true

    if patterns.block_start and patterns.block_end then
      if in_block then
        if line:find(patterns.block_end) then in_block = false end
        keep = false
      elseif line:find(patterns.block_start) then
        in_block = not line:find(patterns.block_end)
        keep = false
      end
    end

    if keep and patterns.single and line:find(patterns.single) then
      local content = line:match('//(.*)') or line:match('%-%-(.*)') or line:match('#(.*)')
      if not should_ignore_comment(content) then
        keep = false
      end
    end

    if keep then
      table.insert(new_lines, line)
    else
      removed = removed + 1
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
  vim.notify(('Deleted %d comment lines'):format(removed), vim.log.levels.INFO)
end

local SUPPORTED_FT = { 'lua', 'javascript', 'typescript', 'typescriptreact', 'javascriptreact', 'python', 'go', 'vim', 'sh', 'bash', 'css' }

function M.delete_comments_from_uncommitted_files()
  local output = vim.fn.system('git status --porcelain')
  if vim.v.shell_error ~= 0 then
    vim.notify('Error running git status', vim.log.levels.ERROR)
    return
  end

  local files = {}
  for line in output:gmatch('[^\r\n]+') do
    local status, filename = line:sub(1, 2), line:sub(4)
    if status:match('[MAUR]') or status:match('.[MAUR]') then
      if status:match('R') then
        local arrow = filename:find(' -> ', 1, true)
        if arrow then filename = filename:sub(arrow + 4) end
      end
      filename = filename:match('^%s*(.-)%s*$')
      if filename ~= '' and vim.fn.filereadable(filename) == 1 then
        table.insert(files, filename)
      end
    end
  end

  if #files == 0 then
    vim.notify('No uncommitted files found', vim.log.levels.WARN)
    return
  end

  local original_buf = vim.api.nvim_get_current_buf()
  local processed = 0

  for _, filepath in ipairs(files) do
    vim.cmd('silent! edit ' .. vim.fn.fnameescape(filepath))
    local ft = vim.bo.filetype
    if vim.tbl_contains(SUPPORTED_FT, ft) then
      M.delete_all_comments()
      vim.cmd('silent! write')
      processed = processed + 1
    end
  end

  vim.api.nvim_set_current_buf(original_buf)
  vim.notify(('Processed %d/%d files'):format(processed, #files), vim.log.levels.INFO)
end

function M.run_clipboard_command()
  local content = vim.fn.trim(vim.fn.getreg('+'))
  if content == '' then
    vim.notify('Clipboard is empty', vim.log.levels.WARN)
    return
  end
  vim.notify('Running: ' .. content, vim.log.levels.INFO)
  vim.cmd(':TermExec cmd="' .. content .. '"')
end

function M.link_github_copilot_instructions()
  vim.fn.system('mkdir -p ./.github')
  local result = vim.fn.system('ln -sf ~/Programming/dotfiles/etc/.github/copilot-instructions.md ./.github/copilot-instructions.md')
  if vim.v.shell_error == 0 then
    vim.notify('Successfully linked copilot instructions', vim.log.levels.INFO)
  else
    vim.notify('Failed to link: ' .. result, vim.log.levels.ERROR)
  end
end

return M
