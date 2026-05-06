# Centralized Keymaps with Lazy Loading

## Overview

Consolidate all keymaps (~250+ across `core/keymaps.lua` and ~30 plugin files) into a single `lua/core/keymaps.lua` file while preserving lazy.nvim's `keys`-based lazy loading. The key insight: lazy.nvim's `keys` spec field serves two purposes — it defines keymaps AND triggers plugin loading. We can decouple these by using other lazy-loading triggers (`event`, `cmd`, `ft`) where plugins already have them, and adding lightweight triggers where they don't.

## Architecture

The approach:

1. **Plugins that already have non-`keys` triggers** (e.g., gitsigns has `event = { 'BufReadPre', 'BufNewFile' }`): Remove `keys` from the spec entirely. Move keymaps to `core/keymaps.lua` wrapped in `function() require('gitsigns').foo() end` — the lazy `require()` pattern ensures the call works regardless of load order.

2. **Plugins that ONLY use `keys` for lazy loading** (e.g., hop, leap, yazi): Add a minimal trigger (`event = 'VeryLazy'` or `cmd`) to the plugin spec, then move keymaps to `core/keymaps.lua`. Alternatively, keep a bare `keys` list in the spec (just the LHS trigger, no RHS) and define the actual mapping in `core/keymaps.lua` — but this creates duplication.

3. **The recommended pattern**: Use `event = 'VeryLazy'` as a catch-all for plugins that need to be available but don't have a natural trigger. This loads them after UI renders but before the user interacts — negligible startup impact for most plugins.

### Files touched

- `lua/core/keymaps.lua` — grows to contain ALL keymaps, organized by category
- `lua/plugins/*.lua` (~30 files) — remove `keys` tables, ensure each has a non-`keys` lazy trigger
- No new files needed

## Data Flow

1. Neovim starts → `init.lua` loads `core.lazy` → `core.options` → `core.plugins` (lazy.setup) → `core.commands` → `core.keymaps`
2. `core.keymaps` registers ALL keymaps via `map()` / `maps()` using the existing keybinding tracker
3. Each keymap's RHS uses `function() require('plugin').action() end` pattern — if the plugin isn't loaded yet, `require()` triggers lazy.nvim to load it on first call
4. Plugins load via their own triggers (`event`, `cmd`, `ft`, or `VeryLazy`) independently of keymaps

## Tasks

### 1. Audit plugin lazy-loading triggers
- **File**: All `lua/plugins/*.lua` files
- **What**: Categorize each plugin into:
  - (A) Already has non-`keys` trigger — safe to just move keymaps
  - (B) Only has `keys` trigger — needs a new trigger added
- **Complexity**: small
- **Parallel**: yes (independent research)

### 2. Add lazy triggers to keys-only plugins
- **Files**: ~15-20 plugin files in category (B)
- **What**: Add `event = 'VeryLazy'` (or more specific trigger where appropriate) to each plugin that currently only uses `keys` for loading
- **Complexity**: small
- **Parallel**: yes (each file independent)
- **Depends on**: Task 1

### 3. Extract plugin keymaps to core/keymaps.lua
- **File**: `lua/core/keymaps.lua`, all `lua/plugins/*.lua` with `keys` tables
- **What**: 
  - Move every `keys = { ... }` entry from plugin specs to `core/keymaps.lua`
  - Convert lazy.nvim `keys` format (`{ '<lhs>', function() end, desc = '...' }`) to the existing `map()` format (`map('n', '<lhs>', function() require('plugin').action() end, { desc = '...' })`)
  - Organize by logical groups (navigation, git, LSP, terminal, pickers, etc.) with section separators
  - Remove `keys` field from plugin specs
- **Complexity**: large (bulk migration of ~150+ keymaps)
- **Parallel**: no (single file target, must be done carefully)
- **Depends on**: Task 2

### 4. Handle on_attach keymaps
- **Files**: `lua/plugins/gitsigns.lua`, any other plugin with `on_attach` keymaps
- **What**: Some plugins define keymaps in `on_attach` or `config` callbacks (e.g., gitsigns' `on_attach` sets buffer-local keymaps). These are buffer-local and context-dependent — they CANNOT move to `core/keymaps.lua`. Document which keymaps must stay in plugin files and why.
- **Complexity**: small
- **Parallel**: yes
- **Depends on**: Task 1

### 5. Verify startup time hasn't regressed
- **What**: Run `:Lazy profile` and compare startup time before/after. The `VeryLazy` event should add negligible overhead since it fires after UI render.
- **Complexity**: small
- **Parallel**: no (must be done after all changes)
- **Depends on**: Task 3

### 6. Verify all keymaps work
- **What**: Spot-check keymaps from each category — LSP (gd, gi), pickers (leader-ff), git (leader-j*), terminal (leader-tn*), and core navigation (C-h/j/k/l)
- **Complexity**: small
- **Parallel**: no (must be done after Task 3)
- **Depends on**: Task 3

## Edge Cases

- **Buffer-local keymaps** (e.g., gitsigns `on_attach`, LSP `on_attach`): These must remain in plugin config callbacks. They are set per-buffer when the plugin attaches, not globally. The spec should NOT attempt to move these.
- **Keymaps that reference plugin-local state**: Some keymaps use closures over variables defined in the plugin spec. These need refactoring to use `require()` instead.
- **Duplicate LHS mappings**: `core/keymaps.lua` already has `<Leader>uv` and `<Leader>ug` defined twice (lines 159-162). This migration is a good opportunity to clean up duplicates.
- **Commented-out keymaps**: `core/keymaps.lua` has ~15 commented-out keymaps (replacement actions, future features). Keep these in place during migration.
- **Terminal mode keymaps** (`mode = 't'`): toggleterm defines terminal-mode keymaps. These work fine in `core/keymaps.lua` but only make sense when a terminal is open.
- **Startup order**: `core/keymaps.lua` loads AFTER `core/plugins` (lazy.setup), so all plugins are registered (but not loaded). The `require('plugin')` pattern in keymap RHS will trigger lazy loading on first use — this is safe.

## Testing Approach

- **Manual verification**: No automated tests needed for keymaps. Verify by:
  1. `:Lazy profile` — startup time comparison
  2. `:checkhealth` — no errors
  3. `:WhichKey` — all keymaps appear with correct descriptions
  4. Spot-check 5-10 keymaps across categories
- **Regression check**: Ensure `:Lazy` shows plugins still loading lazily (not all loaded at startup)

## Open Questions

### Architecture
1. **VeryLazy vs more specific triggers**: For plugins currently only triggered by `keys`, should we use `event = 'VeryLazy'` universally, or pick more specific triggers per plugin (e.g., `cmd = 'HopWord'` for hop)? VeryLazy is simpler but loads plugins slightly earlier than needed. Specific triggers preserve maximum laziness but require per-plugin analysis.

### Scope
2. **Buffer-local keymaps**: Should on_attach/buffer-local keymaps get a comment reference in `core/keymaps.lua` pointing to where they live, or just leave them undocumented in plugin files?

3. **Keybinding tracker integration**: Currently plugin `keys` bypass the keybinding tracker. After centralization, all keymaps will go through `map()` → `tracker.tracked_set()`. Is this desired? It means plugin keymaps will now show up in keybinding usage stats.
