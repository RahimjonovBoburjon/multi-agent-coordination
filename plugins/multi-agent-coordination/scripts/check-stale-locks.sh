#!/usr/bin/env bash
# check-stale-locks.sh — print locks older than the configured TTL
#
# Usage: ./check-stale-locks.sh [path-to-repo-root]
# Defaults to current directory.

set -euo pipefail

REPO_ROOT="${1:-.}"
CONFIG="$REPO_ROOT/.multi-agent/config.json"
LOCKS="$REPO_ROOT/active_files.md"

if [[ ! -f "$CONFIG" ]]; then
  echo "❌ $CONFIG not found. Run /multi-agent-init first." >&2
  exit 1
fi

if [[ ! -f "$LOCKS" ]]; then
  echo "ℹ️  No $LOCKS — nothing to check."
  exit 0
fi

# Extract TTL (in minutes) from config — minimal jq-free parsing
TTL_MIN=$(grep -o '"lock_ttl_minutes"[[:space:]]*:[[:space:]]*[0-9]*' "$CONFIG" \
  | grep -o '[0-9]*$' || echo "15")
TTL_SEC=$((TTL_MIN * 60))
NOW=$(date +%s)

stale_count=0
fresh_count=0
malformed=0

while IFS= read -r line; do
  # Match: - <path> → terminal <label> @ <ISO-timestamp>
  if [[ "$line" =~ ^-[[:space:]](.+)[[:space:]]→[[:space:]]terminal[[:space:]]([^[:space:]]+)[[:space:]]@[[:space:]](.+)$ ]]; then
    path="${BASH_REMATCH[1]}"
    label="${BASH_REMATCH[2]}"
    ts="${BASH_REMATCH[3]}"
    # Try GNU date first, then BSD date
    if lock_epoch=$(date -d "$ts" +%s 2>/dev/null) \
       || lock_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$ts" +%s 2>/dev/null) \
       || lock_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${ts%%+*}" +%s 2>/dev/null); then
      age=$((NOW - lock_epoch))
      age_min=$((age / 60))
      if (( age > TTL_SEC )); then
        echo "⚠️  STALE  terminal $label  $path  (${age_min} min old, TTL ${TTL_MIN} min)"
        stale_count=$((stale_count + 1))
      else
        fresh_count=$((fresh_count + 1))
      fi
    else
      malformed=$((malformed + 1))
    fi
  fi
done < "$LOCKS"

echo ""
echo "─── Summary ───"
echo "Fresh locks:     $fresh_count"
echo "Stale locks:     $stale_count"
[[ $malformed -gt 0 ]] && echo "Malformed lines: $malformed"

if (( stale_count > 0 )); then
  echo ""
  echo "To clear stale locks: run /release-locks --stale in a Claude Code session,"
  echo "or hand-edit $LOCKS to remove the lines above."
  exit 2
fi
