local constants = require('core.constants')
local file_actions = require('custom.actions.files')
local todoist_actions = require('custom.actions.todoist')
local jira_actions = require('custom.actions.jira')
local link_actions = require('custom.actions.links')
local language_actions = require('custom.actions.language')
local errors_actions = require('custom.actions.errors')
local checkbox_actions = require('custom.actions.checkbox')
local replacement_actions = require('custom.actions.replacement')
local documentation_actions = require('custom.actions.documentation')
local git_actions = require('custom.actions.git')
local github_actions = require('custom.actions.github')
local editor_actions = require('custom.actions.editor')
local buffer_actions = require('custom.actions.buffers')
local journal_actions = require('custom.actions.journal')
local notes_actions = require('custom.actions.notes')

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
  { '<A-=>', '<C-W>=', 'Equalize window sizes' },
  { '<A-Up>', '<C-W>+', 'Increase window height' },
  { '<A-Down>', '<C-W>-', 'Decrease window height' },
  { '<A-Right>', '<C-W>>', 'Increase window width' },
  { '<A-Left>', '<C-W><', 'Decrease window width' },
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

map('n', '<leader><leader>da', language_actions.launch_android_emulator, { desc = 'Launch Android emulator' })
map('n', '<leader><leader>df', language_actions.fix_and_organize_typescript_imports, { desc = 'Fix and organize imports (TS)' })
map('n', '<leader><leader>dr', language_actions.repeat_last_command, { desc = 'Repeat last command' })
map('n', '<leader><leader>ds', link_actions.open_dev_server, { desc = 'Development server' })
map('n', '<leader><leader>dw', ':SudaWrite<CR>', { desc = 'Sudo write' })

map('n', '<leader><leader>mc', documentation_actions.add_convention_to_readme, { desc = 'Add convention to README' })

map('n', '<leader><leader>fc', file_actions.save_clipboard_to_file, { desc = 'Save clipboard to file' })
map('n', '<leader>;fM', file_actions.convert_md_to_pdf, { desc = 'Convert markdown to PDF' })
map('n', '<leader><leader>fr', file_actions.run_clipboard_command, { desc = 'Run command from clipboard' })
map('n', '<leader><leader>fs', editor_actions.toggle_spellcheck, { desc = 'Toggle spellcheck' })
map('n', '<leader><leader>fC', ':!rm -r ' .. constants.NEOVIM_STATE_DIR .. '<CR>', { desc = 'Clear swap files' })
map('n', '<leader><leader>fG', file_actions.link_github_copilot_instructions, { desc = 'Link .github from dotfiles' })

map('x', '<leader><leader>tr', [["zy:%s/\V<C-r>=escape(@z, '/')<CR>//gc<left><left><left>]], { desc = 'Visual search replace' })
map('n', '<leader>;;', checkbox_actions.toggle, { desc = 'Toggle checkbox' })

map('n', '<leader>vc', file_actions.delete_all_comments, { desc = 'Delete all comments' })
map('n', '<leader>vC', file_actions.delete_comments_from_uncommitted_files, { desc = 'Delete comments from uncommitted files' })

map('n', '<leader>la', file_actions.copy_all_files_content, { desc = 'Copy all files content' })
map('n', '<leader>lu', file_actions.copy_current_file_url, { desc = 'Copy current file link' })
map('n', '<leader>lo', file_actions.copy_opencode_link, { desc = 'Copy OpenCode link' })
map('n', '<leader>le', errors_actions.copy_diagnostic_under_cursor, { desc = 'Copy diagnostic' })
map('n', '<leader>lw', editor_actions.toggle_wrap, { desc = 'Toggle text wrap' })
map('n', '<leader>ll', buffer_actions.close_other_buffers_and_create_empty, { desc = 'Close other buffers and create empty buffer' })
map('n', '<leader>vx', language_actions.run_knip_fix_current_folder, { desc = 'Knip fix current folder' })
map('n', '<leader>vX', language_actions.run_knip_fix, { desc = 'Knip fix & remove files (global)' })

map('n', '<leader>ve', language_actions.run_eslint_picker, { desc = 'ESLint analysis picker' })
map('n', '<leader>vK', language_actions.run_knip_unused_files, { desc = 'Knip unused files' })
map('n', '<leader>vk', language_actions.run_knip_unused_code, { desc = 'Knip unused code' })

map('n', '<leader><leader>ri', replacement_actions.replace_interactive, { desc = 'Interactive replace' })
map('n', '<leader><leader>rb', replacement_actions.replace_buffer, { desc = 'Replace in buffer' })
map('n', '<leader><leader>rB', replacement_actions.replace_buffer_all, { desc = 'Replace all in buffer' })
map('n', '<leader><leader>rp', replacement_actions.replace_buffer_prefilled, { desc = 'Replace in buffer (prefilled)' })
map('n', '<leader><leader>rP', replacement_actions.replace_buffer_all_prefilled, { desc = 'Replace all in buffer (prefilled)' })
map('v', '<leader><leader>rs', replacement_actions.replace_buffer_selected, { desc = 'Replace selected in buffer' })
map('v', '<leader><leader>rS', replacement_actions.replace_buffer_all_selected, { desc = 'Replace all selected in buffer' })
map('n', '<leader><leader>rq', replacement_actions.replace_quickfix, { desc = 'Replace in quickfix' })
map('n', '<leader><leader>rQ', replacement_actions.replace_quickfix_all, { desc = 'Replace all in quickfix' })
map('n', '<leader><leader>rf', replacement_actions.replace_project, { desc = 'Replace in project' })
map('n', '<leader><leader>rF', replacement_actions.replace_project_all, { desc = 'Replace all in project' })

map('n', '<Leader>i', '<C-i>', { desc = 'Jump forward' })
map('n', '<Leader>o', '<C-o>', { desc = 'Jump backward' })

map('n', '<Leader>q', ':q<CR>', { desc = 'Quit' })
map('n', '<Leader>Q', ':qa!<CR>', { desc = 'Force quit all' })
map('n', '<Leader>w', ':w<CR>', { desc = 'Write' })
map('n', '<Leader>W', ':wa<CR>', { desc = 'Write all' })

map('n', '<Leader>rt', todoist_actions.log_todoist_task(), { desc = 'Log task (non-charcoal)' })
map('n', '<Leader>rT', todoist_actions.log_todoist_task_all_projects(), { desc = 'Log task (all projects)' })
map('n', '<Leader>rP', todoist_actions.log_todoist_task_programming(), { desc = 'Log task (programming)' })
map('n', '<Leader>rw', jira_actions.create_jira_task(), { desc = 'Create Jira task' })
map('n', '<Leader>rW', jira_actions.create_jira_task_with_link(), { desc = 'Create Jira task + open link' })
map('n', '<Leader>rj', journal_actions.add_journal_entry, { desc = 'Add journal entry' })
map('n', '<Leader>rJ', journal_actions.open_journal, { desc = 'Open journal' })
map('n', '<Leader>rp', notes_actions.add_notes_entry, { desc = 'Add notes entry' })

map('n', '<leader>;ct', todoist_actions.refresh_todoist_cache(), { desc = 'Refresh Todoist cache' })
map('n', '<leader>;cw', jira_actions.refresh_jira_cache, { desc = 'Refresh Jira cache' })

map('n', '<leader>;s', jira_actions.generate_done_md, { desc = 'Generate this week jira tasks' })
map('n', '<leader>;t', jira_actions.copy_assigned_issues_for_testing, { desc = 'Copy assigned issues for testing' })
map('n', '<leader>;p', github_actions.copy_open_prs, { desc = 'Copy open PRs' })
map('n', '<Leader>ryj', jira_actions.copy_ticket_with_title, { desc = 'Copy Jira ticket with title' })

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

map('n', '<Leader>ud', file_actions.open_current_dir, { desc = 'Open directory' })
map('n', '<Leader>uc', github_actions.open_current_commit_in_github, { desc = 'Open Current Commit in GitHub' })
map('n', '<Leader>up', git_actions.open_or_create_pull_request, { desc = 'Open existing PR or create new one' })
map('n', '<Leader>ur', link_actions.open_current_github_repo, { desc = 'Open current GitHub repo' })
map('n', '<Leader>uj', link_actions.open_jira_ticket, { desc = 'Open Jira ticket' })
map('n', '<Leader>un', link_actions.open_npm_url, { desc = 'Open NPM link' })
map('n', '<Leader>uP', link_actions.open_current_github_prs, { desc = 'Open GitHub PRs tab' })
map('n', '<Leader>uW', github_actions.open_worktree_pr, { desc = 'Open worktree PR in browser' })
map('n', '<Leader>uu', link_actions.open_useful_link, { desc = 'Open useful link' })
map('n', '<Leader>uU', link_actions.open_private_useful_link, { desc = 'Open private useful link' })
map('n', '<Leader>ug', github_actions.list_org_repos_and_open, { desc = 'List Org Repos' })
map('n', '<Leader>uG', github_actions.list_org_repos_and_open, { desc = 'List Org Repos (alt)' })
map('n', '<Leader>us', link_actions.search_google, { desc = 'Search Google' })
map('n', '<Leader>uF', link_actions.open_firefox_container, { desc = 'Open Firefox container' })
map('v', '<Leader>us', link_actions.search_google, { desc = 'Search Google (selection)' })
