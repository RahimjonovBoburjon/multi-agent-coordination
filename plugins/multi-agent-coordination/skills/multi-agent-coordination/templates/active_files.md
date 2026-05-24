# Active Files — Lock Registry

> File-level lock registry. Append one line per locked file; remove it immediately after the edit completes. This file is **gitignored** — never commit it.

Format: `- <relative/path/from/repo/root> → T<N> @ <ISO-8601-timestamp>`

Where `<N>` is the developer terminal number (`T1`, `T2`, …). The planner uses `P`; planner sub-agents use `P-<short-slug>`.

A lock older than the configured TTL (see `.multi-agent/config.json`) is considered stale and may be auto-cleared or warned about per project policy.

---

<!-- Live locks (append below this line; remove after release): -->

<!-- Examples (delete after first real lock):
- frontend/src/views/admin/Dashboard.vue → T1 @ 2026-05-24T14:32:15+05:00
- backend/src/modules/auth/auth.service.ts → T2 @ 2026-05-24T14:35:02+05:00
- frontend/src/i18n/locales/ru.json → P-pricing-i18n @ 2026-05-24T14:40:00+05:00
-->
