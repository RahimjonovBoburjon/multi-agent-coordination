# Git Workflow Variants

Pick one at `/multi-agent-init` time. They differ in how isolated each task's work is.

## Variant A — feature branches (per-task isolation)

Each task gets its own branch: `feat/<task-id>-<slug>`, `fix/<task-id>-<slug>`, etc. Developer pushes to that branch and opens a PR. Planner reviews on GitHub; user merges.

### Daily flow

1. Developer claims a task in TODO.
2. Developer creates a feature branch from the integration branch: `git checkout -b feat/S2-A-active-users-tile`.
3. Locks files, edits, runs verification.
4. Moves task to AWAITING REVIEW.
5. After planner approval is relayed:
   - `git push -u origin feat/S2-A-active-users-tile`
   - `gh pr create --base <integration-branch> --head feat/S2-A-active-users-tile`
6. User merges the PR (squash or merge commit per project policy).
7. Developer deletes the local + remote feature branch.
8. Move task to DONE with PR number + merge commit hash.

### When Variant A is the right choice

- Project already uses PR review tooling and the team is used to it.
- You want per-task git history for rollback granularity.
- Tasks are mostly independent and rarely cross-depend on each other's new files.

### Watch out

- **Cross-task dependency chaos.** If S2-A creates a file that S2-B imports, S2-B's branch fails CI in isolation. Fix: merge S2-A first, rebase S2-B onto integration, then PR. The planner must dispatch dependent tasks serially, not in parallel.
- **Stale branches multiply.** Auto-delete branches on merge to keep the remote clean.
- **Conflicts on the lock file.** `active_files.md` is gitignored so it doesn't conflict, but `active_tasks.md` is also gitignored — no cross-branch conflicts there either.

## Variant B — single integration branch (recommended)

All developers commit directly to one integration branch (typically `dev`). No per-task feature branches.

### Daily flow

1. Developer claims a task in TODO.
2. Locks files on the integration branch working tree, edits, runs verification.
3. Moves task to AWAITING REVIEW.
4. After approval:
   - `git fetch origin && git pull --rebase origin <integration-branch>` (catch peer commits)
   - `git add <specific-files>` (never `-A`)
   - `git commit -m "<type>(<scope>): <description>"`
   - `git push origin <integration-branch>`
5. CI runs on push. If CI goes red, the committing terminal owns the fix immediately.
6. Move task to DONE with commit hash.

### Why Variant B is the recommended default

- File-level isolation between concurrent terminals is enforced via `active_files.md` locks — NOT branches.
- The approval gate already plays the role of code review; PRs would be redundant ceremony.
- Single-user reality + AI assistants don't need enterprise-team branching.
- Eliminates the cross-task dependency chaos described above.

### Release flow (integration → production)

When the user decides an integration-branch snapshot is deploy-ready:

1. Open PR: `gh pr create --base <prod-branch> --head <integration-branch> --title "release: v0.x.y" --body "<release notes>"`
2. CI must be green.
3. **User merges the PR** via merge commit (preserves integration's commit history on prod). Planner never merges.
4. Tag immediately: `git tag v0.x.y && git push origin v0.x.y`
5. Planner may write the release notes for the PR body.

### Hotfix flow (when prod is broken and integration has unrelated WIP)

1. Create a temporary `hotfix/<slug>` branch off the production branch.
2. Fix + commit + push.
3. PR to production, user merges, tag patch version.
4. Back-merge via PR `sync/hotfix-vX.Y.Z-back-to-<integration>` into integration.

### Critical rules (Variant B)

- **No `feat/*`, `fix/*`, `chore/*` branches for daily work.** Only `hotfix/*` (rare) and short-lived release / sync PR branches.
- **Direct push to production is FORBIDDEN.** Integration → production only via PR + merge commit + tag.
- **Approval gate is still mandatory** before every commit to the integration branch. Variant B drops feature branches, NOT the review gate.
- **Pull before push:** `git pull --rebase origin <integration-branch>` first to avoid conflicts with peer terminals.
- **Conflicts get resolved by the committing terminal.** File locks should prevent most. If a conflict still happens, rebase + retest + ask planner to re-verify before pushing.
- **Reverts are first-class:** `git revert <hash> && git push origin <integration-branch>`. No planner re-approval needed for the revert itself.

## Commit format

If the user picked Conventional Commits at setup:

```
<type>(<scope>): <description>
```

Common types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`, `perf`, `build`, `ci`.

Scope is project-specific — the wizard does NOT prescribe a scope list. Pick scopes that match your module boundaries (e.g. `auth`, `dashboard`, `ui`, `db`, `deps`).

If the user picked freeform commits, just write clear imperative messages — no special structure required.

## Versioning (semver)

Tag the production branch only when it represents something deployable.

- `MAJOR.MINOR.PATCH` — `v0.x.y` for pre-1.0, `v1.0.0` for first production release.
- Bump `MINOR` for features.
- Bump `PATCH` for hotfixes.
- Not every production-branch merge needs a tag — only release-worthy snapshots.

## Branch protection (when available)

If the project uses GitHub:

- Enable branch protection on production: PR required, linear history, status checks, no force push, no deletion.
- Enable branch protection on integration: status checks, no force push. (PR-required can be relaxed since developers commit directly.)
- On GitHub Free for private repos, rulesets exist but are not enforced — honor system. Upgrade or move public if enforcement matters.
