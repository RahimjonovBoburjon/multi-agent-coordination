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

### CRITICAL: "Overwrite from scratch" means FULL re-generation

When the user picks "Overwrite from scratch", you MUST regenerate **every** wizard output even if the new settings end up identical to the old config:

- `.multi-agent/config.json` — write fresh
- `CLAUDE.md` block — re-generate the BEGIN/END section using the **current** templates (this is how version upgrades like v1.0.0 → v1.0.1 actually take effect — fresh interpolation with new template strings).
- Re-print the terminal intros.

**Never short-circuit with "settings are identical, skipping regeneration"** — the templates themselves may have changed between plugin versions, and skipping means the user's project stays stuck on the old conventions (e.g. still showing `T4` after we renamed to `P`). The whole point of "overwrite from scratch" is to discard the old artifacts and rebuild from current sources.

If the user wants minimal changes, they pick "update individual settings" instead.

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

### Git branches and branch model

Detect existing branches via Bash:

```bash
git branch -a 2>/dev/null
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

Then **decide the branch model** based on what exists:

- **If only `main` (or only `master`) exists** → single-branch model. Set `integration_branch = prod_branch = main` (or master). Tell the user: "Detected: only `main` branch exists. Daily commits and production will both use `main`."
- **If both `dev` (or `develop`) and `main` exist** → two-branch model. Set `integration_branch = dev`, `prod_branch = main`. Tell the user: "Detected: `dev` for daily commits, `main` for production releases."
- **If neither exists** (fresh repo) → ask the user explicitly.

### Branch model — explicit question (always ask, even if detected)

Even when auto-detected, surface the branch model as a deliberate choice. Use `AskUserQuestion`:

> **Branch model** — where should daily commits go?
>
> - **One branch (`main` only)** — all commits go to `main`. Releases tagged. Simplest. Good for MVP, prototype, internal tools.
> - **Two branches (`dev` + `main`)** — daily commits to `dev`. `dev → main` via release PR, then tag. Safer; lets you test before production deploys.
> - **Other** — pick custom branch names.

If user picks two-branch and only one exists locally, ask: "Create the missing `dev` branch now? (yes / no — I'll skip and you can create it later)."

### Project name
Default: the basename of the current directory.

### Confirmation prompt

After all auto-detection + branch model is decided, present everything in a single AskUserQuestion:

> "I detected/picked these settings. Use them or customize?"
> - **Use these** — project: `<name>`, build: `<cmd>`, test: `<cmd>`, branches: `<integration>` / `<production>` (`<one-branch | two-branch>` model)
> - **Customize commands** — only edit build/test
> - **Customize branches** — re-pick integration / production names
> - **Customize everything** — go through each one

If "Use these" — skip to Step 4.
If anything else — ask only the relevant questions.

## Step 4 — extra question for Swarm only

If the preset was Swarm, ask the exact terminal count (free text, validate 5-20).

## Step 5 — Custom mode (only if Custom preset was chosen)

Walk through these questions one at a time. Use `AskUserQuestion` everywhere with explanatory descriptions — these are the settings most users get wrong, so each option must explain trade-offs.

### 5.1 — Exact terminal count
Free text, validate 2-20.

### 5.2 — Dedicated planner?
- **Yes** — one terminal plans + reviews and NEVER writes code. Approval gate becomes available. Recommended for 3+ terminals.
- **No** — all terminals are equal developers. No approval gate. Faster but less safe.

### 5.3 — Stale-lock TTL
After how many minutes is a held lock considered abandoned (terminal crashed / forgot to release)?
- **10 / 15 / 30 / 60 minutes / Custom**. Default 15. Shorter = faster recovery from crashes; longer = safer when devs do slow edits.

### 5.4 — Stale-lock policy
When a stale lock is detected:
- **Auto-clear** — any terminal removes it silently. Good for solo + pair.
- **Warn only** — terminal prints a warning, asks user before clearing. Safer for squad/swarm.

### 5.5 — Git workflow variant (with full explanations)

Show the user this with `AskUserQuestion`:

> **How should multiple terminals coordinate via git?**
>
> - **Variant B — Direct to Integration Branch** *(recommended for solo / AI / small teams)*
>   Each developer commits directly to one branch (typically `dev`). No per-task feature branches. The Planner approval gate plays the code-review role.
>   - ✅ Pros: simple, fast, no cross-task dependency chaos, clean history, AI-friendly.
>   - ❌ Cons: less per-task git granularity for rollback.
>
> - **Variant A — Feature Branches + PR per task**
>   Each task gets its own branch (`feat/S2-A-...`). Developer pushes branch, opens PR. User merges via GitHub UI.
>   - ✅ Pros: per-task git history; works with GitHub PR review tooling; familiar to traditional teams.
>   - ❌ Cons: cross-task dependencies are a hassle (S2-B can't import from S2-A until S2-A is merged); branch overhead; stale branches multiply.
>
> - **None** — no git workflow management. Manual commits, no protocol.

### 5.6 — Branch model (if variant ≠ None)

> **Branch model** — how many long-lived branches?
>
> - **One branch (`main` only)** — daily commits + production both on `main`. Releases tagged. Simpler.
> - **Two branches (`dev` + `main`)** — daily commits on `dev`. Promotion to `main` via release PR + tag. Safer.

### 5.7 — Integration branch name
If two-branch: default `dev`, ask. If one-branch: skip — use `main`.

### 5.8 — Production branch name
Default `main`. Ask only if two-branch.

### 5.9 — Approval gate enabled?
- **Yes** *(recommended)* — developers wait for Planner approval before commit.
- **No** — developers commit after their own verification.

### 5.10 — Build / typecheck command
Free text. Wizard suggests from auto-detection.

### 5.11 — Test command
Free text. Wizard suggests from auto-detection.

### 5.12 — Commit format
- **Conventional Commits** — `<type>(<scope>): <description>` (feat, fix, refactor, …).
- **Freeform** — clear imperative messages.
- **None** — no convention enforced.

### 5.13 — Project name
Free text. Default = directory basename.

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

## Step 8 — append the multi-agent block to CLAUDE.md (with smart-detect)

This step is the most sensitive — the user's `CLAUDE.md` might already have content. Treat it carefully.

### 8.1 — Read existing CLAUDE.md (if any)

If `CLAUDE.md` already exists at the project root, read it. If it doesn't exist, skip to 8.3 (just create a new file).

### 8.2 — Smart-detect overlapping sections

Scan the existing CLAUDE.md for headings (lines starting with `## ` or `### `) and check for overlap with the topics our block introduces. Look for headings matching any of these patterns (case-insensitive):

- "multi-agent" / "agents" / "terminals" / "parallel"
- "git workflow" / "branch" / "branching" / "release"
- "commit" / "commit format" / "conventional"
- "approval" / "review" / "code review"
- "lock" / "locking" / "file lock"
- "kanban" / "tasks" / "task board"

Also check for the existing BEGIN/END markers in either form:
- New format (v1.0.3+): `<!--MAC-BLOCK:BEGIN-->` … `<!--MAC-BLOCK:END-->`
- Legacy format (v1.0.0–v1.0.2): `<!-- BEGIN: multi-agent-coordination -->` … `<!-- END: multi-agent-coordination -->`

If you find legacy markers, replace the whole block with a fresh interpolation that uses the new marker format.

### 8.3 — Decide what to do

**Case A — Existing markers found:**
Replace the content between the BEGIN and END markers (either format — new `<!--MAC-BLOCK:BEGIN-->` or legacy `<!-- BEGIN: multi-agent-coordination -->`) with the freshly interpolated block. Always emit the new marker format. Leave everything else untouched. No confirmation needed (this is the re-run case).

**Case B — No markers, but overlapping headings detected:**
List the overlapping headings to the user. Use `AskUserQuestion`:

> Found N potentially overlapping sections in your CLAUDE.md:
> - "## Git Workflow" (line 42)
> - "## Commit conventions" (line 88)
>
> The multi-agent block also covers these topics. What to do?
>
> - **Append at end anyway** — your existing sections stay; our block goes at the bottom. You can manually consolidate later. *(default safe)*
> - **Show the new block, let me decide manually** — print the interpolated block, skip writing CLAUDE.md. User merges by hand.
> - **Skip CLAUDE.md update entirely** — don't touch CLAUDE.md. Only write config + kanban + locks files. **You should manually add rules from `references/` later.**

**Case C — No markers, no overlapping headings:**
Append the block to the end of the existing CLAUDE.md, wrapped in BEGIN/END markers. No confirmation needed.

**Case D — CLAUDE.md doesn't exist:**
Create CLAUDE.md with just the interpolated block wrapped in BEGIN/END markers.

### 8.4 — Interpolation

In all cases that write, interpolate the template (`<skill-dir>/templates/CLAUDE-section.md`):

- `{{TERMINAL_COUNT}}` — from config
- `{{ROLES_TABLE}}` — generate based on `has_planner` and `terminal_count` (rows: T1, T2, …, plus a final P row if has_planner). Always use `P` as the planner label, never `T<count>`.
- `{{LOCK_TTL_MINUTES}}` — from config
- `{{STALE_LOCK_POLICY}}` — human readable ("auto-clear" or "warn user before clearing")
- `{{APPROVAL_GATE_BLOCK}}` — full paragraph if enabled; "Disabled — developers commit after their own verification." otherwise
- `{{GIT_VARIANT_NAME}}` — "Variant A (feature branches)" / "Variant B (single integration branch)" / "none"
- `{{GIT_WORKFLOW_BLOCK}}` — short paragraph appropriate to the variant + branch model (one-branch vs two-branch). If integration_branch == prod_branch, say "single-branch model"; else two-branch with `dev → main` PR for releases.
- `{{BUILD_COMMAND}}`, `{{TEST_COMMAND}}` — from config
- `{{COMMIT_FORMAT_BLOCK}}` — appropriate paragraph

### Marker rules (CRITICAL — read carefully)

Always wrap the block in `<!--MAC-BLOCK:BEGIN-->` and `<!--MAC-BLOCK:END-->` markers (separate lines, with one blank line between the BEGIN marker and the `## 🚨 Multi-Agent Coordination` heading).

**Important — do NOT use the legacy marker `<!-- BEGIN: multi-agent-coordination -->`.** Earlier versions had a transcription bug where Claude would merge the marker's tail (`coordination -->`) into the heading text on the next line, producing garbled output like `## 🚨 Multi-Agent Coordinationnation -->`. The shorter, distinct `MAC-BLOCK` marker avoids this collision.

When writing the CLAUDE.md block, follow this structure **byte-for-byte**:

```
<!--MAC-BLOCK:BEGIN-->

## 🚨 Multi-Agent Coordination

<the rest of the interpolated block>

<!--MAC-BLOCK:END-->
```

Note the blank line between `<!--MAC-BLOCK:BEGIN-->` and the heading. This visual separation also prevents accidental string merging during write.

## Step 9 — output terminal intros (VERBATIM from templates)

For each terminal the user plans to open, print a clearly-fenced block they can copy-paste verbatim into that terminal's first message.

### Header format (exact)

Use these exact headers — no alternative phrasings:

```
━━━ T1 (Developer) ━━━     ← for developer terminals (T1, T2, T3, …)
━━━ P (Planner) ━━━         ← for the planner terminal (only if has_planner)
━━━ SOLO ━━━                ← for solo mode
```

**Never use `TERMINAL 1`, `TERMINAL 4`, `Terminal A`, or any other variation.** The header is literally `━━━ T<N> (Developer) ━━━` or `━━━ P (Planner) ━━━`. Lower-case `t`, upper-case `T`, prefixes like "Terminal" — all WRONG. Match the format above byte-for-byte.

### Numbering

- Developer numbers run from `T1` up to `T<terminal_count - 1>` if `has_planner` is true (one slot belongs to the planner), or up to `T<terminal_count>` if `has_planner` is false.
- The planner is ALWAYS labeled `P` regardless of how many terminals there are. Not `T3`, not `T4`, not `T<count>` — `P`.

### Body — PRINT THE TEMPLATE VERBATIM

This is the most-violated step. You MUST:

1. **Read** the appropriate template file:
   - Solo mode → `templates/intros/solo-intro.md`
   - Planner terminal → `templates/intros/planner-intro.md`
   - Developer terminal → `templates/intros/developer-intro.md`

2. **Substitute** every `{{PLACEHOLDER}}` with the value from `.multi-agent/config.json` (and `{{TERMINAL_NUMBER}}` with the developer's number for developer intros).

3. **Print the entire substituted template, verbatim, from line 1 to the last line.** Do not:
   - Summarize the template into a shorter version.
   - Paraphrase the responsibilities into a one-liner.
   - Skip the "You MAY / You MUST NOT" sections.
   - Replace markdown headings with prose.
   - Compress multi-paragraph sections into bullet points.

The intro file is ~50 lines of structured guidance. The output block should also be ~50 lines. If your block is 5 lines, you summarized — start over and print the actual template.

Why this matters: the intro is what onboards the receiving terminal. If you summarize, the terminal misses critical rules (lock protocol details, commit format constraints, what they MUST NOT do). The receiving Claude session then improvises and the coordination protocol breaks down.

### Handling identical build and test commands

If `config.build_command == config.test_command` (this happens when the project has no test script and the user reuses the build command for both), do NOT print phrases like "run `npm run build` and `npm run build` until both pass" — that's nonsense. Instead:

- Replace any " and `{{TEST_COMMAND}}`" with empty string.
- Replace " until both pass" with " until it passes".
- Replace "build and test" with "build" in flowing prose.

End result: "run `npm run build` until it passes." Clean.

### Final check before declaring "setup complete"

After printing the intros, scan your own output. Confirm:

- [ ] Every developer header is `━━━ T<N> (Developer) ━━━` — no other format.
- [ ] If `has_planner`, exactly one block has header `━━━ P (Planner) ━━━` — never `T4` or `T<count>`.
- [ ] Each developer intro body contains the line "You are Terminal {{TERMINAL_NUMBER}} (Developer) for this project" with the placeholder substituted (e.g. "You are Terminal 1 (Developer) for this project").
- [ ] The planner intro body contains "You are the Planner (P) for this project" or "You are the Planner".
- [ ] No "the Planner (the Planner (P))" double-parens — substitute placeholders so the phrasing reads naturally.
- [ ] If build_command == test_command, no `run X and X` redundancies — collapse to a single command form.
- [ ] No intro body is shorter than ~40 lines of substituted content.

If any check fails, re-print the offending block correctly before moving on.

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
- **Always ask about branch model explicitly.** Even when auto-detected, surface "one-branch vs two-branch" as a deliberate choice — the user may want to set up a dev branch even if only main exists.
- **Explain Variant A vs B with trade-offs.** When the user picks Custom mode, the variant question must include pros/cons (cross-task dependency chaos for A; less per-task history for B). Don't just list "A or B" — that's meaningless without context.
- **Never overwrite existing `active_tasks.md` or `active_files.md` content.** If the files exist, leave them as-is (the user may be re-configuring mid-project and have live state in them).
- **The CLAUDE.md block is the only file `/multi-agent-init` overwrites — and only between its BEGIN/END markers.** If the user has overlapping sections (Git Workflow, Commit Format, etc.), warn them first and let them choose (append, skip, or merge manually).
- **`.multi-agent/config.json` is committed, NOT gitignored.** Team members cloning the repo get the same multi-agent settings without re-running the wizard.
- **Planner is always labeled `P`, never `T<N>`.** Developer labels are `T1`, `T2`, …, `T<n>`. This is the rule in intros, lock files, kanban entries, and the CLAUDE.md roles table.
- **Final confirmation.** Before writing, summarize the full resolved settings (preset + detected + customized) and ask "Confirm and write?" — one last sanity check.
