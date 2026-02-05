local constants = require('core.constants')
local fileActions = require('custom.actions.files')
local todoistActions = require('custom.actions.todoist')
local jiraActions = require('custom.actions.jira')
local linkActions = require('custom.actions.links')
local languageActions = require('custom.actions.language')
local errorsActions = require('custom.actions.errors')
local checkboxActions = require('custom.actions.checkbox')
local replacementActions = require('custom.actions.replacement')
local documentationActions = require('custom.actions.documentation')
local gitActions = require('custom.actions.git')
local editorActions = require('custom.actions.editor')
local bufferActions = require('custom.actions.buffers')

local function map(mode, lhs, rhs, opts)
  opts = vim.tbl_extend('force', { silent = true, noremap = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function maps(mode, mappings)
  for _, m in ipairs(mappings) do
    map(mode, m[1], m[2], { desc = m[3] })
  end
end

maps('n', {
  { '<C-h>', '<C-W><C-H>', 'Move to left window' },
  { '<C-j>', '<C-W><C-J>', 'Move to bottom window' },
  { '<C-k>', '<C-W><C-K>', 'Move to top window' },
  { '<C-l>', '<C-W><C-L>', 'Move to right window' },
  { ']', ':cnext<CR>', 'Next quickfix item' },
  { '[', ':cprev<CR>', 'Previous quickfix item' },
  { 'gP', ':split<CR>', 'Horizontal split' },
  { 'gp', ':vsplit<CR>', 'Vertical split' },
})

maps('t', {
  { '<C-h>', '<C-W><C-H>', 'Move to left window from terminal' },
  { '<C-j>', '<C-W><C-J>', 'Move to bottom window from terminal' },
  { '<C-k>', '<C-W><C-K>', 'Move to top window from terminal' },
  { '<C-l>', '<C-W><C-L>', 'Move to right window from terminal' },
})

map('', '<S-J>', '<C-D>', { desc = 'Scroll down half page' })
map('', '<S-K>', '<C-U>', { desc = 'Scroll up half page' })

maps('n', {
  { '<leader>nh', ':vsplit<CR>', 'Split window vertically (left)' },
  { '<leader>nj', ':split<CR><C-W>j', 'Split window horizontally (below)' },
  { '<leader>nk', ':split<CR>', 'Split window horizontally (above)' },
  { '<leader>nl', ':vsplit<CR><C-W>l', 'Split window vertically (right)' },
  { '<leader>nn', ':split<CR>', 'Split window horizontally' },
  { '<leader>nv', ':vsplit<CR>', 'Split window vertically' },
  { '<leader>nc', '<C-W>c', 'Close current window' },
  { '<leader>no', '<C-W>o', 'Close all other windows' },
  { '<leader>n=', '<C-W>=', 'Equalize window sizes' },
  { '<leader>n+', '<C-W>+', 'Increase window height' },
  { '<leader>n-', '<C-W>-', 'Decrease window height' },
  { '<leader>n>', '<C-W>>', 'Increase window width' },
  { '<leader>n<', '<C-W><', 'Decrease window width' },
})

maps('n', {
  { '<leader>bd', ':bdelete<CR>', 'Delete buffer' },
  { '<leader>bD', ':bdelete!<CR>', 'Force delete buffer' },
  { '<leader>bn', ':bnext<CR>', 'Next buffer' },
  { '<leader>bp', ':bprevious<CR>', 'Previous buffer' },
  { '<leader>bl', ':buffers<CR>', 'List buffers' },
  { '<leader>bo', ':%bdelete|edit#<CR>', 'Close all other buffers' },
  { '<leader>bw', ':w<CR>', 'Write buffer' },
  { '<leader>br', ':e!<CR>', 'Reload buffer' },
})

maps('n', {
  { '<leader>hx', ':tabclose<CR>', 'Delete tab' },
  { '<leader>ho', ':tabonly<CR>', 'Close all other tabs' },
  { '<leader>hk', ':tabnext<CR>', 'Next tab' },
  { '<leader>hj', ':tabprevious<CR>', 'Previous tab' },
  { '<leader>hl', ':tabs<CR>', 'List tabs' },
  { '<leader>hn', ':tabnew<CR>', 'Open new tab' },
  { '<leader>hm', ':tabmove<CR>', 'Move tab' },
  { '<leader>hf', ':tabfirst<CR>', 'First tab' },
  { '<leader>hL', ':tablast<CR>', 'Last tab' },
})

map('n', '<leader><leader>da', languageActions.launch_android_emulator, { desc = 'Launch Android emulator' })
map('n', '<leader><leader>df', languageActions.fix_and_organize_typescript_imports, { desc = 'Fix and organize imports (TS)' })
map('n', '<leader><leader>dr', languageActions.repeat_last_command, { desc = 'Repeat last command' })
map('n', '<leader><leader>ds', linkActions.open_dev_server, { desc = 'Development server' })
map('n', '<leader><leader>dw', ':SudaWrite<CR>', { desc = 'Sudo write' })

map('n', '<leader><leader>mc', documentationActions.add_convention_to_readme, { desc = 'Add convention to README' })

map('n', '<leader><leader>fc', fileActions.save_clipboard_to_file, { desc = 'Save clipboard to file' })
map('n', '<leader><leader>fr', fileActions.run_clipboard_command, { desc = 'Run command from clipboard' })
map('n', '<leader><leader>fs', editorActions.toggle_spellcheck, { desc = 'Toggle spellcheck' })
map('n', '<leader><leader>fC', ':!rm -r ' .. constants.NEOVIM_STATE_DIR .. '<CR>', { desc = 'Clear swap files' })
map('n', '<leader><leader>fG', fileActions.link_github_copilot_instructions, { desc = 'Link .github from dotfiles' })
map('n', '<leader><leader>fu', fileActions.copy_current_file_url, { desc = 'Copy file absolute URL' })

map('x', '<leader><leader>tr', [["zy:%s/\V<C-r>=escape(@z, '/')<CR>//gc<left><left><left>]], { desc = 'Visual search replace' })
map('n', '<leader>;;', checkboxActions.toggle, { desc = 'Toggle checkbox' })

map('n', '<leader>vc', fileActions.delete_all_comments, { desc = 'Delete all comments' })
map('n', '<leader>vC', fileActions.delete_comments_from_uncommitted_files, { desc = 'Delete comments from uncommitted files' })

map('n', '<leader>la', fileActions.copy_all_files_content, { desc = 'Copy all files content' })
map('n', '<leader>lu', fileActions.copy_current_file_url, { desc = 'Copy current file link' })
map('n', '<leader>lo', fileActions.copy_opencode_link, { desc = 'Copy OpenCode link' })
map('n', '<leader>ld', fileActions.open_current_dir, { desc = 'Open directory' })
map('n', '<leader>le', errorsActions.copy_diagnostic_under_cursor, { desc = 'Copy diagnostic' })
map('n', '<leader>lg', gitActions.openOrCreatePullRequest, { desc = 'Open existing PR or create new one' })
map('n', '<leader>lG', linkActions.open_current_github_repo, { desc = 'Open current GitHub repo' })
map('n', '<leader>lI', function() require('custom.actions.github').open_org_repo_by_folder() end, { desc = 'Open org repo by folder name' })
map('n', '<leader>lp', linkActions.open_current_github_prs, { desc = 'Open GitHub PRs tab' })
map('n', '<leader>lw', editorActions.toggle_wrap, { desc = 'Toggle text wrap' })
map('n', '<leader>ll', bufferActions.close_other_buffers_and_create_empty, { desc = 'Close other buffers and create empty buffer' })
map('n', '<leader>lt', '<cmd>Copilot toggle<CR>', { desc = 'Toggle Copilot autocomplete' })
map('n', '<leader>vx', languageActions.run_knip_fix_current_folder, { desc = 'Knip fix current folder' })
map('n', '<leader>vX', languageActions.run_knip_fix, { desc = 'Knip fix & remove files (global)' })

map('n', '<leader>ve', languageActions.run_eslint_picker, { desc = 'ESLint analysis picker' })
map('n', '<leader>vK', languageActions.run_knip_unused_files, { desc = 'Knip unused files' })
map('n', '<leader>vk', languageActions.run_knip_unused_code, { desc = 'Knip unused code' })

map('n', '<leader><leader>ri', replacementActions.replace_interactive, { desc = 'Interactive replace' })
map('n', '<leader><leader>rb', replacementActions.replace_buffer, { desc = 'Replace in buffer' })
map('n', '<leader><leader>rB', replacementActions.replace_buffer_all, { desc = 'Replace all in buffer' })
map('n', '<leader><leader>rp', replacementActions.replace_buffer_prefilled, { desc = 'Replace in buffer (prefilled)' })
map('n', '<leader><leader>rP', replacementActions.replace_buffer_all_prefilled, { desc = 'Replace all in buffer (prefilled)' })
map('v', '<leader><leader>rs', replacementActions.replace_buffer_selected, { desc = 'Replace selected in buffer' })
map('v', '<leader><leader>rS', replacementActions.replace_buffer_all_selected, { desc = 'Replace all selected in buffer' })
map('n', '<leader><leader>rq', replacementActions.replace_quickfix, { desc = 'Replace in quickfix' })
map('n', '<leader><leader>rQ', replacementActions.replace_quickfix_all, { desc = 'Replace all in quickfix' })
map('n', '<leader><leader>rf', replacementActions.replace_project, { desc = 'Replace in project' })
map('n', '<leader><leader>rF', replacementActions.replace_project_all, { desc = 'Replace all in project' })

map('n', '<Leader>i', '<C-i>', { desc = 'Jump forward' })
map('n', '<Leader>o', '<C-o>', { desc = 'Jump backward' })

map('n', '<Leader>q', ':q<CR>', { desc = 'Quit' })
map('n', '<Leader>Q', ':qa!<CR>', { desc = 'Force quit all' })
map('n', '<Leader>w', ':w<CR>', { desc = 'Write' })
map('n', '<Leader>W', ':wa<CR>', { desc = 'Write all' })

map('n', '<Leader>rr', todoistActions.log_todoist_task(), { desc = 'Log task (salmon)' })
map('n', '<Leader>rl', function() vim.notify('Leader rl - functionality not implemented yet') end, { desc = 'Link action (placeholder)' })
map('n', '<Leader>rR', todoistActions.log_todoist_task_all_projects(), { desc = 'Log task (all projects)' })
map('n', '<Leader>rC', todoistActions.refresh_todoist_cache(), { desc = 'Refresh Todoist cache' })

map('n', '<Leader>rj', jiraActions.create_jira_task(), { desc = 'Create Jira task' })
map('n', '<Leader>rL', jiraActions.create_jira_task_with_link(), { desc = 'Create Jira task + open link' })
map('n', '<Leader>rJ', jiraActions.refresh_jira_cache, { desc = 'Refresh Jira cache' })

maps('n', {
  { '<leader>zc', ':Lazy clean<CR>', 'Lazy clean' },
  { '<leader>zh', ':Lazy health<CR>', 'Lazy health' },
  { '<leader>zp', ':Lazy profile<CR>', 'Lazy profile' },
  { '<leader>zr', ':Lazy restore<CR>', 'Lazy restore' },
  { '<leader>zu', ':Lazy update<CR>', 'Lazy update' },
  { '<leader>zz', ':Lazy<CR>', 'Open Lazy' },
})

map('n', '<Leader>ttt', ':Typr<CR>', { desc = 'Start typing test' })
map('n', '<Leader>tts', ':TyprStats<CR>', { desc = 'Show typing stats' })

map('n', '<Leader>ua', fileActions.move_file_to_assets('/Downloads'), { desc = 'Move to assets (Downloads)' })
map('n', '<Leader>uA', fileActions.move_file_to_assets('/Desktop'), { desc = 'Move to assets (Desktop)' })
map('n', '<Leader>uj', linkActions.open_jira_ticket, { desc = 'Open Jira ticket' })

map('n', '<Leader>un', linkActions.open_npm_url, { desc = 'Open NPM link' })
map('n', '<Leader>uu', linkActions.open_useful_link, { desc = 'Open useful link' })
