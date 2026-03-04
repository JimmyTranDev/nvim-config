local M = {}

local function augroup(name)
  return vim.api.nvim_create_augroup('nvim_config_' .. name, { clear = true })
end

local function setup_filetype_associations()
  vim.api.nvim_create_autocmd('BufRead', {
    group = augroup('filetype_associations'),
    pattern = { '*.tag', '*.riot' },
    callback = function() vim.bo.filetype = 'html' end,
    desc = 'Set HTML filetype for Riot.js component files',
  })
end

local function setup_language_settings()
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup('language_settings'),
    pattern = 'java',
    callback = function()
      vim.bo.shiftwidth = 4
      vim.bo.tabstop = 4
      vim.bo.softtabstop = 4
    end,
    desc = 'Set Java-specific indentation (4 spaces)',
  })
end

local function setup_formatting()
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = augroup('formatting'),
    pattern = '*',
    callback = function(args)
      local ok, conform = pcall(require, 'conform')
      if ok then
        conform.format({ bufnr = args.buf, timeout_ms = 3000 })
      end
    end,
    desc = 'Format file on save using conform.nvim',
  })
end

local function setup_visual_enhancements()
  vim.api.nvim_create_autocmd('TextYankPost', {
    group = augroup('visual_enhancements'),
    pattern = '*',
    callback = function()
      vim.highlight.on_yank({ higroup = 'Visual', timeout = 200 })
    end,
    desc = 'Highlight yanked text briefly',
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = augroup('copilot_settings'),
    pattern = 'copilot-*',
    callback = function() vim.opt_local.relativenumber = true end,
    desc = 'Enable relative line numbers in Copilot buffers',
  })
end

local function setup_git_integration()
  vim.api.nvim_create_autocmd('User', {
    group = augroup('git_integration'),
    pattern = 'GitConflictDetected',
    callback = function()
      vim.notify('Git conflict detected in: ' .. vim.fn.expand('<afile>'), vim.log.levels.WARN)
      vim.keymap.set('n', 'cww', function()
        vim.notify('Git conflict resolution functionality not yet implemented', vim.log.levels.INFO)
      end, { buffer = true, desc = 'Resolve git conflicts' })
    end,
    desc = 'Handle git conflict detection and setup resolution keymaps',
  })
end

local function setup_lsp_progress()
  local progress = vim.defaulttable()
  local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

  vim.api.nvim_create_autocmd('LspProgress', {
    group = augroup('lsp_progress'),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      local value = ev.data.params.value
      if not client or type(value) ~= 'table' then return end

      local p = progress[client.id]
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

      local msg = {}
      progress[client.id] = vim.tbl_filter(function(v)
        table.insert(msg, v.msg)
        return not v.done
      end, p)

      local idx = math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1
      vim.notify(table.concat(msg, '\n'), vim.log.levels.INFO, {
        id = 'lsp_progress',
        title = client.name,
        opts = function(notif)
          notif.icon = #progress[client.id] == 0 and ' ' or spinner[idx]
        end,
      })
    end,
    desc = 'Show LSP progress notifications with spinner',
  })
end

local function cleanup_default_keymaps()
  for _, m in ipairs({ 'gra', 'gri', 'grn', 'grr' }) do
    pcall(vim.keymap.del, 'n', m)
  end
end

local function setup_auto_refresh()
  vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
    group = augroup('auto_refresh'),
    pattern = '*',
    callback = function()
      if vim.fn.getcmdwintype() == '' then
        vim.cmd('checktime')
      end
    end,
    desc = 'Check for external file changes and reload buffers',
  })

  vim.api.nvim_create_autocmd('FileChangedShellPost', {
    group = augroup('auto_refresh_notify'),
    pattern = '*',
    callback = function()
      vim.notify('File changed on disk. Buffer reloaded.', vim.log.levels.INFO)
    end,
    desc = 'Notify when a file is reloaded due to external changes',
  })
end

local function setup_toggleterm_whichkey_fix()
  vim.api.nvim_create_autocmd('TermClose', {
    group = augroup('toggleterm_whichkey'),
    callback = function()
      vim.schedule(function()
        local ok, wk = pcall(require, 'which-key')
        if ok then
          vim.o.timeout = true
          vim.o.timeoutlen = 300
        end
      end)
    end,
    desc = 'Re-enable which-key timeout after terminal closes',
  })

  vim.api.nvim_create_autocmd('ModeChanged', {
    group = augroup('toggleterm_whichkey_mode'),
    pattern = 't:n',
    callback = function()
      vim.schedule(function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
      end)
    end,
    desc = 'Restore which-key timeout when leaving terminal mode',
  })
end

local function setup_spell()
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup('spell_check'),
    pattern = { 'gitcommit', 'markdown', 'text', 'plaintex', 'tex' },
    callback = function() vim.opt_local.spell = true end,
    desc = 'Enable spell check for text-heavy filetypes',
  })
end

function M.setup()
  setup_filetype_associations()
  setup_language_settings()
  setup_spell()
  setup_formatting()
  setup_visual_enhancements()
  setup_git_integration()
  setup_lsp_progress()
  setup_auto_refresh()
  setup_toggleterm_whichkey_fix()
  cleanup_default_keymaps()
end

M.setup()

return M
