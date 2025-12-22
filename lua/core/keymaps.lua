-- =============================================================================
-- Neovim Key Mappings Configuration
-- =============================================================================

local keymap = vim.keymap

local constants = require('core.constants')
local fileActions = require('custom.actions.files')
local todoistActions = require('custom.actions.todoist')
local linkActions = require('custom.actions.links')
local languageActions = require('custom.actions.language')
local errorsActions = require('custom.actions.errors')
local checkboxActions = require('custom.actions.checkbox')
local replacementActions = require('custom.actions.replacement')
local lspActions = require('custom.actions.lsp')
local documentationActions = require('custom.actions.documentation')
local gitActions = require('custom.actions.git')

-- Helper to set keymaps with silent and noremap by default
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = true
  opts.noremap = true
  keymap.set(mode, lhs, rhs, opts)
end

-- Window & Navigation
map('n', '<C-h>', '<C-W><C-H>', { desc = 'Move to left window' })
map('n', '<C-j>', '<C-W><C-J>', { desc = 'Move to bottom window' })
map('n', '<C-k>', '<C-W><C-K>', { desc = 'Move to top window' })
map('n', '<C-l>', '<C-W><C-L>', { desc = 'Move to right window' })
map('t', '<C-h>', '<C-W><C-H>', { desc = 'Move to left window from terminal' })
map('t', '<C-j>', '<C-W><C-J>', { desc = 'Move to bottom window from terminal' })
map('t', '<C-k>', '<C-W><C-K>', { desc = 'Move to top window from terminal' })
map('t', '<C-l>', '<C-W><C-L>', { desc = 'Move to right window from terminal' })
map('n', ']', ':cnext<CR>', { desc = 'Next quickfix item', noremap = true })
map('n', '[', ':cprev<CR>', { desc = 'Previous quickfix item', noremap = true })
map('n', 'gP', ':split<CR>', { desc = 'Horizontal split' })
map('n', 'gp', ':vsplit<CR>', { desc = 'Vertical split' })
map('', '<S-J>', '<C-D>', { desc = 'Scroll down half page' })
map('', '<S-K>', '<C-U>', { desc = 'Scroll up half page' })

-- ===============================
-- <leader><leader>d - Development & Code Tools
-- ===============================
map('n', '<leader><leader>da', languageActions.launch_android_emulator, { desc = '🤖 Launch Android emulator' })
map('n', '<leader><leader>df', languageActions.fix_and_organize_typescript_imports, { desc = '🔧 Fix and organize imports (TS)' })
map('n', '<leader><leader>dr', languageActions.repeat_last_command, { desc = '⟳ Repeat last command' })
map('n', '<leader><leader>ds', linkActions.open_dev_server, { desc = '󰒋 Development server' })
map('n', '<leader><leader>dw', ':SudaWrite<CR>', { desc = '🔐 Sudo write' })

-- ===============================
-- <leader><leader>m - Documentation & Manual
-- ===============================
map('n', '<leader><leader>mc', documentationActions.add_convention_to_readme, { desc = '📖 Add convention to README' })

-- ===============================
-- <leader><leader>f - File & System Operations
-- ===============================
map('n', '<leader><leader>fc', fileActions.save_clipboard_to_file, { desc = '💾 Save clipboard to file' })
map('n', '<leader><leader>fr', fileActions.run_clipboard_command, { desc = '▶️  Run command from clipboard' })
map('n', '<leader><leader>fs', function() vim.cmd('set spell!') end, { desc = '📝 Toggle spellcheck' })
map('n', '<leader><leader>fC', ':!rm -r ' .. constants.NEOVIM_STATE_DIR .. '<CR>', { desc = '🗑️  Clear swap files' })
map('n', '<leader><leader>fG', fileActions.link_github_copilot_instructions, { desc = '🔗 Link .github from dotfiles' })
map('n', '<leader><leader>fu', fileActions.copy_current_file_url, { desc = '🔗 Copy file absolute URL' })

-- ===============================
-- <leader><leader>t - Text & Content Operations
-- ===============================
map('x', '<leader><leader>tr', [["zy:%s/\V<C-r>=escape(@z, '/')<CR>//gc<left><left><left>]], { desc = '🔍 Visual search replace' })
map('n', '<leader>;;', checkboxActions.toggle, { desc = '☑️  Toggle checkbox' })

-- ===============================
-- <leader>; - Misc Quick Access
-- ===============================
map('n', '<leader>;e', errorsActions.copy_diagnostic_under_cursor, { desc = '📋 Copy diagnostic' })
map('n', '<leader>;c', fileActions.copy_all_files_content, { desc = '📁 Copy all files content' })
map('n', '<leader>;f', fileActions.copy_current_file_url, { desc = '🔗 Copy current file link' })
map('n', '<leader>;d', fileActions.open_current_dir, { desc = '📁 Open directory' })
map('n', '<leader>;g', linkActions.open_current_github_repo, { desc = '󰊤 Open current GitHub repo' })
map('n', '<leader>;G', linkActions.open_current_github_prs, { desc = '󰊤 Open GitHub PRs tab' })
map('n', '<leader>;p', gitActions.openExistingPullRequestOnly, { desc = '🔗 Open existing PR link' })
map('n', '<leader>;w', function() vim.opt.wrap = not vim.opt.wrap:get() end, { desc = '↩️ Toggle text wrap' })
map('n', '<leader>;l', lspActions.refresh_all_lsps_silent, { desc = '🔄 Refresh all LSPs' })
map('n', '<leader>;t', '<cmd>Copilot toggle<CR>', { desc = '🤖 Toggle Copilot autocomplete' })

-- ===============================
-- <leader>f; - Find & Analysis Operations
-- ===============================
map('n', '<leader>f;e', languageActions.run_eslint_picker, { desc = '🔍 ESLint analysis picker' })
map('n', '<leader>f;k', languageActions.run_knip_picker, { desc = '🧹 Knip unused code picker' })

-- ===============================
-- <leader><leader>r - Replacement Operations
-- ===============================
map('n', '<leader><leader>ri', replacementActions.replace_interactive, { desc = '🎯 Interactive replace' })
map('n', '<leader><leader>rb', replacementActions.replace_buffer, { desc = '📄 Replace in buffer' })
map('n', '<leader><leader>rB', replacementActions.replace_buffer_all, { desc = '📄 Replace all in buffer' })
map('n', '<leader><leader>rp', replacementActions.replace_buffer_prefilled, { desc = '📝 Replace in buffer (prefilled)' })
map('n', '<leader><leader>rP', replacementActions.replace_buffer_all_prefilled, { desc = '📝 Replace all in buffer (prefilled)' })
map('v', '<leader><leader>rs', replacementActions.replace_buffer_selected, { desc = '✂️  Replace selected in buffer' })
map('v', '<leader><leader>rS', replacementActions.replace_buffer_all_selected, { desc = '✂️  Replace all selected in buffer' })
map('n', '<leader><leader>rq', replacementActions.replace_quickfix, { desc = '📋 Replace in quickfix' })
map('n', '<leader><leader>rQ', replacementActions.replace_quickfix_all, { desc = '📋 Replace all in quickfix' })
map('n', '<leader><leader>rf', replacementActions.replace_project, { desc = '🌐 Replace in project' })
map('n', '<leader><leader>rF', replacementActions.replace_project_all, { desc = '🌐 Replace all in project' })

-- =============================================================================
-- Leader + h - Help Operations (AI prompt functionality removed)
-- =============================================================================

-- All AI prompt keybindings removed

-- =============================================================================
-- Leader + i/o - Jump Operations
-- =============================================================================

map('n', '<Leader>i', '<C-i>', { desc = 'Jump forward' })
map('n', '<Leader>o', '<C-o>', { desc = 'Jump backward' })

-- =============================================================================
-- Leader + l - Link Operations
-- =============================================================================

map('n', '<Leader>lc', linkActions.open_container_registry, { desc = 'Container registry' })
map('n', '<Leader>ld', linkActions.open_test_pods, { desc = 'Test pods' })
map('n', '<Leader>lD', linkActions.open_prod_pods, { desc = 'Production pods' })
map('n', '<Leader>lg', linkActions.open_github_repo, { desc = '󰊤 Open GitHub repo' })
map('n', '<Leader>ll', linkActions.open_test_logs, { desc = 'Test logs' })
map('n', '<Leader>lL', linkActions.open_prod_logs, { desc = 'Production logs' })
map('n', '<Leader>lp', linkActions.open_prod_server, { desc = '󰒋 Production server' })
map('n', '<Leader>lt', linkActions.open_test_server, { desc = '󰒋 Test server' })

-- =============================================================================
-- Leader + q/Q/w/W - File Operations (Basic)
-- =============================================================================

map('n', '<Leader>q', ':q<CR>', { desc = '󰩈 Quit' })
map('n', '<Leader>Q', ':qa!<CR>', { desc = '󰩈 Force quit all' })
map('n', '<Leader>w', ':w<CR>', { desc = ' Write' })
map('n', '<Leader>W', ':wa<CR>', { desc = ' Write all' })

-- =============================================================================
-- Leader + r - Logging Operations
-- =============================================================================

map('n', '<Leader>rr', todoistActions.log_todoist_task(), { desc = '󰎞 Log task (salmon)' })
map('n', '<Leader>rR', todoistActions.log_todoist_task_all_projects(), { desc = '󰎞 Log task (all projects)' })
map('n', '<Leader>rC', todoistActions.refresh_todoist_cache(), { desc = '󰑓 Refresh Todoist cache' })

-- =============================================================================
-- Leader + z - Plugin Management (Lazy)
-- =============================================================================

map('n', '<leader>zc', ':Lazy clean<CR>', { desc = 'Lazy clean' })
map('n', '<leader>zh', ':Lazy health<CR>', { desc = 'Lazy health' })
map('n', '<leader>zp', ':Lazy profile<CR>', { desc = 'Lazy profile' })
map('n', '<leader>zr', ':Lazy restore<CR>', { desc = 'Lazy restore' })
map('n', '<leader>zu', ':Lazy update<CR>', { desc = 'Lazy update' })
map('n', '<leader>zz', ':Lazy<CR>', { desc = 'Open Lazy' })

-- =============================================================================
-- Leader + b - Buffer Management (barbar.nvim)
-- =============================================================================

-- Buffer navigation
map('n', '<Leader>bp', '<Cmd>BufferPrevious<CR>', { desc = '󰒮 Previous buffer' })
map('n', '<Leader>bn', '<Cmd>BufferNext<CR>', { desc = '󰒭 Next buffer' })
map('n', '<Leader>bP', '<Cmd>BufferMovePrevious<CR>', { desc = '󰜲 Move buffer left' })
map('n', '<Leader>bN', '<Cmd>BufferMoveNext<CR>', { desc = '󰜵 Move buffer right' })

-- Buffer selection by position
map('n', '<Leader>b1', '<Cmd>BufferGoto 1<CR>', { desc = '󰲠 Go to buffer 1' })
map('n', '<Leader>b2', '<Cmd>BufferGoto 2<CR>', { desc = '󰲢 Go to buffer 2' })
map('n', '<Leader>b3', '<Cmd>BufferGoto 3<CR>', { desc = '󰲤 Go to buffer 3' })
map('n', '<Leader>b4', '<Cmd>BufferGoto 4<CR>', { desc = '󰲦 Go to buffer 4' })
map('n', '<Leader>b5', '<Cmd>BufferGoto 5<CR>', { desc = '󰲨 Go to buffer 5' })
map('n', '<Leader>b6', '<Cmd>BufferGoto 6<CR>', { desc = '󰲪 Go to buffer 6' })
map('n', '<Leader>b7', '<Cmd>BufferGoto 7<CR>', { desc = '󰲬 Go to buffer 7' })
map('n', '<Leader>b8', '<Cmd>BufferGoto 8<CR>', { desc = '󰲮 Go to buffer 8' })
map('n', '<Leader>b9', '<Cmd>BufferGoto 9<CR>', { desc = '󰲰 Go to buffer 9' })
map('n', '<Leader>bl', '<Cmd>BufferLast<CR>', { desc = '󰘁 Go to last buffer' })

-- Buffer management
map('n', '<Leader>bc', '<Cmd>BufferClose<CR>', { desc = '󰅖 Close buffer' })
map('n', '<Leader>bC', '<Cmd>BufferRestore<CR>', { desc = '󰁯 Restore buffer' })
map('n', '<Leader>bw', '<Cmd>BufferWipeout<CR>', { desc = '󰩺 Wipeout buffer' })
map('n', '<Leader>bpin', '<Cmd>BufferPin<CR>', { desc = '󰐃 Pin/unpin buffer' })

-- Buffer operations
map('n', '<Leader>bpick', '<Cmd>BufferPick<CR>', { desc = '󰒉 Pick buffer' })
map('n', '<Leader>bpd', '<Cmd>BufferPickDelete<CR>', { desc = '󰒉 Pick delete buffer' })

-- Close operations
map('n', '<Leader>bca', '<Cmd>BufferCloseAllButCurrent<CR>', { desc = '󰅗 Close all but current' })
map('n', '<Leader>bcv', '<Cmd>BufferCloseAllButVisible<CR>', { desc = '󰅗 Close all but visible' })
map('n', '<Leader>bcp', '<Cmd>BufferCloseAllButPinned<CR>', { desc = '󰅗 Close all but pinned' })
map('n', '<Leader>bcc', '<Cmd>BufferCloseAllButCurrentOrPinned<CR>', { desc = '󰅗 Close all but current/pinned' })
map('n', '<Leader>bcl', '<Cmd>BufferCloseBuffersLeft<CR>', { desc = '󰅖 Close buffers left' })
map('n', '<Leader>bcr', '<Cmd>BufferCloseBuffersRight<CR>', { desc = '󰅖 Close buffers right' })

-- Sort operations
map('n', '<Leader>bsn', '<Cmd>BufferOrderByName<CR>', { desc = '󰒺 Sort by name' })
map('n', '<Leader>bsd', '<Cmd>BufferOrderByDirectory<CR>', { desc = '󰉋 Sort by directory' })
map('n', '<Leader>bsl', '<Cmd>BufferOrderByLanguage<CR>', { desc = '󰗊 Sort by language' })
map('n', '<Leader>bsw', '<Cmd>BufferOrderByWindowNumber<CR>', { desc = '󰖲 Sort by window' })
map('n', '<Leader>bsb', '<Cmd>BufferOrderByBufferNumber<CR>', { desc = '󰎕 Sort by buffer number' })

-- =============================================================================
-- Leader + t - Training & Productivity
-- =============================================================================
-- Note: LeetCode keymaps are configured in lua/plugins/leetcode.lua for better organization

-- Typing practice
map('n', '<Leader>ttt', ':Typr<CR>', { desc = '󰗀 Start typing test' })
map('n', '<Leader>tts', ':TyprStats<CR>', { desc = '󰄨 Show typing stats' })

-- =============================================================================
-- Leader + u - File & Link Operations (Advanced)
-- =============================================================================
map('n', '<Leader>ua', fileActions.move_file_to_assets('/Downloads'), { desc = ' Move to assets (Downloads)' })
map('n', '<Leader>uA', fileActions.move_file_to_assets('/Desktop'), { desc = ' Move to assets (Desktop)' })
map('n', '<Leader>uj', linkActions.open_jira_ticket, { desc = '󰌃 Open Jira ticket', silent = true })

map('n', '<Leader>un', linkActions.open_npm_url, { desc = ' Open NPM link', silent = true })
map('n', '<Leader>uu', linkActions.open_useful_link, { desc = ' Open useful link', silent = true })
