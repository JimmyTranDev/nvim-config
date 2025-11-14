-- =============================================================================
-- Neovim Autocommands and Commands Configuration
-- Organized by functionality for better maintainability
-- =============================================================================

-- =============================================================================
-- Configuration and Constants
-- =============================================================================

local M = {}

-- Autocommand group for organization
local augroup = function(name) return vim.api.nvim_create_augroup('nvim_config_' .. name, { clear = true }) end

-- Which-key color scheme (Catppuccin Dark)
local WHICH_KEY_COLORS = {
  WhichKey = { fg = '#cdd6f4', bold = true },
  WhichKeyGroup = { fg = '#f38ba8', bold = true },
  WhichKeyDesc = { fg = '#a6e3a1' },
  WhichKeySeparator = { fg = '#6c7086' },
  WhichKeyFloat = { bg = '#181825' },
  WhichKeyBorder = { fg = '#6c7086' },
  WhichKeyValue = { fg = '#fab387' },
}

-- =============================================================================
-- File Type and Language Configuration
-- =============================================================================

--- Set up file type associations for specialized files
local function setup_filetype_associations()
  -- Riot.js component files
  vim.api.nvim_create_autocmd('BufRead', {
    group = augroup('filetype_associations'),
    pattern = { '*.tag', '*.riot' },
    callback = function() vim.bo.filetype = 'html' end,
    desc = 'Set HTML filetype for Riot.js component files',
  })
end

--- Configure language-specific indentation settings
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

  -- Default indentation for other languages is handled in options.lua
end

-- =============================================================================
-- Code Formatting and Quality
-- =============================================================================

--- Set up automatic formatting on save
local function setup_formatting()
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = augroup('formatting'),
    pattern = '*',
    callback = function(args)
      -- Only format if conform is available
      local ok, conform = pcall(require, 'conform')
      if ok then conform.format({
        bufnr = args.buf,
        timeout_ms = 3000,
      }) end
    end,
    desc = 'Format file on save using conform.nvim',
  })
end

-- =============================================================================
-- Visual Enhancements and UI
-- =============================================================================

--- Set up visual feedback and enhancements
local function setup_visual_enhancements()
  -- Highlight yanked text
  vim.api.nvim_create_autocmd('TextYankPost', {
    group = augroup('visual_enhancements'),
    pattern = '*',
    callback = function()
      vim.highlight.on_yank({
        higroup = 'Visual',
        timeout = 200,
      })
    end,
    desc = 'Highlight yanked text briefly',
  })

  -- Configure Copilot buffer settings
  vim.api.nvim_create_autocmd('BufEnter', {
    group = augroup('copilot_settings'),
    pattern = 'copilot-*',
    callback = function() vim.opt_local.relativenumber = true end,
    desc = 'Enable relative line numbers in Copilot buffers',
  })
end

-- --- Set up which-key color scheme
-- local function setup_which_key_colors()
--   vim.api.nvim_create_autocmd('ColorScheme', {
--     group = augroup('which_key_colors'),
--     pattern = '*',
--     callback = function()
--       for group, config in pairs(WHICH_KEY_COLORS) do
--         vim.api.nvim_set_hl(0, group, config)
--       end
--     end,
--     desc = 'Apply which-key color scheme',
--   })
--
--   -- Apply immediately if colorscheme is already loaded
--   if vim.g.colors_name then vim.api.nvim_exec_autocmds('ColorScheme', { pattern = vim.g.colors_name }) end
-- end

-- =============================================================================
-- Git Integration
-- =============================================================================

--- Set up git-related autocommands
local function setup_git_integration()
  vim.api.nvim_create_autocmd('User', {
    group = augroup('git_integration'),
    pattern = 'GitConflictDetected',
    callback = function()
      local file = vim.fn.expand('<afile>')
      vim.notify('Git conflict detected in: ' .. file, vim.log.levels.WARN)

      -- Set up temporary keymap for conflict resolution
      vim.keymap.set('n', 'cww', function()
        vim.notify('Git conflict resolution functionality not yet implemented', vim.log.levels.INFO)
        -- Future implementation: integrate with conflict resolution tools
      end, {
        buffer = true,
        desc = 'Resolve git conflicts',
      })
    end,
    desc = 'Handle git conflict detection and setup resolution keymaps',
  })
end

-- =============================================================================
-- LSP Integration and Progress
-- =============================================================================

--- Set up LSP progress notifications
local function setup_lsp_progress()
  ---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
  local progress = vim.defaulttable()

  vim.api.nvim_create_autocmd('LspProgress', {
    group = augroup('lsp_progress'),
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
      progress[client.id] = vim.tbl_filter(function(v)
        table.insert(msg, v.msg)
        return not v.done
      end, p)

      -- Show notification with spinner
      local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
      local spinner_idx = math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1

      vim.notify(table.concat(msg, '\n'), vim.log.levels.INFO, {
        id = 'lsp_progress',
        title = client.name,
        opts = function(notif) notif.icon = #progress[client.id] == 0 and ' ' or spinner[spinner_idx] end,
      })
    end,
    desc = 'Show LSP progress notifications with spinner',
  })
end

--- Clean up conflicting default keymaps
local function cleanup_default_keymaps()
  local default_lsp_maps = { 'gra', 'gri', 'grn', 'grr' }

  for _, map in ipairs(default_lsp_maps) do
    pcall(vim.keymap.del, 'n', map)
  end
end

-- =============================================================================
-- Module Initialization
-- =============================================================================

--- Initialize all autocommands and commands
function M.setup()
  setup_filetype_associations()
  setup_language_settings()
  setup_formatting()
  setup_visual_enhancements()
  -- setup_which_key_colors() -- Commented out function
  setup_git_integration()
  setup_lsp_progress()
  cleanup_default_keymaps()
end

-- Auto-initialize when required
M.setup()

return M
