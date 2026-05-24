---
description: Show the multi-agent kanban, active locks, and stale-lock warnings
allowed-tools: Read, Bash
---

# /agents-status

Print a one-screen status of the multi-agent coordination state.

## Steps

1. **Read** `.multi-agent/config.json` at repo root. If missing, tell the user: "No multi-agent config found. Run `/multi-agent-init` first." Stop.

2. **Read** `active_tasks.md` and group entries by column (🟢 / 🟡 / 🟠 / ✅). Count items per column. For ✅ DONE, only list the last 5 entries.

3. **Read** `active_files.md`. Parse each lock line. For each lock, compute `age = now - timestamp`. Mark as **STALE** if `age > config.lock_ttl_minutes`.

4. **Render** the status report. Suggested layout:

```
═══ Multi-Agent Status — <project_name> ═══
Mode: <scale_mode>  ·  Terminals: <terminal_count>  ·  Planner: <yes/no>
Lock TTL: <N> min  ·  Policy: <auto-clear|warn>  ·  Git: <variant>

── Kanban ──
🟢 IN PROGRESS / TODO  (3)
  • S2-A — Active Users tile  (T1)
  • S2-B — Refund endpoint    (T2)
  • S2-C — i18n key codegen   (T3)

🟡 AWAITING REVIEW  (1)
  • S1-D — JWT secret rotation  (T2)  — submitted 12 min ago

🟠 BLOCKED  (1)
  • S0-C — Telegram retry  (T2)  — needs decision

✅ DONE  (last 5)
  • S1-C ✓ T1 — abc1234
  • S1-B ⚠ T3 — def5678
  …

── Active Locks ──
  T1  frontend/src/views/admin/Dashboard.vue        (acquired 3 min ago)
  T2  backend/src/modules/auth/auth.service.ts     (acquired 8 min ago)
  P-pricing  frontend/src/i18n/locales/ru.json   ⚠ STALE — 22 min old

── Stale locks ──
  ⚠ 1 stale lock detected.
  Policy: warn user before clearing.
  Run /release-locks to remove locks held by this terminal,
  or hand-edit active_files.md to clear orphaned locks.
```

5. **If no stale locks**, omit the stale-locks section.

6. **If `active_files.md` is empty**, print "No active locks."

7. **If `active_tasks.md` has empty sections**, print "(none)" under each empty column header.

## Notes

- Compute timestamps using ISO-8601 parsing. The lock format is `- <path> → T<N> @ <ISO-timestamp>` (developers) or `- <path> → P[-slug] @ <ISO-timestamp>` (planner / planner sub-agents).
- Be tolerant of minor formatting drift — try to parse, skip lines that don't match, and report at the bottom: "N malformed lock lines skipped."
- Read-only command — never write to any file. If the user wants to clear stale locks, point them to `/release-locks` or hand-editing.
