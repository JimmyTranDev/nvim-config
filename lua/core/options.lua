-- =============================================================================
-- Neovim Options Configuration
-- =============================================================================

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
-- Copilot configuration
vim.g.copilot_no_tab_map = true

-- Netrw configuration
vim.g.netrw_sort_sequence = 'r'

-- =============================================================================
-- Display and UI Settings
-- =============================================================================
-- Line numbers
vim.wo.number = true
vim.wo.relativenumber = true

-- Cursor and scrolling
vim.opt.cursorline = true
vim.o.scrolloff = 99999 -- Auto center screen

vim.wo.wrap = false
vim.o.foldenable = false
vim.wo.linebreak = true
vim.wo.list = false

-- Status line
vim.o.laststatus = 3 -- Global status line

-- Colors and themes
vim.o.termguicolors = true

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

-- Keep sign column always visible
vim.wo.signcolumn = 'yes'

-- =============================================================================
-- Diagnostic Signs
-- =============================================================================
local signs = {
  { name = 'DiagnosticSignError', text = ' ' },
  { name = 'DiagnosticSignWarn', text = ' ' },
  { name = 'DiagnosticSignInfo', text = ' ' },
  { name = 'DiagnosticSignHint', text = '󰌵' },
}

for _, sign in ipairs(signs) do
  vim.fn.sign_define(sign.name, { text = sign.text, texthl = sign.name })
end

-- =============================================================================
-- Custom Highlighting
-- =============================================================================
-- Line number colors
vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#5e67a1', bold = true })
vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#5e67a1', bold = true })
