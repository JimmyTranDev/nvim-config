-- =============================================================================
-- Neovim Commands and Autocommands
-- =============================================================================

-- =============================================================================
-- File Type Associations
-- =============================================================================

-- Riot.js file handling
vim.api.nvim_create_autocmd('BufRead', {
  pattern = '*.tag',
  callback = function() vim.bo.filetype = 'html' end,
  desc = 'Set filetype for Riot.js .tag files',
})

vim.api.nvim_create_autocmd('BufRead', {
  pattern = '*.riot',
  callback = function() vim.bo.filetype = 'html' end,
  desc = 'Set filetype for Riot.js .riot files',
})

-- =============================================================================
-- Formatting and Code Actions
-- =============================================================================

-- Format on save
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  callback = function(args) require('conform').format({ bufnr = args.buf }) end,
  desc = 'Format file on save using conform.nvim',
})

-- =============================================================================
-- Language-specific Settings
-- =============================================================================

-- Java indentation handling
vim.api.nvim_create_autocmd('BufRead', {
  callback = function()
    if vim.bo.filetype == 'java' then
      vim.bo.shiftwidth = 4
      vim.bo.tabstop = 4
    else
      vim.bo.shiftwidth = 2
      vim.bo.tabstop = 2
    end
  end,
  desc = 'Set language-specific indentation (Java: 4 spaces, others: 2 spaces)',
})

-- =============================================================================
-- Git Integration
-- =============================================================================

-- Git conflict detection
vim.api.nvim_create_autocmd('User', {
  pattern = 'GitConflictDetected',
  callback = function()
    vim.notify('Conflict detected in ' .. vim.fn.expand('<afile>'))
    vim.keymap.set('n', 'cww', function()
      -- Note: 'engage' appears to be a custom module not currently available
      -- engage.conflict_buster()
      -- create_buffer_local_mappings()
      vim.notify('Git conflict resolution functionality needs to be implemented')
    end)
  end,
  desc = 'Handle git conflict detection',
})

-- =============================================================================
-- Visual Enhancements
-- =============================================================================

-- Highlight yanked text
vim.cmd([[
  augroup highlight_yank
  autocmd!
  au TextYankPost * silent! lua vim.highlight.on_yank({higroup="Visual", timeout=200})
  augroup END
]])

-- Copilot buffer settings
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = 'copilot-*',
  callback = function() vim.opt_local.relativenumber = true end,
  desc = 'Enable relative numbers in Copilot buffers',
})

-- Modern which-key highlighting
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = function()
    -- Which-Key modern styling
    vim.api.nvim_set_hl(0, 'WhichKey', { fg = '#cdd6f4', bold = true })
    vim.api.nvim_set_hl(0, 'WhichKeyGroup', { fg = '#f38ba8', bold = true })
    vim.api.nvim_set_hl(0, 'WhichKeyDesc', { fg = '#a6e3a1' })
    vim.api.nvim_set_hl(0, 'WhichKeySeparator', { fg = '#6c7086' })
    vim.api.nvim_set_hl(0, 'WhichKeyFloat', { bg = '#181825' })
    vim.api.nvim_set_hl(0, 'WhichKeyBorder', { fg = '#6c7086' })
    vim.api.nvim_set_hl(0, 'WhichKeyValue', { fg = '#fab387' })
  end,
  desc = 'Set which-key colors',
})

-- Apply immediately if colorscheme is already loaded
if vim.g.colors_name then vim.api.nvim_exec_autocmds('ColorScheme', { pattern = vim.g.colors_name }) end

-- =============================================================================
-- LSP Progress Notifications
-- =============================================================================

---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
local progress = vim.defaulttable()

vim.api.nvim_create_autocmd('LspProgress', {
  ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local value = ev.data.params.value

    if not client or type(value) ~= 'table' then return end

    local p = progress[client.id]

    -- Update or add progress entry
    for i = 1, #p + 1 do
      if i == #p + 1 or p[i].token == ev.data.params.token then
        p[i] = {
          token = ev.data.params.token,
          msg = ('[%3d%%] %s%s'):format(
            value.kind == 'end' and 100 or value.percentage or 100,
            value.title or '',
            value.message and (' **%s**'):format(value.message) or ''
          ),
          done = value.kind == 'end',
        }
        break
      end
    end

    -- Filter completed progress and build message
    local msg = {}
    progress[client.id] = vim.tbl_filter(function(v) return table.insert(msg, v.msg) or not v.done end, p)

    -- Show notification with spinner
    local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
    vim.notify(table.concat(msg, '\n'), 'info', {
      id = 'lsp_progress',
      title = client.name,
      opts = function(notif) notif.icon = #progress[client.id] == 0 and ' ' or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1] end,
    })
  end,
  desc = 'Show LSP progress notifications',
})

-- =============================================================================
-- VSCode Integration
-- =============================================================================

-- Open current Git root in VSCode and jump to current file+line
vim.api.nvim_create_user_command('CodeHere', function()
  -- Absolute path to current file and cursor line
  local file = vim.fn.expand('%:p')
  local line = vim.fn.line('.')

  -- Find Git root (falls back to current dir if no repo)
  local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if git_root == nil or git_root == '' then git_root = vim.fn.getcwd() end

  -- Open VSCode with Git root as workspace
  vim.fn.jobstart({
    'code',
    '--reuse-window',
    git_root, -- set workspace folder
    '--goto',
    file .. ':' .. line, -- jump to same file & line
  }, { detach = true })
end, {})

-- =============================================================================
-- Cleanup Default Key Mappings
-- =============================================================================

-- Remove conflicting default LSP key mappings
local default_lsp_maps = { 'gra', 'gri', 'grn', 'grr' }
for _, map in ipairs(default_lsp_maps) do
  pcall(vim.keymap.del, 'n', map)
end
