---
todoist: https://app.todoist.com/app/section/neovim-6f29FXGQfv24xCqG
---

# Neovim UI & Display Fixes

## Overview

Fix three display issues: markdown tables breaking with word wrap enabled, "file changed on disk" notification spam, and lualine disappearing behind toggleterm/other buffers.

## Architecture

- Word wrap/tables: controlled by `vim.wo.wrap` in `lua/core/options.lua` and the toggle in `lua/custom/actions/editor.lua`. Need filetype-specific or syntax-aware overflow handling.
- Buffer reload: uses `vim.o.autoread` in options.lua. The spam comes from `checktime` events triggering repeated notifications.
- Lualine: configured in `lua/core/statusline.lua` with `laststatus = 3` (global statusline). Toggleterm may be overriding or conflicting.

## Tasks

### 1. Fix table overflow with word wrap

- **File**: `lua/core/options.lua` or `lua/custom/actions/editor.lua` (modify)
- **File**: possibly new autocmd in `lua/core/commands.lua`
- **Changes**:
  - When wrap is enabled, tables should not wrap. Options:
    - Use `vim.opt.conceallevel` or treesitter-based detection to disable wrap on table lines
    - Add an autocmd that sets `nowrap` for lines matching table patterns
    - Use a plugin like `vim-table-mode` or configure markview to render tables with horizontal scroll
    - Alternative: use `sidescrolloff` and `nowrap` only within table regions via extmarks
  - Most practical: configure the markview plugin to handle table rendering with overflow, or use a `WinScrolled` / `CursorMoved` autocmd approach
- **Complexity**: large
- **Parallel**: yes

### 2. Fix "file changed on disk" notification spam

- **File**: `lua/core/commands.lua` or new autocmd in `lua/core/options.lua`
- **Changes**:
  - Debounce or suppress the `FileChangedShellPost` / `FocusGained` autoread notifications
  - Options:
    - Add `vim.api.nvim_create_autocmd('FileChangedShellPost', { callback = function() vim.cmd('silent! checktime') end })`
    - Or throttle notifications: only show once per file per N seconds
    - Or silently reload without notification: `set autoread` + silent checktime on focus
- **Complexity**: small
- **Parallel**: yes

### 3. Fix lualine always at bottom with toggleterm

- **File**: `lua/core/statusline.lua` (modify)
- **File**: `lua/plugins/toggleterm.lua` (possibly modify)
- **Changes**:
  - `laststatus = 3` should already keep statusline global. If toggleterm opens as a split, lualine may get hidden.
  - Ensure toggleterm doesn't override `laststatus`
  - Add `winbar` or ensure the lualine `disabled_filetypes` config doesn't hide it for terminal buffers
  - May need to set `lualine.options.disabled_filetypes.statusline = {}` explicitly
  - Check if toggleterm's `direction = 'horizontal'` is creating a window that pushes lualine off-screen
- **Complexity**: medium
- **Parallel**: yes

## Edge Cases

- Table fix: must not break non-markdown files when wrap is toggled
- Buffer reload: must still actually reload the file, just suppress the notification
- Lualine: fix must work for all terminal counts (1-10) and both horizontal/vertical splits

## Testing Approach

- Table fix: open a markdown file with wide table, enable wrap, verify table doesn't line-break
- Buffer reload: modify a file externally, switch back to nvim, verify it reloads silently without repeated popups
- Lualine: open toggleterm with `<leader>t1`, verify statusline remains visible at the very bottom

## Decisions

- Table overflow: use markview plugin configuration to handle table rendering with horizontal overflow
- Buffer reload: completely silent — reload without any notification
