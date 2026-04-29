# Picker & Terminal Enhancements

## Overview

Two improvements: filter Snacks recent files picker to the current git repo only, and add multi-select npm script picker that runs each selected script in a visible terminal split.

## Architecture

- `lua/plugins/snacks.lua` — Snacks picker configuration, recent files behavior
- `lua/custom/actions/language.lua` — `run_package_script` function (reads package.json, presents picker)
- `lua/plugins/toggleterm.lua` — npm script keymaps

## Data Flow

**Recent files filter:** Snacks picker `recent` source → filter callback checks each file path starts with `vim.fn.systemlist('git rev-parse --show-toplevel')[1]` → only matching files shown. Cache the git root per session to avoid repeated shell calls.

**Multi-select npm scripts:** keymap → read `package.json` scripts → Snacks picker with multi-select enabled → for each selected script, open a toggleterm split (horizontal) with incrementing terminal IDs → all visible simultaneously as horizontal splits.

## Tasks

| # | File | Change | Complexity | Dependencies | Parallel? |
|---|------|--------|-----------|--------------|-----------|
| 1 | `lua/plugins/snacks.lua` | Modify the Snacks picker `recent` config to add a `filter` function that checks files belong to the current git repo root. Use `vim.fn.systemlist('git rev-parse --show-toplevel')[1]` cached in a module-level variable. If not in a git repo, show all files (fallback). | small | none | yes |
| 2 | `lua/custom/actions/language.lua` | Create a new function `run_multiple_package_scripts(start_term_id)` that reads package.json, opens a Snacks multi-select picker, and for each selected script opens a horizontal split toggleterm instance running `npm run <script>`. Terminal IDs start from `start_term_id`. Each terminal's display name should include the script name. | medium | none | yes |
| 3 | `lua/plugins/toggleterm.lua` | Add `<leader>tnm` keymap that calls the new multi-select npm script runner. Add `<leader>tnM` to kill all multi-select spawned terminals (similar to existing `<leader>tnA` pattern). | small | Task 2 | sequential after 2 |

## API Contracts

New function in `lua/custom/actions/language.lua`:
```lua
M.run_multiple_package_scripts(start_term_id: number) -> function
```

Returns a function (thunk) for use as a keymap callback. When called:
1. Reads `package.json` from `vim.fn.getcwd()`
2. Opens Snacks picker with multi-select
3. For each selected script, creates a toggleterm with `direction = 'horizontal'` and a unique ID starting from `start_term_id`

## State Changes

None.

## Edge Cases

- Recent files filter: if not in a git repo (`git rev-parse` fails), fall back to showing all recent files without error.
- Multi-select: if `package.json` has no `scripts` key, notify and abort.
- Multi-select: if `package.json` doesn't exist in cwd, notify and abort.
- Multi-select: cap at 6 simultaneous splits (screen real estate) — if user selects more, warn and truncate.
- Terminal naming: set `display_name` on each toggleterm to the script name for identification in terminal list.

## Testing Approach

Manual verification:
- Open nvim in a git repo, trigger recent files → only files from that repo appear
- Open nvim in a non-git directory → all recent files appear (fallback)
- Trigger `<leader>tnm` → select 3 scripts → confirm 3 horizontal splits open running the correct commands
- Trigger `<leader>tnM` → confirm all multi-select terminals are killed
- Trigger in a directory with no package.json → confirm notification

## Open Questions

None — all resolved.
