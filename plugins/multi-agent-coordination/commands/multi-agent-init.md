---
description: Interactive setup wizard for multi-agent coordination in this project (fast — 3 to 5 questions for most users)
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion
---

# /multi-agent-init — setup wizard

You are running the multi-agent coordination setup wizard. Your job is to get the user configured **as fast as possible** — auto-detect everything you can from the project, pick smart defaults from a preset, and only ask the user about choices that genuinely matter. Then save the config, scaffold the coordination files, patch CLAUDE.md, and print ready-to-paste intros.

The wizard MUST feel quick. A first-time user who picks Squad mode should be done in 3-5 prompts. Power users can pick "Custom" to get the full 13-question flow.

## Step 1 — detect existing setup

Check whether `.multi-agent/config.json` already exists at the repo root.

- If it exists: read it, summarize the current settings to the user, and ask: "Existing config found. Overwrite from scratch, update individual settings, or cancel?"
- If "update individual settings": ask which ones, ask only those, write back.
- If "overwrite": proceed to Step 2.
- If "cancel": stop here.

If it does NOT exist: proceed to Step 2.

## Step 2 — preset (the only mandatory question)

Use `AskUserQuestion` with these 5 options:

- **Solo** — 1 terminal. Lite task tracking. No locks, no gate.
- **Pair** — 2 terminals. 1 planner + 1 developer. Full protocol.
- **Squad** *(recommended for active projects)* — 3 terminals. 1 planner + 2 developers. Full protocol with 15min TTL.
- **Swarm** — 5+ terminals. Asks exact count next. Full protocol with stricter discipline.
- **Custom** — ask all 13 settings individually (use this if you want full control over TTL, variant, branches, etc.).

### Preset defaults (NOT asked — baked into each preset)

| Setting               | Solo  | Pair        | Squad       | Swarm       |
| --------------------- | ----- | ----------- | ----------- | ----------- |
| `has_planner`         | false | true        | true        | true        |
| `lock_ttl_minutes`    | n/a   | 15          | 15          | 15          |
| `stale_lock_policy`   | n/a   | auto-clear  | warn        | warn        |
| `git_variant`         | B     | B           | B           | B           |
| `approval_gate_enabled` | false | true      | true        | true        |
| `commit_format`       | conventional | conventional | conventional | conventional |
| `terminal_count`      | 1     | 2           | 3           | (asked)     |

If the user wants something different from these defaults, they pick **Custom** and the wizard asks every question.

## Step 3 — auto-detect commands and branches

Pull these from the project, present in a single confirmation step:

### Build / typecheck command
Read the project files:
- If `package.json` exists: look at `scripts.build`. If present, suggest `npm run build`. If a `scripts.typecheck` exists too, prefer that. Otherwise `npm run build`.
- If `Cargo.toml`: suggest `cargo build`.
- If `pyproject.toml` or `setup.py`: suggest `python -m build` or `mypy .` if mypy is configured.
- If `go.mod`: suggest `go build ./...`.
- If `Makefile` has a `build` target: suggest `make build`.
- Otherwise: ask the user free-text.

### Test command
- `package.json` → `scripts.test` → `npm test`
- `Cargo.toml` → `cargo test`
- `pyproject.toml`/`setup.py` → `pytest`
- `go.mod` → `go test ./...`
- `Makefile` has `test` → `make test`
- Otherwise: ask the user free-text.

### Git branches
Detect via Bash:
- Integration: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'` — fall back to `git branch --show-current`, then default `dev`.
- Production: `main` if it exists locally or on remote, else `master`, else fall back to integration branch.

### Project name
Default: the basename of the current directory.

### Confirmation prompt

Present everything detected in a single AskUserQuestion:

> "I detected these settings. Use them or customize?"
> - **Use these** — project: `<name>`, build: `<cmd>`, test: `<cmd>`, integration: `<branch>`, production: `<branch>`
> - **Customize commands** — only edit build/test
> - **Customize branches** — only edit integration/production names
> - **Customize everything** — go through each one

If "Use these" — skip to Step 4.
If anything else — ask only the relevant questions.

## Step 4 — extra question for Swarm only

If the preset was Swarm, ask the exact terminal count (free text, validate 5-20).

## Step 5 — Custom mode (only if Custom preset was chosen)

Walk through the original 13 questions one at a time. Use `AskUserQuestion` everywhere, with the same options as before:

1. Exact terminal count (free text, 2-20).
2. Dedicated planner? Yes / No.
3. Stale-lock TTL — 10 / 15 / 30 / 60 / Custom.
4. Stale-lock policy — auto-clear / warn.
5. Git variant — A / B / none.
6. Integration branch (if git workflow).
7. Production branch (if git workflow).
8. Approval gate — Yes / No.
9. Build command.
10. Test command.
11. Commit format — Conventional / Freeform / None.
12. Project name.

## Step 6 — confirm and write

Summarize ALL final settings (preset choice + everything else, whether asked or defaulted) and ask: "Confirm and write?" One last sanity check.

On confirm, write:

### `.multi-agent/config.json` (COMMITTED — not gitignored)

```json
{
  "version": "1.0.0",
  "project_name": "...",
  "scale_mode": "solo|pair|squad|swarm|custom",
  "terminal_count": 3,
  "has_planner": true,
  "lock_ttl_minutes": 15,
  "stale_lock_policy": "auto-clear|warn",
  "git_variant": "A|B|none",
  "integration_branch": "dev",
  "prod_branch": "main",
  "approval_gate_enabled": true,
  "build_command": "npm run build",
  "test_command": "npm test",
  "commit_format": "conventional|freeform|none",
  "configured_at": "<ISO timestamp>",
  "configured_via": "preset:squad|custom"
}
```

This file is **committed to the repo** so team members get the same settings on clone.

## Step 7 — scaffold coordination files

Create at the repo root (do NOT overwrite if they already exist):

- `active_tasks.md` — copy from `<skill-dir>/templates/active_tasks.md`
- `active_files.md` — copy from `<skill-dir>/templates/active_files.md` (skip in Solo mode)

Patch `.gitignore` (create if missing) — append these lines if not already present:
```
active_tasks.md
active_files.md
```

**Do NOT add `.multi-agent/` to .gitignore** — config.json should be committed. Only the live kanban + lock state is gitignored.

## Step 3 — write config

Write `.multi-agent/config.json` at the repo root with all answers:

```json
{
  "version": "1.0.0",
  "project_name": "...",
  "scale_mode": "solo|pair|squad|swarm",
  "terminal_count": 3,
  "has_planner": true,
  "lock_ttl_minutes": 15,
  "stale_lock_policy": "auto-clear|warn",
  "git_variant": "A|B|none",
  "integration_branch": "dev",
  "prod_branch": "main",
  "approval_gate_enabled": true,
  "build_command": "npm run build",
  "test_command": "npm test",
  "commit_format": "conventional|freeform|none",
  "configured_at": "<ISO timestamp>"
}
```

## Step 4 — scaffold coordination files

Create at the repo root (if they don't already exist — never overwrite existing kanban / lock state):

- `active_tasks.md` — copy from `<skill-dir>/templates/active_tasks.md`
- `active_files.md` — copy from `<skill-dir>/templates/active_files.md` (skip in Solo mode)

Patch `.gitignore` (create if missing) — append these lines if not already present:
```
active_tasks.md
active_files.md
.multi-agent/
```

## Step 8 — append the multi-agent block to CLAUDE.md

Read `<skill-dir>/templates/CLAUDE-section.md`. Interpolate all the `{{PLACEHOLDERS}}`:

- `{{TERMINAL_COUNT}}` — from config
- `{{ROLES_TABLE}}` — generate based on planner Y/N and terminal count
- `{{LOCK_TTL_MINUTES}}` — from config
- `{{STALE_LOCK_POLICY}}` — human readable ("auto-clear" or "warn user before clearing")
- `{{APPROVAL_GATE_BLOCK}}` — full paragraph if enabled; "Disabled — developers commit after their own verification." otherwise
- `{{GIT_VARIANT_NAME}}` — "Variant A (feature branches)" / "Variant B (single integration branch)" / "none"
- `{{GIT_WORKFLOW_BLOCK}}` — short paragraph appropriate to the variant
- `{{BUILD_COMMAND}}`, `{{TEST_COMMAND}}` — from config
- `{{COMMIT_FORMAT_BLOCK}}` — appropriate paragraph

If `CLAUDE.md` exists, append the interpolated block. If it doesn't, create `CLAUDE.md` with just this block (the user can add other rules later).

Wrap the block in the BEGIN/END markers from the template so re-runs can replace it cleanly.

## Step 9 — output terminal intros

For each terminal the user plans to open, print a clearly-fenced block they can copy-paste verbatim into that terminal's first message.

Header format:
```
━━━ TERMINAL <N> (<role>) ━━━
```

Body: interpolate the appropriate intro template:
- Solo mode → `templates/intros/solo-intro.md`
- Planner terminal (T4 in modes with a planner) → `templates/intros/planner-intro.md`
- Developer terminals (T1, T2, T3, …) → `templates/intros/developer-intro.md` with `{{TERMINAL_NUMBER}}` set

Interpolate all `{{PLACEHOLDERS}}` from the config.

After the intros, print a short next-steps summary:

```
✅ Setup complete.
Next steps:
1. Open <N> Claude Code terminals in this project.
2. Paste the matching intro into each as the first message.
3. Each terminal will then read CLAUDE.md and `.multi-agent/config.json` automatically.
4. From the Planner terminal, start dispatching tasks into active_tasks.md.

To verify: run /agents-status here.
To re-configure later: run /multi-agent-init again.
```

## Guardrails

- **Presets bake in defaults — don't ask about them.** Solo / Pair / Squad / Swarm cover 95% of users. Only **Custom** mode asks every question.
- **Auto-detect before asking.** Build commands, test commands, branch names — read the project. Confirm in a single step rather than asking each separately.
- **Show what you detected.** When proposing build/test/branches, list them clearly so the user can spot a mismatch before confirming.
- **Never overwrite existing `active_tasks.md` or `active_files.md` content.** If the files exist, leave them as-is (the user may be re-configuring mid-project and have live state in them).
- **The CLAUDE.md block is the only file `/multi-agent-init` overwrites** — and only between its BEGIN/END markers.
- **`.multi-agent/config.json` is committed, NOT gitignored.** Team members cloning the repo get the same multi-agent settings without re-running the wizard.
- **Final confirmation.** Before writing, summarize the full resolved settings (preset + detected + customized) and ask "Confirm and write?" — one last sanity check.
