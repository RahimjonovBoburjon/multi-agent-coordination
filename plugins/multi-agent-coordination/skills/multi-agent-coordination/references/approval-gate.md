# Approval Gate

The mandatory pre-commit review by the planner. Prevents broken work from reaching the integration branch.

## The rule

> Developer terminals (T1, T2, T3, …) must **never** run `git add` / `git commit` / `git push` / `gh pr create` until the planner has reviewed the uncommitted work and the user has relayed an explicit approval message.

## Why this exists

The planner is the architect. They verify the work against the original brief, run the app as a real user, check for regressions in related code paths, and confirm typecheck / tests / build are green. Auto-committing before this review means broken work reaches the integration branch before anyone notices, then has to be reverted or fixed-on-top — far more cleanup than the review costs.

## Developer flow (T1 / T2 / T3)

When you finish implementing a task on the integration branch working tree:

1. Run the project's typecheck + test + build commands (configured at setup, surfaced in the intro).
   - Build (not just typecheck) catches bundler-only failures like vite's `noUnusedLocals`.
2. Release all your file locks in `active_files.md`.
3. Move your task in `active_tasks.md` from 🟢 IN PROGRESS to 🟡 AWAITING REVIEW with:
   - Files changed (paths + 1-line summary per file)
   - Verify checklist (what passed locally)
   - Anything you decided to skip / leave for follow-up
4. Tell the user in chat: `<TASK-ID> is ready for review.`
5. **STOP.** Do not stage, commit, or push. Wait.
6. When the user relays "approved `<TASK-ID>`":
   - `git fetch origin && git pull --rebase origin <integration-branch>` (catch any concurrent commits from other terminals)
   - `git add <specific-files>` (never `-A` / `.`)
   - `git commit -m "<type>(<scope>): <description>"` (Conventional Commits if configured)
   - Variant B: `git push origin <integration-branch>`
   - Variant A: push the feature branch and `gh pr create`
   - Move the task to ✅ DONE with the commit hash.
7. If the user relays "blocked `<TASK-ID>`: `<reason>`", fix, return to AWAITING REVIEW.

## Planner flow

When a developer announces a task is awaiting approval:

1. Read the entry in `active_tasks.md` to confirm the brief.
2. Read the uncommitted diff: `git diff` (and `git status` for untracked).
3. Verify:
   - Typecheck + unit tests + build (run them yourself; don't trust the developer's "ran locally" line).
   - Manual smoke as a real user — start the dev server, navigate, click. Use the browser MCP if installed. For backend changes, hit the endpoint with curl / Postman / similar.
   - Look for regressions in related code paths (not just the diff).
4. Output the structured review report (see `references/terminal-roles.md`).
5. End with one of:
   - ✅ Approve: `approved <TASK-ID>. Notes: …` — user copy-pastes to dev terminal.
   - ⚠ Approve with notes: same + list non-blocking follow-up tasks.
   - 🔴 Block: `blocked <TASK-ID>. Reason: <X>. Fix: <Y>.`
6. The planner does NOT commit or push itself. The developer does the git operations after receiving approval.

## If a bad commit lands on the integration branch

The planner verifies in browser / curl after every commit. If a regression is caught:

1. Planner instructs the user: "Relay `revert <commit-hash>` to a dev terminal."
2. Dev runs `git revert <commit-hash> && git push origin <integration-branch>`.
3. **No planner re-approval needed for the revert itself** — it's a safety operation.
4. File a proper fix task in 🟢 IN PROGRESS so the work isn't lost.

## Exceptions (commit without approval allowed)

- **Pure docs / planning files** — `active_tasks.md` (gitignored anyway), `CLAUDE.md` edits, ADR / planning markdown, comments-only changes. Can't break the app.
- **Emergency hotfixes the user explicitly authorizes** — user message must say "skip review — hotfix" or similar. The dev still commits; just skips the gate.
- **Reverting a regression actively breaking the integration branch** — when user explicitly says "revert now."

Otherwise: **no commit without approval. No exceptions for "small" or "obvious" changes.** Small obvious changes have caused more regressions than complex ones — the gate is there because everyone underestimates how risky their own diffs feel.

## When the gate is configured OFF

If the user picked "approval gate: no" at setup, this whole document is skipped. Each developer terminal commits after its own typecheck + tests + manual verification. The `AWAITING REVIEW` column still exists as a kanban convenience but does not block commits. **Recommended only for trusted solo-pair workflows on greenfield projects.**
