---
todoist: https://app.todoist.com/app/section/neovim-6f29FXGQfv24xCqG
---

# Remove Emoji from Commit Messages & Add OpenCode Commit Keymap

## Overview

Remove all emoji from the conventional commit keymaps (`<leader>gc*` and `<leader>gC*`) and the quick-update constant, and add a dedicated keymap to trigger OpenCode's `/commit` command from Neovim.

## Architecture

Commit logic is in `lua/custom/actions/git.lua` (`create_commit` function takes an `emoji` parameter). Commit keymaps are defined in `lua/plugins/fugitive.lua`. The OpenCode commit keymap will use toggleterm to send a command to an OpenCode terminal session.

## Data Flow

1. User presses `<leader>gcf` → calls `create_commit('feat', '', false)`
2. `create_commit` builds message: `feat(scope): description` (no emoji)
3. Executes `git commit --no-verify -m "..."` in terminal

For OpenCode commit:
1. User presses new keymap → sends `/commit` to an OpenCode terminal or triggers the CLI

## Tasks

### 1. Remove emoji from all commit keymaps in fugitive.lua

- **File**: `lua/plugins/fugitive.lua` (modify)
- **Changes**: Replace all emoji strings (`'✨'`, `'🐛'`, etc.) with `''` in every `create_commit()` call (lines 74-101)
- **Complexity**: small
- **Parallel**: yes

### 2. Remove emoji from quick update constant and branch commit function

- **File**: `lua/custom/actions/git.lua` (modify)
- **Changes**:
  - Line 145: Change `QUICK_UPDATE_MESSAGE` from `'feat: ✨ update'` to `'feat: update'`
  - Lines 189-199: Remove the `branch_emoji` table entirely
  - Update `create_commit_from_branch_name` to not include emoji
- **Complexity**: small
- **Parallel**: yes (with task 1)

### 3. Add OpenCode commit keymap

- **File**: `lua/plugins/fugitive.lua` or `lua/core/keymaps.lua` (modify)
- **Changes**: Add keymap that runs OpenCode `/commit` command via terminal. Could use `:TermExec cmd='opencode /commit'` or integrate with the opencode.nvim plugin
- **Complexity**: small
- **Parallel**: yes (with tasks 1-2)

## Edge Cases

- The `emoji` parameter in `create_commit` should handle `nil` and `''` identically (already does based on line 165: `emoji == '' and '' or ' ' .. emoji`)
- Branch-name commits also add emoji via `branch_emoji` lookup — ensure this path also strips emoji

## Testing Approach

- After changes, verify `<leader>gcf` produces `feat(scope): description` with no emoji
- Verify `<leader>gCu` (quick update) produces `feat: update`
- Verify `<leader>gcx` (from branch name) produces no emoji
- Test the OpenCode commit keymap triggers correctly

## Decisions

- OpenCode commit keymap: `<leader>gco`
