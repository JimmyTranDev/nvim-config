# Java Development Workflow Enhancements

## Overview

Four improvements to the Java development experience in Neovim: new-code test coverage via JaCoCo + diff-cover, Maven-based per-file test execution, unused code highlighting via jdtls settings, and a branch-specific SonarQube keymap.

## Architecture

All changes touch the Java/Maven layer:
- `lua/plugins/java.lua` — jdtls LSP settings for unused code diagnostics
- `lua/plugins/toggleterm.lua` — Maven terminal keymaps (`<leader>tv*`)
- `lua/core/keymaps.lua` — SonarQube keymap
- `lua/custom/utils/env_check.lua` — new env var registration

No new files needed. All keymaps follow existing patterns in toggleterm.lua and keymaps.lua.

## Data Flow

**Test coverage (new code):** keymap → toggleterm exec → `mvn clean test jacoco:report` → `diff-cover` (Python tool) compares JaCoCo XML against git diff → outputs coverage % for changed production lines only → opens HTML report.

**Test specific file:** keymap → extract Java class name from current buffer filename → toggleterm exec `mvn -Dtest=ClassName test -Dmaven.gitcommitid.skip=true` → output in terminal.

**Unused code highlighting:** jdtls settings in java.lua → configure `java.compile.nullAnalysis`, unused import/variable diagnostics → diagnostics appear inline as warnings.

**SonarQube:** keymap → read `ORG_SONARQUBE_URL` env var → get current branch name via `git rev-parse` → construct branch-specific URL → `vim.ui.open()`.

## Tasks

| # | File | Change | Complexity | Dependencies | Parallel? |
|---|------|--------|-----------|--------------|-----------|
| 1 | `lua/plugins/java.lua` | Add jdtls settings to enable unused import/variable diagnostics. Configure `java.compile.nullAnalysis.mode = 'automatic'` and relevant `java.cleanup.actionsOnSave` entries. Note: unused *methods* may not be supported by jdtls alone — imports and variables are the primary target. | small | none | yes |
| 2 | `lua/plugins/toggleterm.lua` | Add `<leader>tvN` keymap that runs `mvn clean test jacoco:report` then `diff-cover target/site/jacoco/jacoco.xml --compare-branch=develop --html-report target/diff-cover.html && open target/diff-cover.html`. This shows coverage specifically of changed production code. Requires `pip install diff-cover` as a prerequisite. | medium | none | yes |
| 3 | `lua/plugins/toggleterm.lua` | Add `<leader>tvf` keymap that extracts the class name from the current buffer's filename (e.g. `UserServiceTest.java` → `UserServiceTest`) and runs `mvn -Dtest=ClassName test -Dmaven.gitcommitid.skip=true` in toggleterm. This is a Maven alternative to the existing neotest `<leader><leader>cf`. | small | none | yes |
| 4 | `lua/core/keymaps.lua` | Add `<leader>uS` keymap that reads `ORG_SONARQUBE_URL` env var, gets current branch via `vim.fn.systemlist('git branch --show-current')[1]`, constructs `ORG_SONARQUBE_URL .. '&branch=' .. branch`, and opens via `vim.ui.open()`. Guard against missing env var with notification. | small | none | yes |

## API Contracts

New env var: `ORG_SONARQUBE_URL` — base URL for SonarQube dashboard including project key (e.g. `https://sonar.example.com/dashboard?id=project-key`). The keymap appends `&branch=<current-branch>`.

## State Changes

- Add `ORG_SONARQUBE_URL` to `lua/custom/utils/env_check.lua` REQUIRED_VARS list with features description `'SonarQube: branch coverage dashboard'`.

## Edge Cases

- jdtls unused code diagnostics may only cover imports and variables, not methods. This is acceptable — document the limitation.
- `diff-cover`: if the tool is not installed, the command will fail in the terminal with a clear error. No nvim-side guard needed.
- `diff-cover`: if no files are changed vs the compare branch, the report will show 100% or empty — this is correct behavior.
- Test specific file: if the current file is not a Java file, extract will produce garbage — guard by checking `vim.bo.filetype == 'java'`.
- SonarQube: if `ORG_SONARQUBE_URL` is missing, show `vim.notify` warning and return.

## Testing Approach

Manual verification:
- Open a Java file with unused imports → confirm diagnostic underlines appear
- Run `<leader>tvN` → confirm diff-cover report opens showing only changed-line coverage
- Open a Java test file → run `<leader>tvf` → confirm only that class's tests execute
- Trigger `<leader>uS` → confirm SonarQube opens with correct branch parameter
- Trigger `<leader>uS` without env var set → confirm friendly notification

## Open Questions

None — all resolved.
