-- =============================================================================
-- Neovim Options Configuration
-- =============================================================================

-- Check if we're in VSCode
local is_vscode = vim.g.vscode ~= nil

-- Spell checking
vim.opt.spelllang = 'en_us'

-- =============================================================================
-- Leader Keys (must be set before plugins load)
-- =============================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- =============================================================================
-- Plugin-specific Settings
-- =============================================================================
-- Copilot configuration (disable in VSCode as it has its own)
if not is_vscode then vim.g.copilot_no_tab_map = true end

-- Netrw configuration (disable in VSCode)
if not is_vscode then vim.g.netrw_sort_sequence = 'r' end

-- =============================================================================
-- Display and UI Settings
-- =============================================================================
-- Line numbers (VSCode handles these)
if not is_vscode then
  vim.wo.number = true
  vim.wo.relativenumber = true
end

-- Cursor and scrolling
if not is_vscode then vim.opt.cursorline = true end
vim.o.scrolloff = 99999 -- Auto center screen

-- Wrapping and line display
vim.wo.wrap = false
vim.wo.linebreak = true
vim.wo.list = false

-- Status line (VSCode handles this)
if not is_vscode then
  vim.o.laststatus = 3 -- Global status line
else
  vim.o.laststatus = 0 -- No status line in VSCode
end

-- Colors and themes (VSCode handles themes)
if not is_vscode then vim.o.termguicolors = true end

-- =============================================================================
-- Indentation and Spacing
-- =============================================================================
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.o.breakindent = true

-- =============================================================================
-- Mouse and Input
-- =============================================================================
vim.o.mouse = 'a'

-- =============================================================================
-- Clipboard Configuration
-- =============================================================================
vim.o.clipboard = 'unnamedplus'
vim.opt.clipboard = 'unnamedplus'

-- WSL clipboard integration
if vim.fn.has('wsl') == 1 then
  vim.g.clipboard = {
    name = 'win32yank',
    copy = {
      ['+'] = 'win32yank.exe -i --crlf',
      ['*'] = 'win32yank.exe -i --crlf',
    },
    paste = {
      ['+'] = 'win32yank.exe -o --lf',
      ['*'] = 'win32yank.exe -o --lf',
    },
    cache_enabled = 0,
  }
end

-- =============================================================================
-- File Management
-- =============================================================================
vim.o.undofile = true -- Persistent undo

-- =============================================================================
-- Search Configuration
-- =============================================================================
vim.o.ignorecase = true
-- vim.o.smartcase = true  -- Commented out intentionally

-- =============================================================================
-- Performance and Timing
-- =============================================================================
vim.o.updatetime = 100 -- Faster CursorHold events (was inconsistent before)
vim.o.timeoutlen = 300 -- Faster key sequence timeout

-- =============================================================================
-- Completion
-- =============================================================================
vim.o.completeopt = 'menuone,noselect'

-- Keep sign column always visible (only in regular Neovim)
if not is_vscode then
  vim.wo.signcolumn = 'yes'
else
  vim.wo.signcolumn = 'no' -- VSCode handles this
end

-- =============================================================================
-- Diagnostic Signs (only in regular Neovim)
-- =============================================================================
if not is_vscode then
  local signs = {
    { name = 'DiagnosticSignError', text = ' ' },
    { name = 'DiagnosticSignWarn', text = ' ' },
    { name = 'DiagnosticSignInfo', text = ' ' },
    { name = 'DiagnosticSignHint', text = '󰌵' },
  }

  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { text = sign.text, texthl = sign.name })
  end
end

-- =============================================================================
-- Custom Highlighting (only in regular Neovim)
-- =============================================================================
if not is_vscode then
  -- Line number colors
  vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#5e67a1', bold = true })
  vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#5e67a1', bold = true })
end
