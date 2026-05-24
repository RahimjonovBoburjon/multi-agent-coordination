# You are running in Solo Mode

This project is configured for a single Claude Code terminal. Multi-agent coordination machinery is mostly inactive, but the lightweight task tracking still pays off when resuming work across sessions.

## What stays active

- **`active_tasks.md`** — your personal kanban. Use it to remember what you were doing, what's blocked, and what's shipped. Update it at the start and end of each session.
- **Pre-commit pause** — for non-trivial changes, pause before committing and ask the user to confirm. (Solo mode skips the formal approval gate, but the discipline of "review before commit" still prevents most regressions.)

## What is skipped

- **`active_files.md` locks** — no parallel terminals means no lock conflicts. Skip entirely.
- **Planner / developer split** — you are both.
- **Approval gate** — see above.

## Project-specific settings

- **Lock TTL:** N/A (solo)
- **Git workflow:** {{GIT_VARIANT_NAME}}
- **Integration branch:** `{{INTEGRATION_BRANCH}}`
- **Production branch:** `{{PROD_BRANCH}}`
- **Build / typecheck:** `{{BUILD_COMMAND}}`
- **Tests:** `{{TEST_COMMAND}}`
- **Commit format:** {{COMMIT_FORMAT}}

## First action

1. Read `active_tasks.md` to see where you left off.
2. If a task is in AWAITING REVIEW or BLOCKED, finish that one before starting new work.
3. Otherwise, ask the user what's next.

## If you scale up later

If a second terminal joins this project, re-run `/multi-agent-init` and pick Pair / Squad mode. The wizard will preserve your existing `active_tasks.md` content and only update the config.
