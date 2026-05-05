---
todoist: https://app.todoist.com/app/section/neovim-6f29FXGQfv24xCqG
---

# Neovim Keymaps & Pickers

## Overview

Add new keymaps for copying frontend project paths, finding spec/plan files, copying repo root path, and sorting the `<leader>uu`/`<leader>uv` link pickers by recent use. These are independent quality-of-life improvements to the Neovim workflow.

## Architecture

All new keymaps follow the existing pattern: action logic lives in `lua/custom/actions/*.lua`, utility helpers in `lua/custom/utils/*.lua`, and keybindings are registered in `lua/core/keymaps.lua` using the `map()` helper. Pickers use `snacks.picker`.

## Tasks

### 1. Add "copy all frontend projects" keymap

- **File**: `lua/custom/actions/files.lua` (modify)
- **Changes**: Add a function that scans `~/Programming` for frontend projects (detect by `package.json` presence), formats their paths, and copies to clipboard
- **Keymap**: Register in `lua/core/keymaps.lua` under `<leader>;y` namespace (alongside existing copy keymaps like `;ya`, `;yu`, `;yo`)
- **Complexity**: medium
- **Parallel**: yes

### 2. Create keymap to find spec/plan files

- **File**: `lua/core/keymaps.lua` (modify)
- **Changes**: Add a keymap that opens snacks.picker scoped to `plans/` directories across the workspace. Use `Snacks.picker.files({ cwd = "plans" })` or grep across `**/plans/*.md`
- **Keymap**: Suggest `<leader>fP` (find plans) — adjacent to existing `<leader>fp` (switch project)
- **Complexity**: small
- **Parallel**: yes

### 3. Add "copy repo path" keymap

- **File**: `lua/custom/actions/files.lua` (modify)
- **Changes**: Add function that copies `vim.fn.getcwd()` to clipboard via `vim.fn.setreg('+', path)`
- **Keymap**: Register as `<leader>;yr` in `lua/core/keymaps.lua`
- **Complexity**: small
- **Parallel**: yes

### 4. Sort `<leader>uu` and `<leader>uv` links by recent use

- **File**: `lua/custom/actions/links.lua` (modify)
- **File**: `lua/custom/utils/links.lua` (modify or create tracking)
- **Changes**:
  - Track which links are opened (persist to a JSON file in nvim data dir)
  - On picker open, sort link list by last-used timestamp (most recent first)
  - Fall back to alphabetical for never-used links
- **Complexity**: medium
- **Parallel**: yes

## Edge Cases

- "Copy all frontend projects": should handle missing directories gracefully, skip repos without `package.json`
- Link tracking: handle corrupted/missing JSON file gracefully, create on first use
- Spec file finder: handle case where no `plans/` directory exists (show empty picker or notification)

## Testing Approach

- Manual verification of each keymap
- Ensure clipboard contains expected content after copy operations
- Verify picker displays sorted results after opening a link twice

## Decisions

- Copy format: one absolute path per line
- Spec file finder scope: search `plans/` in root of current project only
- Frontend copy keymap: `<leader>;yf`
