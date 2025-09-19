-- =============================================================================
-- Neovim Key Mappings Configuration
-- =============================================================================

local keymap = vim.keymap

local constants = require('core.constants')
local fileActions = require('custom.actions.files')
local todoistActions = require('custom.actions.todoist')
local linkActions = require('custom.actions.links')
local prompts = require('core.prompts')
local languageActions = require('custom.actions.language')
local errorsActions = require('custom.actions.errors')
local promptActions = require('custom.actions.prompt')
local checkboxActions = require('custom.actions.checkbox')
local replacementActions = require('custom.actions.replacement')
local storageActions = require('custom.actions.storage')
local lspActions = require('custom.actions.lsp')
local recentActions = require('custom.actions.recent')
local worktreeActions = require('custom.actions.worktree')

keymap.set('n', '<Leader>rL', todoistActions.repeatLastTodoistOptions(), { desc = '⟳ Repeat last Todoist options', silent = true })
keymap.set('n', '<Leader>rl', lspActions.refresh_all_lsps, { desc = '🔄 Refresh all LSPs', silent = true })

keymap.set('n', '<C-h>', '<C-W><C-H>', { desc = 'Move to left window' })
keymap.set('n', '<C-j>', '<C-W><C-J>', { desc = 'Move to bottom window' })
keymap.set('n', '<C-k>', '<C-W><C-K>', { desc = 'Move to top window' })
keymap.set('n', '<C-l>', '<C-W><C-L>', { desc = 'Move to right window' })
keymap.set('t', '<C-h>', '<C-W><C-H>', { desc = 'Move to left window from terminal' })
keymap.set('t', '<C-j>', '<C-W><C-J>', { desc = 'Move to bottom window from terminal' })
keymap.set('t', '<C-k>', '<C-W><C-K>', { desc = 'Move to top window from terminal' })
keymap.set('t', '<C-l>', '<C-W><C-L>', { desc = 'Move to right window from terminal' })
keymap.set('n', 'gj', ':cnext<CR>', { desc = 'Next quickfix item', silent = true, noremap = true })
keymap.set('n', 'gk', ':cprev<CR>', { desc = 'Previous quickfix item', silent = true, noremap = true })
keymap.set('n', 'gP', ':split<CR>', { desc = 'Horizontal split', silent = true })
keymap.set('n', 'gp', ':vsplit<CR>', { desc = 'Vertical split', silent = true })
keymap.set('v', 'ls', 'y:/<C-S-V>', { desc = 'Search selected text' })
keymap.set('', '<S-J>', '<C-D>', { desc = 'Scroll down half page' })
keymap.set('', '<S-K>', '<C-U>', { desc = 'Scroll up half page' })

-- ===============================
-- <leader>; Development & Code Tools
-- ===============================
keymap.set('n', '<leader>;da', languageActions.launch_android_emulator, { desc = '🤖 Launch Android emulator', silent = true, noremap = true })
keymap.set('n', '<leader>;de', languageActions.run_eslint, { desc = '🔍 Run ESLint quickfix', silent = true, noremap = true })
keymap.set('n', '<leader>;dc', errorsActions.copyDiagnosticUnderCursor, { desc = '📋 Copy diagnostic', silent = true, noremap = true })
keymap.set('n', '<leader>;df', languageActions.fix_and_organize_ts, { desc = '🔧 Fix and organize imports (TS)', silent = true, noremap = true })
keymap.set('n', '<leader>;dl', languageActions.repeatLastCommand, { desc = '⟳ Repeat last command', silent = true, noremap = true })

-- ===============================
-- <leader>; Git & GitHub Operations
-- ===============================
keymap.set('n', '<leader>;wt', worktreeActions.pull_and_rebase_all, { desc = '🔄 Pull develop & rebase all worktrees', silent = true, noremap = true })

-- ===============================
-- <leader>; File & System Operations
-- ===============================
keymap.set('n', '<Leader>;fc', fileActions.saveClipboardToFile, { desc = '💾 Save clipboard to file', silent = true, noremap = true })
keymap.set('n', '<Leader>;fr', fileActions.runClipboardCommand, { desc = '▶️  Run command from clipboard', silent = true, noremap = true })
keymap.set('n', '<leader>;ff', fileActions.copyAllFilesInFolder, { desc = '📁 Copy all files content', silent = true, noremap = true })
keymap.set('n', '<Leader>;fS', storageActions.sync_secrets_simple, { desc = '☁️  Sync secrets to cloud', silent = true, noremap = true })
keymap.set('n', '<Leader>;fI', storageActions.init_secrets_directory, { desc = '🔧 Initialize secrets directory', silent = true, noremap = true })
keymap.set('n', '<Leader>;fs', function() vim.cmd('set spell!') end, { desc = '📝 Toggle spellcheck', silent = true, noremap = true })
keymap.set('n', '<Leader>;fC', ':!rm -r ' .. constants.NEOVIM_STATE_DIR .. '<CR>', { desc = '🗑️  Clear swap files', silent = true, noremap = true })
keymap.set('n', '<Leader>;fG', ':!ln -sf ~/Programming/dotfiles/etc/.github/copilot-instructions.md ./.github/copilot-instructions.md<CR>', { desc = '🔗 Link .github from dotfiles (replace if exists)', silent = true, noremap = true })
keymap.set('n', '<leader>;fg', fileActions.grepInCurrentFolder, { desc = ' Grep in current folder', silent = true, noremap = true })
keymap.set('n', '<Leader>;v', recentActions.open_in_vscode_at_line, { desc = '󰨞 Open file in VS Code at line', silent = true, noremap = true })

-- ===============================
-- <leader>; Text & Content Operations
-- ===============================
keymap.set('x', '<leader>;tr', [["zy:%s/\V<C-r>=escape(@z, '/')<CR>//gc<left><left><left>]], { desc = '🔍 Visual search replace', silent = true, noremap = true })
keymap.set('n', '<leader>;tR', ':cdo %s///gc<left><left><left><left>', { desc = '🔄 CDO replace', silent = true, noremap = true })
keymap.set('n', '<leader>;tt', checkboxActions.toggle, { desc = '☑️  Toggle checkbox', silent = true, noremap = true })
keymap.set('v', '<leader>;tc', replacementActions.replace_text, { desc = '✏️  Replace text', silent = true, noremap = true })
keymap.set('v', '<leader>;tC', replacementActions.replace_text_cdo, { desc = '🔄 Replace text CDO', silent = true, noremap = true })

-- =============================================================================
-- Leader + h - AI, Help, and Search Operations
-- =============================================================================

keymap.set({ 'n', 'v' }, '<leader>ha', promptActions.openAiChat(), { desc = '  Open AI chat' })
keymap.set({ 'n', 'v' }, '<leader>hd', promptActions.getDiagnosticPrompt(), { desc = '🛑 Diagnostic prompt' })
keymap.set({ 'n', 'v' }, '<leader>hD', promptActions.getDiagnosticPrompt(true), { desc = '🛑 Diagnostic prompt with context' })
keymap.set({ 'n' }, '<leader>hff', promptActions.folderPrompt(), { desc = '  Copy folder prompt' })
keymap.set({ 'n' }, '<leader>hfa', promptActions.folderPrompt(prompts.accessibilityImproveReactPrompt), { desc = '♿ Copy accessibility prompt' })
keymap.set({ 'n' }, '<leader>hfi', promptActions.folderPrompt(prompts.testIdsPrompt), { desc = '󰀫 Copy TestId prompt' })
keymap.set({ 'n' }, '<leader>hfs', promptActions.folderPrompt(prompts.storyGeneratePrompt), { desc = ' Copy story prompt' })
keymap.set({ 'n', 'v' }, '<leader>hg', promptActions.searchGithub(vim.env.ORG_GITHUB_NAME), { desc = ' Search GitHub org' })
keymap.set({ 'n', 'v' }, '<leader>hG', promptActions.searchGithub(), { desc = ' Search GitHub' })
keymap.set({ 'n', 'v' }, '<leader>hh', promptActions.prompt(), { desc = '🤖 Random prompt' })
keymap.set({ 'n', 'v' }, '<leader>hH', promptActions.prompt(nil, true), { desc = '🤖 Random prompt with context' })
keymap.set({ 'n', 'v' }, '<leader>hm', promptActions.prompt(prompts.marketStatusPrompt), { desc = '📈 Market status' })
keymap.set({ 'n', 'v' }, '<leader>hn', promptActions.promptNews(), { desc = '📰 News' })
keymap.set({ 'n', 'v' }, '<leader>hr', promptActions.promptRole(prompts.promptRoles), { desc = '🎭 Role prompt' })
keymap.set({ 'n', 'v' }, '<leader>hR', promptActions.promptRole(prompts.promptRoles, true), { desc = '🎭 Role prompt with context' })
keymap.set({ 'n', 'v' }, '<leader>hs', promptActions.querySearchEngine(), { desc = ' Search web' })

-- =============================================================================
-- Leader + i/o - Jump Operations
-- =============================================================================

keymap.set('n', '<Leader>i', '<C-i>', { desc = ' Jump forward', silent = true })
keymap.set('n', '<Leader>o', '<C-o>', { desc = ' Jump backward', silent = true })

-- =============================================================================
-- Leader + l - Link Operations
-- =============================================================================

keymap.set('n', '<Leader>lc', linkActions.openContainerRegistry, { desc = '  Container registry', silent = true })
keymap.set('n', '<Leader>ld', linkActions.openTestPods, { desc = ' Test pods', silent = true })
keymap.set('n', '<Leader>lD', linkActions.openProdPods, { desc = ' Production pods', silent = true })
keymap.set('n', '<Leader>lg', linkActions.openGithubRepo, { desc = '󰊤 Open GitHub repo', silent = true })
keymap.set('n', '<Leader>ll', linkActions.openTestLogs, { desc = ' Test logs', silent = true })
keymap.set('n', '<Leader>lL', linkActions.openProdLogs, { desc = ' Production logs', silent = true })
keymap.set('n', '<Leader>lp', linkActions.openProdServer, { desc = '󰒋 Production server', silent = true })
keymap.set('n', '<Leader>ls', linkActions.openDevServer, { desc = '󰒋 Local server', silent = true })
keymap.set('n', '<Leader>lt', linkActions.openTestServer, { desc = '󰒋 Test server', silent = true })

-- =============================================================================
-- Leader + q/Q/w/W - File Operations (Basic)
-- =============================================================================

keymap.set('n', '<Leader>q', ':q<CR>', { desc = '󰩈 Quit', silent = true })
keymap.set('n', '<Leader>Q', ':qa!<CR>', { desc = '󰩈 Force quit all', silent = true })
keymap.set('n', '<Leader>w', ':w<CR>', { desc = ' Write', silent = true })
keymap.set('n', '<Leader>W', ':wa<CR>', { desc = ' Write all', silent = true })

-- =============================================================================
-- Leader + r - Logging Operations
-- =============================================================================

keymap.set('n', '<Leader>rr', todoistActions.logTodoistTask(), { desc = '󰎞 Log task (salmon)', silent = true })
keymap.set('n', '<Leader>rR', todoistActions.logTodoistTaskAllProjects(), { desc = '󰎞 Log task (all projects)', silent = true })
keymap.set('n', '<Leader>rR', todoistActions.refreshTodoistCache(), { desc = '󰑓 Refresh Todoist cache', silent = true })

keymap.set('n', '<Leader>ua', fileActions.moveFileToAsset('/Downloads'), { desc = ' Move to assets (Downloads)' })
keymap.set('n', '<Leader>uA', fileActions.moveFileToAsset('/Desktop'), { desc = ' Move to assets (Desktop)' })
keymap.set('n', '<Leader>uc', fileActions.openFileWithClipboard, { desc = ' Open file from clipboard', silent = true })
keymap.set('n', '<Leader>uj', linkActions.openJiraTicket, { desc = '󰌃 Open Jira ticket', silent = true })
keymap.set('n', '<Leader>ul', linkActions.openLinkedInJobs, { desc = '󰌻 LinkedIn jobs', silent = true })
keymap.set('n', '<Leader>un', linkActions.openNpmUrl, { desc = ' Open NPM link', silent = true })
keymap.set('n', '<Leader>uo', fileActions.openDir, { desc = ' Open directory', silent = true })
keymap.set('n', '<Leader>uu', linkActions.openUsefulLink, { desc = ' Open useful link', silent = true })

-- Open current file in VS Code at exact line (utility group)
keymap.set('n', '<Leader>;v', recentActions.open_in_vscode_at_line, {
  desc = '󰨞 Open file in VS Code at line',
  silent = true,
})

-- =============================================================================
-- Leader + z - Plugin Management (Lazy)
-- =============================================================================

keymap.set('n', '<leader>zc', ':Lazy clean<CR>', { desc = 'Lazy clean', silent = true })
keymap.set('n', '<leader>zh', ':Lazy health<CR>', { desc = 'Lazy health', silent = true })
keymap.set('n', '<leader>zp', ':Lazy profile<CR>', { desc = 'Lazy profile', silent = true })
keymap.set('n', '<leader>zr', ':Lazy restore<CR>', { desc = 'Lazy restore', silent = true })
keymap.set('n', '<leader>zu', ':Lazy update<CR>', { desc = 'Lazy update', silent = true })
keymap.set('n', '<leader>zz', ':Lazy<CR>', { desc = 'Open Lazy', silent = true })
