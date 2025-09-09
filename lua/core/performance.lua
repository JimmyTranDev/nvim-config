-- Performance optimizations for Neovim startup
-- These settings help improve startup time and general performance

-- Disable built-in plugins we don't need
vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1

-- Disable additional built-in plugins for better startup
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_fzf = 1
vim.g.loaded_man = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_remote_plugins = 1

-- Faster file operations
vim.opt.lazyredraw = false -- Don't redraw during macros (but keep false for better UX)
vim.opt.ttyfast = true -- Fast terminal connection
vim.opt.updatetime = 200 -- Faster CursorHold events
vim.opt.redrawtime = 1500 -- Time in milliseconds for redrawing the display

-- Reduce timeouts for better responsiveness
vim.opt.timeout = true
vim.opt.timeoutlen = 300 -- Time to wait for mapped sequence
vim.opt.ttimeoutlen = 10 -- Time to wait for key code sequence

-- Better memory usage and performance
vim.opt.hidden = true -- Allow buffers to be hidden
vim.opt.history = 1000 -- Reasonable history size
vim.opt.undolevels = 1000 -- Reasonable undo levels
vim.opt.maxmempattern = 2000 -- Maximum memory used for pattern matching

-- Faster completion and search
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.shortmess:append('c') -- Don't show completion messages
vim.opt.shortmess:append('I') -- Don't show intro message
vim.opt.shortmess:append('W') -- Don't show "written" when writing a file
vim.opt.shortmess:append('A') -- Don't show "ATTENTION" message
vim.opt.wildmenu = true
vim.opt.wildmode = 'longest:full,full' -- Better command-line completion

-- Improve syntax and highlighting performance
vim.opt.synmaxcol = 500 -- Only highlight first 500 columns
vim.opt.regexpengine = 1 -- Use old regexp engine (sometimes faster)

-- File handling optimizations
vim.opt.swapfile = false -- Disable swap files for better performance
vim.opt.backup = false -- Disable backup files
vim.opt.writebackup = false -- Disable backup before writing
vim.opt.autoread = true -- Automatically read changed files
vim.opt.autowrite = true -- Automatically write files when switching buffers

-- Improve scrolling performance
vim.opt.scrolljump = 1 -- Lines to scroll when cursor leaves screen
vim.opt.scrolloff = 3 -- Lines to keep above and below cursor
vim.opt.sidescrolloff = 5 -- Columns to keep to the left and right of cursor

-- Disable providers we don't use (if you don't need them)
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
-- Keep node provider if you use it
-- vim.g.loaded_node_provider = 0

-- LSP Performance optimizations
vim.lsp.set_log_level('WARN') -- Reduce LSP logging
-- Disable semantic tokens for better performance (uncomment if needed)
-- vim.api.nvim_create_autocmd("LspAttach", {
--   callback = function(args)
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--     if client then
--       client.server_capabilities.semanticTokensProvider = nil
--     end
--   end,
-- })

-- Improve diff performance
vim.opt.diffopt:append('algorithm:patience')
vim.opt.diffopt:append('indent-heuristic')

-- Better grep performance if using internal grep
if vim.fn.executable('rg') == 1 then
  vim.opt.grepprg = 'rg --vimgrep --smart-case --follow'
  vim.opt.grepformat = '%f:%l:%c:%m'
elseif vim.fn.executable('ag') == 1 then
  vim.opt.grepprg = 'ag --nogroup --nocolor --vimgrep'
  vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
end

-- Disable syntax highlighting for large files
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    if vim.fn.line('$') > 5000 then
      vim.cmd('syntax clear')
      vim.opt_local.foldmethod = 'manual'
      vim.opt_local.spell = false
    end
  end,
})

-- Optimize treesitter for large files
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local file_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))

    -- Disable treesitter for files larger than 1MB
    if file_size > 1024 * 1024 then vim.schedule(function() vim.treesitter.stop(buf) end) end
  end,
})

-- Improve startup by deferring some settings
vim.defer_fn(function()
  -- Enable clipboard after startup
  vim.opt.clipboard = 'unnamedplus'

  -- Set up folding method after startup
  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
  vim.opt.foldlevelstart = 99

  -- Additional post-startup optimizations can go here
end, 0)

-- Cache compiled lua modules for faster startup
if vim.loader and vim.fn.has('nvim-0.9.1') == 1 then vim.loader.enable() end
