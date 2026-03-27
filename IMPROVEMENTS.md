# Improvements

## Follow-up Items

### High Priority

- [ ] Add error notification to `sync_notes_repo` push callback in `utils/git.lua` — currently push failures are silent
- [ ] Fix `journal.lua` `add_journal_entry` to not call `write_lines` when `find_entry_insert_line` returns nil — currently writes the file without the entry but shows a success notification

### Medium Priority

- [ ] Guard `ensure_today_header` in `journal.lua` against `write_lines` failure — currently returns modified in-memory lines even if write fails, causing `open_journal` to jump to a line that may not exist on disk
- [ ] Remove dead code in `utils/language.lua` lines ~77-87 — the CWD lockfile fallback check is unreachable because `find_workspace_root` already checks CWD as its first iteration
- [ ] Decouple `core/statusline.lua` self-calling `M.setup()` at module load — consider removing the auto-call and letting the plugin spec's `config` call `setup()` explicitly

### Low Priority

- [ ] Extract `branch_emoji` lookup table in `actions/git.lua` to `constants/` if it needs to be reused elsewhere
- [ ] Consider making `get_javascript_package_manager_dev_arg` return a default value instead of nil when no package manager is detected
