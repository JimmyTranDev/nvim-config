local gitActions = require('custom.actions.git')
local githubActions = require('custom.actions.github')

return {
  'tpope/vim-fugitive',
  event = 'VeryLazy',
  cond = function()
    return not require('core.vscode').is_vscode() -- VSCode has built-in git functionality
  end,
  dependencies = {
    'akinsho/nvim-toggleterm.lua',
  },
  keys = {
    { mode = 'n', '<Leader>ghc', githubActions.create_draft_pr, desc = 'View Repo Summary', silent = true },
    { mode = 'n', '<Leader>ghP', githubActions.select_and_open_pr, desc = 'View Repo Summary', silent = true },
    { mode = 'n', '<Leader>ghp', githubActions.open_prs_in_current_repo, desc = 'View PRs in Current Repo', silent = true },

    -- SAFE
    { mode = 'n', '<Leader>gf', ':Git fetch --prune --all<CR>', desc = '󰓦 Fetch prune', silent = true },
    { mode = 'n', '<Leader>gl', ':split <Bar> :terminal git --no-pager log<CR>', desc = '󰈙 Log All', silent = true },
    { mode = 'n', '<Leader>gs', ':Git status<CR>', desc = '󱖫 Status', silent = true },
    { mode = 'n', '<Leader>gv', gitActions.gitAddPatch, desc = '📝 Git add patch', silent = true },

    -- STASH OPERATIONS
    { mode = 'n', '<Leader>ghh', gitActions.stashAllChanges, desc = '📦 Stash all changes', silent = true },
    { mode = 'n', '<Leader>ghk', gitActions.stashKeepChanges, desc = '📦 Stash keeping staged changes', silent = true },
    { mode = 'n', '<Leader>ghH', gitActions.selectAndPopStash, desc = '📦 Select and pop stash', silent = true },

    -- RISKY
    { mode = 'n', '<Leader>gS', gitActions.openGithubPullRequest, desc = ' Open GitHub PR', silent = true },
    { mode = 'n', '<Leader>gI', ':Git init<CR>', desc = '󱩵 Init', silent = true },
    { mode = 'n', '<Leader>gF', ':Git push --force-with-lease<CR>', desc = ' Push force', silent = true },
    { mode = 'n', '<Leader>gH', ':Git branch -D holding <Bar> Git branch holding<CR>', desc = '󱩵 Recreate holding branch', silent = true },
    { mode = 'n', '<Leader>gM', ':Git commit --amend --no-verify --no-edit<CR>', desc = ' Amend', silent = true },
    { mode = 'n', '<Leader>gP', ':Git push<CR>', desc = ' Push', silent = true },
    { mode = 'n', '<Leader>gV', ':Git add .<CR>', desc = ' Add all', silent = true },

    -- EFFICIENT COMBO
    {
      mode = 'n',
      '<Leader>gym',
      ':Git add . <Bar> :Git commit --amend --no-verify --no-edit <Bar> :Git push --force-with-lease<CR>',
      desc = ' Amend and push',
      silent = true,
    },
    {
      mode = 'n',
      '<Leader>gyy',
      ":Git add . <Bar> :Git commit --no-verify -m 'feat: ✨ update' <Bar> :Git push<CR>",
      desc = ' Commit and push',
      silent = true,
    },

    -- RESET
    { mode = 'n', '<Leader>grC', ':Git reset . <BAR> :Git clean -df <BAR> Git restore .<CR>', desc = 'Reset All', silent = true },
    { mode = 'n', '<Leader>grr', ':Git reset .<CR>', desc = 'Reset patch', silent = true },
    { mode = 'n', '<Leader>grT', ':Git reset -p<CR>', desc = 'Reset', silent = true },
    { mode = 'n', '<Leader>grt', ':Git restore -p<CR>', desc = 'Restore patch', silent = true },
    { mode = 'n', '<Leader>grR', function() require('custom.actions.git').resetToReflog() end, desc = 'Reset to reflog', silent = true },
    { mode = 'n', '<Leader>grH', function() require('custom.actions.git').resetHardToCommit() end, desc = '🔥 Reset hard to commit', silent = true },
    { mode = 'n', '<Leader>grS', function() require('custom.actions.git').resetSoftToCommit() end, desc = '💿 Reset soft to commit', silent = true },
    { mode = 'n', '<Leader>grO', ':Git reset --hard origin<CR>', desc = '💥 Reset hard to origin', silent = true },

    -- BRANCH
    { mode = 'n', '<Leader>gbP', ':Git pull --rebase<CR>', desc = 'Branch pull rebase', silent = true },
    { mode = 'n', '<Leader>gbM', ':Git pull --no-rebase<CR>', desc = 'Branch pull merge', silent = true },
    { mode = 'n', '<Leader>gbp', ':Git pull<CR>', desc = 'Branch pull', silent = true },

    -- CREATE BRANCH
    { mode = 'n', '<Leader>gnC', gitActions.createBranch('ci'), desc = '👷 Branch CI' },
    { mode = 'n', '<Leader>gnb', gitActions.createBranch('build'), desc = '📦 Branch Build' },
    { mode = 'n', '<Leader>gnc', gitActions.createBranch('chore'), desc = '🔧 Branch Chore' },
    { mode = 'n', '<Leader>gnd', gitActions.createBranch('docs'), desc = '📚 Branch Docs' },
    { mode = 'n', '<Leader>gnf', gitActions.createBranch('feature'), desc = '✨ Branch Feature' },
    { mode = 'n', '<Leader>gnp', gitActions.createBranch('perf'), desc = '🚀 Branch Perf' },
    { mode = 'n', '<Leader>gnr', gitActions.createBranch('refactor'), desc = '🔨 Branch Refactor' },
    { mode = 'n', '<Leader>gns', gitActions.createBranch('style'), desc = '💎 Branch Style' },
    { mode = 'n', '<Leader>gnt', gitActions.createBranch('test'), desc = '🧪 Branch Test' },
    { mode = 'n', '<Leader>gnF', gitActions.createBranch('fix'), desc = '🐛 Branch Fix' },
    { mode = 'n', '<Leader>gnR', gitActions.createBranch('revert'), desc = '⏪ Branch Revert' },

    -- CREATE COMMIT  PUSH
    { mode = 'n', '<Leader>gCa', gitActions.createCommit('ci', '👷', true), desc = '👷 Commit actions' },
    { mode = 'n', '<Leader>gCb', gitActions.createCommit('build', '📦', true), desc = '📦 Commit build' },
    { mode = 'n', '<Leader>gCc', gitActions.createCommit('chore', '🔧', true), desc = '🔧 Commit chore' },
    { mode = 'n', '<Leader>gCd', gitActions.createCommit('docs', '📚', true), desc = '📚 Commit docs' },
    { mode = 'n', '<Leader>gCf', gitActions.createCommit('feat', '✨', true), desc = '✨ Commit feat' },
    { mode = 'n', '<Leader>gCn', gitActions.createCommit(nil, nil, true), desc = 'Commit none' },
    { mode = 'n', '<Leader>gCp', gitActions.createCommit('perf', '🚀', true), desc = '🚀 Commit perf' },
    { mode = 'n', '<Leader>gCr', gitActions.createCommit('refactor', '🔨', true), desc = '🔨 Commit refactor' },
    { mode = 'n', '<Leader>gCs', gitActions.createCommit('style', '💎', true), desc = '💎 Commit style' },
    { mode = 'n', '<Leader>gCt', gitActions.createCommit('test', '🧪', true), desc = '🧪 Commit test' },
    { mode = 'n', '<Leader>gCF', gitActions.createCommit('fix', '🐛', true), desc = '🐛 Commit fix' },
    { mode = 'n', '<Leader>gCR', gitActions.createCommit('revert', '⏪', true), desc = '⏪ Commit revert' },
    { mode = 'n', '<Leader>gCu', gitActions.createCommit('feat', '✨', true, true), desc = '⏪ Commit update' },
    { mode = 'n', '<Leader>gcy', gitActions.quickCommitUpdate, desc = '󰊢 Quick commit update', silent = true },

    -- CREATE COMMIT
    { mode = 'n', '<Leader>gca', gitActions.createCommit('ci', '👷'), desc = '👷 Commit actions' },
    { mode = 'n', '<Leader>gcb', gitActions.createCommit('build', '📦'), desc = '📦 Commit build' },
    { mode = 'n', '<Leader>gcc', gitActions.createCommit('chore', '🔧'), desc = '🔧 Commit chore' },
    { mode = 'n', '<Leader>gcd', gitActions.createCommit('docs', '📚'), desc = '📚 Commit docs' },
    { mode = 'n', '<Leader>gcf', gitActions.createCommit('feat', '✨'), desc = '✨ Commit feat' },
    { mode = 'n', '<Leader>gcn', gitActions.createCommit(), desc = 'Commit none' },
    { mode = 'n', '<Leader>gcp', gitActions.createCommit('perf', '🚀'), desc = '🚀 Commit perf' },
    { mode = 'n', '<Leader>gcr', gitActions.createCommit('refactor', '🔨'), desc = '🔨 Commit refactor' },
    { mode = 'n', '<Leader>gcs', gitActions.createCommit('style', '💎'), desc = '💎 Commit style' },
    { mode = 'n', '<Leader>gct', gitActions.createCommit('test', '🧪'), desc = '🧪 Commit test' },
    { mode = 'n', '<Leader>gcF', gitActions.createCommit('fix', '🐛'), desc = '🐛 Commit fix' },
    { mode = 'n', '<Leader>gcR', gitActions.createCommit('revert', '⏪'), desc = '⏪ Commit revert' },
    { mode = 'n', '<Leader>gCu', gitActions.createCommit('feat', '✨', false, true), desc = '⏪ Commit update' },

    { mode = 'n', '<Leader>gwa', gitActions.createWorktree('ci'), desc = '👷 Worktree CI' },
    { mode = 'n', '<Leader>gwb', gitActions.createWorktree('build'), desc = '📦 Worktree Build' },
    { mode = 'n', '<Leader>gwd', gitActions.createWorktree('docs'), desc = '📚 Worktree Docs' },
    { mode = 'n', '<Leader>gwf', gitActions.createWorktree('feature'), desc = '✨ Worktree Feature' },
    { mode = 'n', '<Leader>gwp', gitActions.createWorktree('perf'), desc = '🚀 Worktree Perf' },
    { mode = 'n', '<Leader>gwr', gitActions.createWorktree('refactor'), desc = '🔨 Worktree Refactor' },
    { mode = 'n', '<Leader>gws', gitActions.createWorktree('style'), desc = '💎 Worktree Style' },
    { mode = 'n', '<Leader>gwt', gitActions.createWorktree('test'), desc = '🧪 Worktree Test' },
    { mode = 'n', '<Leader>gwF', gitActions.createWorktree('fix'), desc = '🐛 Worktree Fix' },
    { mode = 'n', '<Leader>gwR', gitActions.createWorktree('revert'), desc = '⏪ Worktree Revert' },
  },
}
