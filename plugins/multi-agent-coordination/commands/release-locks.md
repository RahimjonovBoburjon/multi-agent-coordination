---
description: Release all file locks held by this terminal in active_files.md
allowed-tools: Read, Edit, AskUserQuestion
---

# /release-locks

Remove every line in `active_files.md` whose terminal label matches the current session. Use this on clean session exit, or to recover from a crash.

## Steps

1. **Read** `.multi-agent/config.json`. If missing, stop and tell the user to run `/multi-agent-init`.

2. **Read** `active_files.md`. Parse lines.

3. **Ask the user**: "Which terminal label should I release locks for?"
   Provide options based on config (`T1`, `T2`, …, plus `P` and any `P-*` sub-agent labels visible in the file).

4. **Show the lines that match** and confirm before deleting:
   ```
   I will remove these lines from active_files.md:
   - <path-1> → T2 @ 2026-05-24T...
   - <path-2> → T2 @ 2026-05-24T...
   Confirm? (yes / no)
   ```

5. **If confirmed**, edit `active_files.md` to delete exactly those lines. Preserve all other lines (other terminals' locks).

6. **If the user picked a sub-agent label** (`P-*`), only match lines with that exact label, not all `P-*`.

7. **Report**: "Released N locks for <label>."

## Optional — stale lock cleanup mode

If the user invokes `/release-locks --stale`, additionally:

1. Compute age of each remaining lock against `config.lock_ttl_minutes`.
2. List stale locks (any terminal).
3. If `config.stale_lock_policy == "auto-clear"`, remove them after confirmation.
4. If `policy == "warn"`, just print the list and tell the user to clear by hand or rerun without `--stale`.

## Guardrails

- Never remove a line that doesn't match the requested label.
- Always confirm before editing. Lock files are shared state; an accidental over-delete blocks other terminals.
- If the file is empty after deletion, leave the template comments intact — don't wipe the file header.
