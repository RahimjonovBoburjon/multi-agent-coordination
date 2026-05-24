---
description: Print this terminal's role intro based on saved multi-agent config
allowed-tools: Read, AskUserQuestion
---

# /agent-intro

Print a role-tailored intro for the current Claude Code terminal session. Use this at the start of every new session so each terminal knows what it is.

## Steps

1. **Read** `.multi-agent/config.json` at repo root.
   - If missing, tell the user: "No multi-agent config found. Run `/multi-agent-init` first." Stop.

2. **If Solo mode** (`scale_mode == "solo"`): just print `templates/intros/solo-intro.md`, interpolated with config. Done.

3. **Otherwise, ask which terminal this is.** Use `AskUserQuestion` with options based on terminal count:
   - If `has_planner == true`: include "Planner (T4)" + "Developer T1" + "Developer T2" + … up to `terminal_count - 1` developers.
   - If `has_planner == false`: list "Developer T1" + … + "Developer T<terminal_count>".

4. **Print the matching intro** with all `{{PLACEHOLDERS}}` interpolated from config:
   - Planner → `templates/intros/planner-intro.md`
   - Developer → `templates/intros/developer-intro.md` with `{{TERMINAL_NUMBER}}` set

5. **End with a one-line action prompt** based on role:
   - Planner: "Now reading `active_tasks.md` to see current state…" — then actually read it and summarize.
   - Developer: "Now reading `active_tasks.md` for tasks assigned to T<N>…" — then actually read and report.

## Guardrails

- Don't ask the user any setting questions here — those were answered at `/multi-agent-init` time. If a setting is missing from config, point the user back to `/multi-agent-init`.
- This command should be fast — a single intro + a quick read of the kanban. Not a full status report; that's `/agents-status`.
