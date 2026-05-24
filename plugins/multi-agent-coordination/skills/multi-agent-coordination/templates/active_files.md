# Active Files — Lock Registry

> File-level lock registry. Append one line per locked file; remove it immediately after the edit completes. This file is **gitignored** — never commit it.

Format: `- <relative/path/from/repo/root> → terminal <N> @ <ISO-8601-timestamp>`

Sub-agents spawned by the planner lock under: `terminal 4-<short-slug>`.

A lock older than the configured TTL (see `.multi-agent/config.json`) is considered stale and may be auto-cleared or warned about per project policy.

---

<!-- Live locks (append below this line; remove after release): -->

<!-- Examples (delete after first real lock):
- frontend/src/views/admin/Dashboard.vue → terminal 1 @ 2026-05-24T14:32:15+05:00
- backend/src/modules/auth/auth.service.ts → terminal 2 @ 2026-05-24T14:35:02+05:00
- frontend/src/i18n/locales/ru.json → terminal 4-pricing-i18n @ 2026-05-24T14:40:00+05:00
-->
