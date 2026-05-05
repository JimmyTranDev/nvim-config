---
todoist: https://app.todoist.com/app/section/neovim-6f29FXGQfv24xCqG
---

# Neovim Team PR Dashboard

## Overview

Add a Neovim picker/dashboard showing all open PRs from team members across configured repositories. Builds on the existing `lua/custom/actions/github.lua` which already has PR listing, selection, and `gh` CLI integration.

## Architecture

Existing infrastructure:
- `lua/custom/actions/github.lua` already has `select_own_open_prs`, `select_open_prs_by_people`, `copy_open_prs`
- `lua/custom/utils/github.lua` provides `get_repo_info()` and gh CLI wrappers
- Snacks picker is used throughout for selection UI

New feature adds a cross-repo team PR view that aggregates PRs from multiple repos.

## Data Flow

1. User presses keymap → triggers `github_actions.team_pr_dashboard()`
2. Function reads configured org/repos list (from env var or config)
3. Runs `gh pr list --repo <org/repo> --json number,title,author,updatedAt,url` for each repo (parallel)
4. Aggregates results, groups by author or repo
5. Displays in snacks.picker with preview showing PR details
6. On selection: opens PR in browser or shows diff

## Tasks

### 1. Add team PR dashboard action

- **File**: `lua/custom/actions/github.lua` (modify)
- **Changes**: Add `M.team_pr_dashboard()` function that:
  - Reads repo list from `vim.env.GITHUB_TEAM_REPOS` (comma-separated `org/repo` list)
  - Falls back to current repo's org and lists all repos
  - Calls `gh pr list` for each repo concurrently using `vim.system` or async utils
  - Formats results into snacks picker items
- **Complexity**: large
- **Dependencies**: none
- **Parallel**: yes

### 2. Register keymap

- **File**: `lua/core/keymaps.lua` (modify)
- **Changes**: Add `map('n', '<Leader>uT', github_actions.team_pr_dashboard, { desc = 'Team PR dashboard' })`
- **Complexity**: small
- **Dependencies**: task 1
- **Parallel**: no (depends on task 1)

## API Contracts

```lua
function M.team_pr_dashboard()
  -- Reads GITHUB_TEAM_REPOS env var: "org/repo1,org/repo2,..."
  -- Displays picker with columns: repo | author | title | updated
  -- Confirm action: open PR URL in browser
end
```

## State Changes

- New env var: `GITHUB_TEAM_REPOS` — comma-separated list of repos to monitor
- Add to `lua/custom/utils/env_check.lua` as optional env var

## Edge Cases

- No `GITHUB_TEAM_REPOS` set: fall back to current org repos or show warning
- gh CLI not authenticated for a repo: skip it with warning
- Large number of PRs: limit to 50 per repo, show total count
- Network timeout: show partial results with error indicator

## Testing Approach

- Verify `gh pr list --repo org/repo --json ...` returns expected format
- Test with 1 repo, then multiple repos
- Test with env var unset (fallback behavior)

## Decisions

- Repos: configured repos only (via `GITHUB_TEAM_REPOS` env var)
- Refresh: manual only (triggered when user opens the dashboard)
- Config: env var `GITHUB_TEAM_REPOS` (comma-separated `org/repo` list)
