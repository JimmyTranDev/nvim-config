# Config Quality & UX Improvements

## Overview

Three improvements: full audit of env var reads for graceful degradation, auto Postgres Docker containers per git worktree via `docker run`, and completing the Jira FE/BE label task (already done — skip).

**Removed from scope:**
- Jira FE/BE tag: already implemented (LABELS table is wired into `create_jira_task` flow)
- `<leader>u` command refactor: skipped for now

## Architecture

- `lua/custom/utils/env_check.lua` — existing env var checker
- Multiple action files — every module that reads `vim.env.*`
- `lua/custom/actions/docker.lua` (new) — Docker container management per worktree
- `lua/core/keymaps.lua` — Docker keymaps

## Data Flow

**Graceful degradation (full audit):** Trace every `vim.env.*` and `os.getenv()` read across all action modules. For each, wrap in a guard: if nil, show `vim.notify("Feature X requires ENV_VAR_NAME", vim.log.levels.WARN)` and return early. Also extend `env_check.lua` to check for required CLI tools (`gh`, `acli`, `jq`).

**Docker per worktree:** keymap → `docker.start_db()` → detect worktree name via `git worktree list --porcelain` or branch name → `docker run --name pg-<worktree> -e POSTGRES_PASSWORD=... -p <port>:5432 -v pgdata-<worktree>:/var/lib/postgresql/data -d postgres:16` → container runs in background. Port is deterministic: `5432 + hash(worktree_name) % 100`.

## Tasks

| # | File | Change | Complexity | Dependencies | Parallel? |
|---|------|--------|-----------|--------------|-----------|
| 1 | All files in `lua/custom/actions/` | Full audit: find every `vim.env.*` and `os.getenv()` read. For each, add a nil check that notifies the user and returns early instead of crashing. Key files to audit: `jira.lua`, `todoist.lua`, `github.lua`, `git.lua`, `links.lua`, `branch.lua`, `pnpm.lua`. | medium | none | yes |
| 2 | `lua/custom/utils/env_check.lua` | Extend to also check for required CLI tools. Add a `check_tool(name)` helper that runs `vim.fn.executable(name)`. Add checks for `gh`, `acli`, `jq`, `docker`. Group results by "missing env vars" and "missing tools" in the startup notification. | small | none | yes |
| 3 | `lua/custom/actions/docker.lua` (new) | Create module with: `start_db()` — detects worktree/branch name, runs `docker run` with worktree-specific container name (`pg-<name>`), volume (`pgdata-<name>`), and deterministic port. `stop_db()` — stops and removes the container. `status()` — lists all `pg-*` containers. `cleanup_all()` — stops/removes all. Uses `vim.fn.system()` for docker commands. | large | none | yes |
| 4 | `lua/core/keymaps.lua` | Add keymaps: `<leader>tds` → `docker.start_db()`, `<leader>tdx` → `docker.stop_db()`, `<leader>tdi` → `docker.status()`, `<leader>tdX` → `docker.cleanup_all()`. | small | Task 3 | sequential after 3 |

## API Contracts

New module `lua/custom/actions/docker.lua`:
```lua
M.start_db()      -- starts Postgres container for current worktree/branch
M.stop_db()       -- stops and removes container for current worktree/branch
M.status()        -- lists all pg-* containers with ports and status
M.cleanup_all()   -- stops and removes ALL worktree Postgres containers
```

Optional env vars (with defaults):
- `DOCKER_POSTGRES_IMAGE` — default `postgres:16`
- `DOCKER_POSTGRES_PASSWORD` — default `postgres`
- `DOCKER_POSTGRES_BASE_PORT` — default `5432`

## State Changes

- Docker containers named `pg-<worktree-or-branch-name>`
- Docker volumes named `pgdata-<worktree-or-branch-name>`
- Port mapping: `base_port + (hash(name) % 100)` to avoid collisions while being deterministic

## Edge Cases

- Graceful degradation: some env vars are optional for certain actions (e.g. `ORG_JIRA_EPICS` only matters for Jira). Guards should be context-aware — only warn when the feature is actually invoked.
- Docker: if Docker daemon is not running, `docker run` fails with a clear error — catch and show `vim.notify`.
- Docker: if `vim.fn.executable('docker') == 0`, show "Docker not installed" and abort.
- Docker: if port is already in use (container already running), detect via `docker ps` and notify instead of failing.
- Docker: if not in a git repo, use the cwd directory name as the container suffix.
- Docker: container names must be valid Docker names — sanitize worktree names (replace `/`, spaces, etc. with `-`).

## Testing Approach

Manual verification:
- Unset `ORG_JIRA_TICKET_LINK` → trigger `<leader>rw` (create Jira task) → confirm friendly warning instead of crash
- Unset `TODOIST_API_TOKEN` → trigger `<leader>rt` → confirm friendly warning
- Run `<leader>tds` in a worktree → `docker ps` shows `pg-<worktree>` running on expected port
- Run `<leader>tdi` → shows all worktree containers
- Run `<leader>tdx` → container stopped and removed
- Run `<leader>tdX` → all pg-* containers cleaned up

## Open Questions

None — all resolved.
