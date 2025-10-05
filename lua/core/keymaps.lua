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
local documentationActions = require('custom.actions.documentation')

-- Helper to set keymaps with silent and noremap by default
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = true
  opts.noremap = true
  keymap.set(mode, lhs, rhs, opts)
end

keymap.set('n', '<Leader>rl', lspActions.refresh_all_lsps, { desc = '🔄 Refresh all LSPs', silent = true })

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
-- <leader>; Development & Code Tools
-- ===============================
map('n', '<leader>;da', languageActions.launch_android_emulator, { desc = '🤖 Launch Android emulator' })
map('n', '<leader>;de', languageActions.run_eslint, { desc = '🔍 Run ESLint quickfix' })
map('n', '<leader>;dc', errorsActions.copyDiagnosticUnderCursor, { desc = '📋 Copy diagnostic' })
map('n', '<leader>;df', languageActions.fix_and_organize_ts, { desc = '🔧 Fix and organize imports (TS)' })
map('n', '<leader>;dl', languageActions.repeatLastCommand, { desc = '⟳ Repeat last command' })

-- ===============================
-- <leader>;m Documentation & Notes
-- ===============================
map('n', '<leader>;mc', documentationActions.addConventionToReadme, { desc = '📖 Add convention to README' })

-- ===============================
-- <leader>; File & System Operations
-- ===============================
map('n', '<Leader>;fc', fileActions.saveClipboardToFile, { desc = '💾 Save clipboard to file' })
map('n', '<Leader>;fr', fileActions.runClipboardCommand, { desc = '▶️  Run command from clipboard' })
map('n', '<leader>;ff', fileActions.copyAllFilesInFolder, { desc = '📁 Copy all files content' })
map('n', '<Leader>;fS', storageActions.sync_secrets_simple, { desc = '☁️  Sync secrets to cloud' })
map('n', '<Leader>;fI', storageActions.init_secrets_directory, { desc = '🔧 Initialize secrets directory' })
map('n', '<Leader>;fs', function() vim.cmd('set spell!') end, { desc = '📝 Toggle spellcheck' })
map('n', '<Leader>;fC', ':!rm -r ' .. constants.NEOVIM_STATE_DIR .. '<CR>', { desc = '🗑️  Clear swap files' })
map(
  'n',
  '<Leader>;fG',
  ':!ln -sf ~/Programming/dotfiles/etc/.github/copilot-instructions.md ./.github/copilot-instructions.md<CR>',
  { desc = '🔗 Link .github from dotfiles (replace if exists)' }
)

-- ===============================
-- <leader>; Text & Content Operations
-- ===============================
map('x', '<leader>;tr', [["zy:%s/\V<C-r>=escape(@z, '/')<CR>//gc<left><left><left>]], { desc = '🔍 Visual search replace' })
map('n', '<leader>;tR', ':cdo %s///gc<left><left><left><left>', { desc = '🔄 CDO replace' })
map('n', '<leader>;tt', checkboxActions.toggle, { desc = '☑️  Toggle checkbox' })
map('v', '<leader>;tc', replacementActions.replace_text, { desc = '✏️  Replace text' })
map('v', '<leader>;tC', replacementActions.replace_text_cdo, { desc = '🔄 Replace text CDO' })

-- =============================================================================
-- Leader + h - AI, Help, and Search Operations
-- =============================================================================

map({ 'n', 'v' }, '<leader>ha', promptActions.openAiChat(), { desc = 'Open AI chat' })
map({ 'n', 'v' }, '<leader>hd', promptActions.getDiagnosticPrompt(), { desc = '🛑 Diagnostic prompt' })
map({ 'n', 'v' }, '<leader>hD', promptActions.getDiagnosticPrompt(true), { desc = '🛑 Diagnostic prompt with context' })
map({ 'n', 'v' }, '<leader>hg', promptActions.searchGithub(vim.env.ORG_GITHUB_NAME), { desc = 'Search GitHub org' })
map({ 'n', 'v' }, '<leader>hG', promptActions.searchGithub(), { desc = 'Search GitHub' })
map('n', '<leader>hff', promptActions.folderPrompt(), { desc = 'Copy folder prompt' })
map({ 'n', 'v' }, '<leader>hh', promptActions.prompt(), { desc = '🤖 Random prompt' })
map({ 'n', 'v' }, '<leader>hH', promptActions.prompt(nil, true), { desc = '🤖 Random prompt with context' })
map({ 'n', 'v' }, '<leader>hr', promptActions.promptRole(prompts.promptRoles), { desc = '🎭 Role prompt' })
map({ 'n', 'v' }, '<leader>hR', promptActions.promptRole(prompts.promptRoles, true), { desc = '🎭 Role prompt with context' })
map({ 'n', 'v' }, '<leader>hs', promptActions.querySearchEngine(), { desc = 'Search web' })

-- =============================================================================
-- Leader + i/o - Jump Operations
-- =============================================================================

map('n', '<Leader>i', '<C-i>', { desc = 'Jump forward' })
map('n', '<Leader>o', '<C-o>', { desc = 'Jump backward' })

-- =============================================================================
-- Leader + l - Link Operations
-- =============================================================================

map('n', '<Leader>lc', linkActions.openContainerRegistry, { desc = 'Container registry' })
map('n', '<Leader>ld', linkActions.openTestPods, { desc = 'Test pods' })
map('n', '<Leader>lD', linkActions.openProdPods, { desc = 'Production pods' })
map('n', '<Leader>lg', linkActions.openGithubRepo, { desc = '󰊤 Open GitHub repo' })
map('n', '<Leader>ll', linkActions.openTestLogs, { desc = 'Test logs' })
map('n', '<Leader>lL', linkActions.openProdLogs, { desc = 'Production logs' })
map('n', '<Leader>lp', linkActions.openProdServer, { desc = '󰒋 Production server' })
map('n', '<Leader>ls', linkActions.openDevServer, { desc = '󰒋 Local server' })
map('n', '<Leader>lt', linkActions.openTestServer, { desc = '󰒋 Test server' })

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

map('n', '<Leader>rr', todoistActions.logTodoistTask(), { desc = '󰎞 Log task (salmon)' })
map('n', '<Leader>rR', todoistActions.logTodoistTaskAllProjects(), { desc = '󰎞 Log task (all projects)' })
map('n', '<Leader>rC', todoistActions.refreshTodoistCache(), { desc = '󰑓 Refresh Todoist cache' })

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
-- Leader + u - File & Link Operations (Advanced)
-- =============================================================================
map('n', '<Leader>ua', fileActions.moveFileToAsset('/Downloads'), { desc = ' Move to assets (Downloads)' })
map('n', '<Leader>uA', fileActions.moveFileToAsset('/Desktop'), { desc = ' Move to assets (Desktop)' })
map('n', '<Leader>uc', fileActions.openFileWithClipboard, { desc = ' Open file from clipboard', silent = true })
map('n', '<Leader>uj', linkActions.openJiraTicket, { desc = '󰌃 Open Jira ticket', silent = true })
map('n', '<Leader>ul', linkActions.openLinkedInJobs, { desc = '󰌻 LinkedIn jobs', silent = true })
map('n', '<Leader>un', linkActions.openNpmUrl, { desc = ' Open NPM link', silent = true })
map('n', '<Leader>uo', fileActions.openDir, { desc = ' Open directory', silent = true })
map('n', '<Leader>uu', linkActions.openUsefulLink, { desc = ' Open useful link', silent = true })
