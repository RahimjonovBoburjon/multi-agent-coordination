---
description: Claim a TODO task as the current developer terminal (move to IN PROGRESS, lock files)
allowed-tools: Read, Edit, AskUserQuestion
---

# /claim-task

Move a task from TODO to IN PROGRESS for this terminal, and pre-acquire the file locks listed in its brief.

## Steps

1. **Read** `.multi-agent/config.json`. If missing, stop.

2. **Read** `active_tasks.md`. List all entries in 🟢 IN PROGRESS / TODO that are assigned to "T<your-number>" (or unassigned).
   - Ask the user: "Which terminal are you?" (use saved session number if known).
   - Filter the TODO list to that assignee.

3. **Ask the user**: "Which task to claim?" Show the filtered list as options.

4. **Read the chosen task's `Files:` and `Locks needed:` lines**.

5. **Read `active_files.md`.** For each file in the lock list:
   - If already locked by another terminal with a fresh timestamp: STOP. Print a conflict warning ("<path> is locked by terminal X — wait or pick another task.") and exit. Do NOT partially lock.
   - If listed but stale (older than TTL) and policy is auto-clear: remove the stale line.
   - If listed but stale and policy is warn-only: ask user before clearing.
   - If free: prepare to append.

6. **Acquire all locks atomically** — append all the new lines to `active_files.md` in one edit.

7. **Confirm** to the user: "Claimed `<TASK-ID>` and acquired locks on N files. You can now Edit / Write to them."

## Guardrails

- This command is optional convenience. The full protocol (one lock per file, acquired right before each edit) is still valid and safer for long tasks where you don't know all files upfront.
- Use this when the task brief lists a known set of files and you want to fail-fast on lock conflicts before starting work.
- If you abandon the task without finishing, run `/release-locks` to clean up.
