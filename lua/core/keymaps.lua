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
local githubActions = require('custom.actions.github')

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

map('n', '<leader>nh', ':vsplit<CR>', { desc = 'Split window vertically (left)' })
map('n', '<leader>nj', ':split<CR><C-W>j', { desc = 'Split window horizontally (below)' })
map('n', '<leader>nk', ':split<CR>', { desc = 'Split window horizontally (above)' })
map('n', '<leader>nl', ':vsplit<CR><C-W>l', { desc = 'Split window vertically (right)' })
map('n', '<leader>nn', ':split<CR>', { desc = 'Split window horizontally' })
map('n', '<leader>nv', ':vsplit<CR>', { desc = 'Split window vertically' })
map('n', '<leader>nc', '<C-W>c', { desc = 'Close current window' })
map('n', '<leader>no', '<C-W>o', { desc = 'Close all other windows' })
map('n', '<leader>n=', '<C-W>=', { desc = 'Equalize window sizes' })
map('n', '<leader>n+', '<C-W>+', { desc = 'Increase window height' })
map('n', '<leader>n-', '<C-W>-', { desc = 'Decrease window height' })
map('n', '<leader>n>', '<C-W>>', { desc = 'Increase window width' })
map('n', '<leader>n<', '<C-W><', { desc = 'Decrease window width' })

map('n', '<leader>bd', ':bdelete<CR>', { desc = 'Delete buffer' })
map('n', '<leader>bD', ':bdelete!<CR>', { desc = 'Force delete buffer' })
map('n', '<leader>bn', ':bnext<CR>', { desc = 'Next buffer' })
map('n', '<leader>bp', ':bprevious<CR>', { desc = 'Previous buffer' })
map('n', '<leader>bl', ':buffers<CR>', { desc = 'List buffers' })
map('n', '<leader>bo', ':%bdelete|edit#<CR>', { desc = 'Close all other buffers' })
map('n', '<leader>bw', ':w<CR>', { desc = 'Write buffer' })
map('n', '<leader>br', ':e!<CR>', { desc = 'Reload buffer' })

map('n', '<leader>hx', ':tabclose<CR>', { desc = 'Delete tab' })
map('n', '<leader>ho', ':tabonly<CR>', { desc = 'Close all other tabs' })
map('n', '<leader>hk', ':tabnext<CR>', { desc = 'Next tab' })
map('n', '<leader>hj', ':tabprevious<CR>', { desc = 'Previous tab' })
map('n', '<leader>hl', ':tabs<CR>', { desc = 'List tabs' })
map('n', '<leader>hn', ':tabnew<CR>', { desc = 'Open new tab' })
map('n', '<leader>hm', ':tabmove<CR>', { desc = 'Move tab' })
map('n', '<leader>hf', ':tabfirst<CR>', { desc = 'First tab' })
map('n', '<leader>hL', ':tablast<CR>', { desc = 'Last tab' })

map('n', '<leader><leader>da', languageActions.launch_android_emulator, { desc = '🤖 Launch Android emulator' })
map('n', '<leader><leader>df', languageActions.fix_and_organize_typescript_imports, { desc = '🔧 Fix and organize imports (TS)' })
map('n', '<leader><leader>dr', languageActions.repeat_last_command, { desc = '⟳ Repeat last command' })
map('n', '<leader><leader>ds', linkActions.open_dev_server, { desc = '󰒋 Development server' })
map('n', '<leader><leader>dw', ':SudaWrite<CR>', { desc = '🔐 Sudo write' })

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

map('x', '<leader><leader>tr', [["zy:%s/\V<C-r>=escape(@z, '/')<CR>//gc<left><left><left>]], { desc = '🔍 Visual search replace' })
map('n', '<leader>;;', checkboxActions.toggle, { desc = '☑️  Toggle checkbox' })

map('n', '<leader>le', errorsActions.copy_diagnostic_under_cursor, { desc = '📋 Copy diagnostic' })
map('n', '<leader>lc', fileActions.copy_all_files_content, { desc = '📁 Copy all files content' })
map('n', '<leader>lC', fileActions.delete_all_comments, { desc = '🧹 Delete all comments' })
map('n', '<leader>lf', fileActions.copy_current_file_url, { desc = '🔗 Copy current file link' })
map('n', '<leader>ld', fileActions.open_current_dir, { desc = '📁 Open directory' })
map('n', '<leader>lg', gitActions.openOrCreatePullRequest, { desc = '🔗 Open existing PR or create new one' })
map('n', '<leader>lG', linkActions.open_current_github_repo, { desc = '󰊤 Open current GitHub repo' })
map('n', '<leader>l', linkActions.open_current_github_prs, { desc = '󰊤 Open GitHub PRs tab' })
map('n', '<leader>lp', linkActions.open_current_github_prs, { desc = '󰊤 Open GitHub PRs tab' })
map('n', '<leader>lw', function() vim.opt.wrap = not vim.opt.wrap:get() end, { desc = '↩️ Toggle text wrap' })
map('n', '<leader>ll', lspActions.refresh_all_lsps_silent, { desc = '🔄 Refresh all LSPs' })
map('n', '<leader>lt', '<cmd>Copilot toggle<CR>', { desc = '🤖 Toggle Copilot autocomplete' })

map('n', '<leader>lae', languageActions.run_eslint_picker, { desc = '🔍 ESLint analysis picker' })
map('n', '<leader>lak', languageActions.run_knip_picker, { desc = '🧹 Knip unused code picker' })

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

-- All AI prompt keybindings removed
-- =============================================================================

map('n', '<Leader>i', '<C-i>', { desc = 'Jump forward' })
map('n', '<Leader>o', '<C-o>', { desc = 'Jump backward' })

-- =============================================================================
-- Leader + i/o - Jump Operations
-- =============================================================================

map('n', '<Leader>q', ':q<CR>', { desc = '󰩈 Quit' })
map('n', '<Leader>Q', ':qa!<CR>', { desc = '󰩈 Force quit all' })
map('n', '<Leader>w', ':w<CR>', { desc = ' Write' })
map('n', '<Leader>W', ':wa<CR>', { desc = ' Write all' })

map('n', '<Leader>rr', todoistActions.log_todoist_task(), { desc = '󰎞 Log task (salmon)' })
map('n', '<Leader>rR', todoistActions.log_todoist_task_all_projects(), { desc = '󰎞 Log task (all projects)' })
map('n', '<Leader>rC', todoistActions.refresh_todoist_cache(), { desc = '󰑓 Refresh Todoist cache' })

map('n', '<leader>zc', ':Lazy clean<CR>', { desc = 'Lazy clean' })
map('n', '<leader>zh', ':Lazy health<CR>', { desc = 'Lazy health' })
map('n', '<leader>zp', ':Lazy profile<CR>', { desc = 'Lazy profile' })
map('n', '<leader>zr', ':Lazy restore<CR>', { desc = 'Lazy restore' })
map('n', '<leader>zu', ':Lazy update<CR>', { desc = 'Lazy update' })
map('n', '<leader>zz', ':Lazy<CR>', { desc = 'Open Lazy' })

-- Note: LeetCode keymaps are configured in lua/plugins/leetcode.lua for better organization

-- Typing practice
map('n', '<Leader>ttt', ':Typr<CR>', { desc = '󰗀 Start typing test' })
map('n', '<Leader>tts', ':TyprStats<CR>', { desc = '󰄨 Show typing stats' })

map('n', '<Leader>ua', fileActions.move_file_to_assets('/Downloads'), { desc = ' Move to assets (Downloads)' })
map('n', '<Leader>uA', fileActions.move_file_to_assets('/Desktop'), { desc = ' Move to assets (Desktop)' })
map('n', '<Leader>uj', linkActions.open_jira_ticket, { desc = '󰌃 Open Jira ticket', silent = true })

map('n', '<Leader>un', linkActions.open_npm_url, { desc = ' Open NPM link', silent = true })
map('n', '<Leader>uu', linkActions.open_useful_link, { desc = ' Open useful link', silent = true })
