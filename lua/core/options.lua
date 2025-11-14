-- =============================================================================
-- Neovim Options Configuration
-- =============================================================================

-- =============================================================================
-- Leader Keys (MUST be set before plugins load)
-- =============================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- =============================================================================
-- Core Editor Settings
-- =============================================================================

---Configure basic editor behavior with performance optimizations
local function setup_editor_basics()
  -- Language and locale
  vim.opt.spelllang = 'en_us'

  -- Mouse support
  vim.o.mouse = 'a'

  -- File handling
  vim.o.undofile = true -- Persistent undo across sessions
  vim.o.hidden = true -- Keep modified buffers in background

  -- Better completion experience
  vim.o.completeopt = 'menuone,noselect'

  -- Performance optimizations
  vim.o.updatetime = 250 -- Faster CursorHold events (default 4000ms)
  vim.o.timeoutlen = 300 -- Faster which-key popup (default 1000ms)
  vim.o.ttimeoutlen = 10 -- Faster escape sequences
  vim.o.redrawtime = 1500 -- Allow more time for syntax highlighting
  vim.o.synmaxcol = 240 -- Limit syntax highlighting to 240 columns
end

---Configure display and visual settings
local function setup_display()
  -- Line numbers
  vim.wo.number = true
  vim.wo.relativenumber = true
  vim.wo.signcolumn = 'yes' -- Always show sign column

  -- Cursor and navigation
  vim.opt.cursorline = true
  vim.o.scrolloff = 99999 -- Auto-center screen (extreme scrolloff)

  -- Text display
  vim.wo.wrap = false
  vim.wo.linebreak = true
  vim.wo.list = false
  vim.o.foldenable = false

  -- Status and UI
  vim.o.laststatus = 3 -- Global status line
  vim.o.termguicolors = true -- Enable 24-bit RGB colors
end

---Configure indentation and formatting
local function setup_indentation()
  vim.opt.tabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.softtabstop = 2
  vim.opt.expandtab = true
  vim.o.breakindent = true -- Maintain indent when wrapping
end

---Configure search behavior
local function setup_search()
  vim.o.ignorecase = true
  -- Note: vim.o.smartcase is intentionally disabled
  -- This forces case-insensitive search always
end

---Configure clipboard integration
local function setup_clipboard()
  vim.o.clipboard = 'unnamedplus'
  vim.opt.clipboard = 'unnamedplus'

  -- WSL-specific clipboard integration
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
end

---Configure performance and timing settings
local function setup_performance()
  -- Timing optimizations
  vim.o.updatetime = 250 -- Faster completion and diagnostics
  vim.o.timeoutlen = 300 -- Faster key sequence timeout
  vim.o.redrawtime = 1500 -- More time for complex syntax highlighting
  vim.o.lazyredraw = true -- Don't redraw during macros

  -- Memory optimizations
  vim.o.history = 1000 -- Reasonable command history size
  vim.o.maxmempattern = 20000 -- More memory for pattern matching
end

-- =============================================================================
-- Performance and Memory Optimizations
-- =============================================================================

---Configure performance and memory optimizations
local function setup_performance()
  -- File handling performance
  vim.o.swapfile = false -- Disable swap files for better performance
  vim.o.backup = false -- Disable backup files
  vim.o.writebackup = false -- Don't create backup before overwriting

  -- Memory and buffer optimizations
  vim.o.maxmempattern = 20000 -- Increase memory for pattern matching
  vim.o.history = 1000 -- Limit command history (default 10000)

  -- Lazy redraw for better performance during macros
  vim.o.lazyredraw = true

  -- Disable unnecessary providers for faster startup
  vim.g.loaded_python3_provider = 0
  vim.g.loaded_ruby_provider = 0
  vim.g.loaded_perl_provider = 0
  vim.g.loaded_node_provider = 0

  -- Faster diff algorithm
  vim.opt.diffopt:append('algorithm:patience')
  vim.opt.diffopt:append('indent-heuristic')

  -- Optimize fold performance
  vim.o.foldmethod = 'manual' -- Fastest folding method
  vim.o.foldlevelstart = 99 -- Start with all folds open

  -- Reduce regex engine usage for better performance
  vim.o.regexpengine = 0 -- Automatically select fastest engine

  -- Faster file type detection (these are set via vim commands)
  vim.cmd('filetype on')
  vim.cmd('filetype plugin on')
  vim.cmd('filetype indent on')
end

-- =============================================================================
-- Plugin-Specific Pre-Configuration
-- =============================================================================

---Configure plugin settings that must be set before plugin loading
local function setup_plugin_globals()
  -- Copilot: disable default tab mapping
  vim.g.copilot_no_tab_map = true

  -- Netrw: reverse sort order
  vim.g.netrw_sort_sequence = 'r'
end

-- =============================================================================
-- Diagnostic Configuration
-- =============================================================================

---Configure LSP diagnostic signs and display
local function setup_diagnostics()
  local signs = {
    { name = 'DiagnosticSignError', text = ' ' },
    { name = 'DiagnosticSignWarn', text = ' ' },
    { name = 'DiagnosticSignInfo', text = ' ' },
    { name = 'DiagnosticSignHint', text = '󰌵' },
  }

  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, {
      text = sign.text,
      texthl = sign.name,
    })
  end
end

-- =============================================================================
-- Custom Highlighting
-- =============================================================================

---Setup custom highlight groups
local function setup_highlights()
  -- Line number styling (using catppuccin-inspired colors)
  vim.api.nvim_set_hl(0, 'LineNrAbove', {
    fg = '#5e67a1',
    bold = true,
  })
  vim.api.nvim_set_hl(0, 'LineNrBelow', {
    fg = '#5e67a1',
    bold = true,
  })
end

-- =============================================================================
-- Initialization
-- =============================================================================

-- Execute all configuration functions in logical order
setup_editor_basics()
setup_display()
setup_indentation()
setup_search()
setup_clipboard()
setup_performance()
setup_plugin_globals()
setup_diagnostics()
setup_highlights()
