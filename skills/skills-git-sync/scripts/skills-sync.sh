#!/usr/bin/env bash
# One daily job: publish this machine's edits, then rebase onto main.
# Silent on success (watchdog pattern); any failure exits non-zero with a marker.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
rc=0
bash "$DIR/skills-push.sh" || rc=1
bash "$DIR/skills-pull.sh" || rc=1
exit "$rc"
