#!/usr/bin/env bash
# Rebase this machine onto main. Read-only with respect to main; local work is kept.
# If a rebase conflicts the script aborts and reports a stable marker.
set -u
. "$(dirname "$0")/lib.sh"
cd "$SKILLS_DIR" || exit 1

git fetch origin main >/dev/null 2>&1 || { echo "SKILLS_SYNC_FETCH_FAILED" >&2; exit 1; }

if git rebase --autostash origin/main >/dev/null 2>&1; then
  exit 0
fi

git rebase --abort >/dev/null 2>&1
echo "SKILLS_SYNC_CONFLICT_NEEDS_HERMES" >&2
git diff --name-only --diff-filter=U >&2 2>/dev/null
exit 1
