# Troubleshooting

Common breakage and recovery recipes.

## Stale locks after a terminal crash

**Symptom:** `active_files.md` has lines from a terminal that's no longer running. Other terminals are waiting indefinitely.

**Fix:**
1. In any terminal, run `/agents-status` — it lists stale locks (older than configured TTL).
2. If the crashed terminal is back online, run `/release-locks` in that terminal — it removes every line tagged with the current session's terminal number.
3. If the terminal is gone for good, hand-edit `active_files.md` and delete the orphaned lines. Note which terminal number was lost so subsequent sessions don't reuse it accidentally.

**Prevention:** set the TTL low enough (15 min default) that orphaned locks self-expire before they bottleneck the team.

## Two terminals collide on the same task

**Symptom:** T1 and T2 both think they own `S2-A`.

**Fix:**
1. Planner reads `active_tasks.md` — only one entry per task ID should exist. If two entries appear (with different assignees), the planner reconciles by reading both terminals' chat logs and picking the one that started first.
2. The other terminal moves its duplicate work to a new task ID (`S2-A2`) or discards if the work is overlapping.

**Prevention:** the planner is the only writer in the TODO column. Developers move tasks **between** columns; they don't add new tasks themselves.

## Conflicts during `git pull --rebase`

**Symptom:** Variant B — `git pull --rebase origin <integration-branch>` fails with conflict before the developer can push.

**Fix:**
1. Resolve the conflict in the working tree.
2. Re-run the project's typecheck + tests + build to ensure nothing regressed.
3. Ask the planner to re-verify (this is essentially a new diff).
4. `git rebase --continue && git push origin <integration-branch>`.

**Prevention:** file locks usually prevent this. A conflict here means either (a) someone edited without locking, or (b) two terminals touched the same file at exactly the same TTL boundary. Tighten the lock discipline.

## CI goes red right after a push

**Symptom:** developer pushed after approval; CI fails on the integration branch.

**Fix:**
1. The committing terminal owns the fix **immediately** — don't wait for the planner.
2. If the fix is small and obvious (a missed import, typo), commit a follow-up directly **without** approval — this counts as "reverting a regression actively breaking the integration branch" (see `references/approval-gate.md` exceptions).
3. If the fix is non-trivial, `git revert <bad-commit> && git push`, then file a proper task to redo it.

**Prevention:** the planner should always run the project's build (not just typecheck) before approval — vite, webpack, swc, etc. often catch issues that `tsc --noEmit` misses.

## Two tasks need to edit the same file

**Symptom:** S2-A (T1) and S2-B (T2) both need `frontend/src/router/index.ts`.

**Fix:** the planner assigns them serially, not in parallel. Either:
- Assign both to the same terminal so the lock is held continuously, or
- Sequence: T1 finishes S2-A → approved → commits → releases lock → T2 starts S2-B.

**Prevention:** at task-dispatch time, the planner scans the file lists of all pending tasks. Overlapping file lists go to the same terminal.

## Sub-agent forgot to release a lock

**Symptom:** a `terminal 4-<slug>` lock persists after the planner's sub-agent finished.

**Fix:** the planner removes the orphaned line by hand. The sub-agent doesn't have a slash command of its own.

**Prevention:** in the planner's prompt to the sub-agent, end with "release all locks under your label before reporting back."

## Planner accidentally edited a source file

**Symptom:** the planner used `Edit` or `Write` against repo source code despite the role rule.

**Fix:**
1. Stop. Move the change to a sub-agent or assign it as a task to a developer terminal — even if the change is trivial.
2. Revert the planner's edit locally before relaying the task: `git checkout -- <file>`. (This is safe because the planner never committed.)
3. The developer terminal then re-implements via the proper flow.

**Prevention:** when in doubt, ask "should this be a task?" before editing.

## Approval gate keeps blocking on the same minor issue

**Symptom:** the planner blocks 3 tasks in a row for the same lint warning / convention drift.

**Fix:** either (a) the planner adds the convention to CLAUDE.md so future tasks pick it up at session start, or (b) the planner relaxes their criterion if it's nitpicky.

**Prevention:** every "blocked" reason that recurs should turn into a CLAUDE.md rule. Codify, don't repeat-block.

## The integration branch diverged from production

**Symptom:** integration has weeks of unmerged work; the production branch is far behind.

**Fix:** schedule a release.
1. Open the integration → production PR.
2. Resolve any merge conflicts.
3. CI green.
4. User merges, tags new version.
5. Back-merge the tag commit into integration so future PRs are clean.

**Prevention:** release on a cadence (weekly / bi-weekly), not when the user remembers. Add a recurring planner task: "Open release PR if integration has > N un-released commits."

## A terminal lost its session identity

**Symptom:** a developer terminal asks "wait, am I T1 or T2 again?"

**Fix:** the user is the source of truth. Read the last few entries in `active_tasks.md` — the terminal number is in the task assignments. Match it to the work-in-progress on the local working tree (which files are dirty?). If still ambiguous, ask the user.

**Prevention:** run `/agent-intro` at the start of every new session — it asks the user to confirm the terminal number and prints the role intro.

## Setup wizard's choices no longer fit the project

**Symptom:** the project outgrew solo mode; you now want pair mode. Or the TTL is too short.

**Fix:** re-run `/multi-agent-init`. The wizard detects an existing `.multi-agent/config.json` and asks whether to overwrite or update individual settings. It does NOT delete existing kanban / lock state — only the config.

**Prevention:** the wizard is idempotent. Re-run whenever needs change.
