#!/usr/bin/env bash
# status.sh — quick terminal status: config summary + kanban counts + lock count
#
# Usage: ./status.sh [path-to-repo-root]

set -euo pipefail

REPO_ROOT="${1:-.}"
CONFIG="$REPO_ROOT/.multi-agent/config.json"
TASKS="$REPO_ROOT/active_tasks.md"
LOCKS="$REPO_ROOT/active_files.md"

if [[ ! -f "$CONFIG" ]]; then
  echo "❌ $CONFIG not found. Run /multi-agent-init first." >&2
  exit 1
fi

# Pull a few config values via simple grep
get_str() { grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$CONFIG" | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/' || echo ""; }
get_num() { grep -o "\"$1\"[[:space:]]*:[[:space:]]*[0-9]*" "$CONFIG" | grep -o '[0-9]*$' || echo ""; }

project_name=$(get_str "project_name")
mode=$(get_str "scale_mode")
count=$(get_num "terminal_count")
ttl=$(get_num "lock_ttl_minutes")
variant=$(get_str "git_variant")
integ=$(get_str "integration_branch")

# Count kanban sections
count_section() {
  local marker="$1"
  if [[ ! -f "$TASKS" ]]; then echo 0; return; fi
  awk -v m="$marker" '
    /^## / { in_section = ($0 ~ m) ? 1 : 0; next }
    in_section && /^### / { c++ }
    END { print c+0 }
  ' "$TASKS"
}

todo=$(count_section "IN PROGRESS")
review=$(count_section "AWAITING REVIEW")
blocked=$(count_section "BLOCKED")
done=$(count_section "DONE")

# Count locks (non-comment, non-empty lines starting with "- ")
lock_count=0
if [[ -f "$LOCKS" ]]; then
  lock_count=$(grep -cE '^- .+→ terminal' "$LOCKS" || echo 0)
fi

cat <<EOF
═══ Multi-Agent Status — ${project_name:-(unnamed)} ═══
Mode: $mode  ·  Terminals: $count  ·  TTL: ${ttl}min  ·  Git: $variant ($integ)

Kanban:  🟢 $todo TODO  ·  🟡 $review review  ·  🟠 $blocked blocked  ·  ✅ $done done
Locks:   $lock_count active

For details, run /agents-status in a Claude Code session.
For stale locks, run ./check-stale-locks.sh
EOF
