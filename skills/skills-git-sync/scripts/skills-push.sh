#!/usr/bin/env bash
# Commit local skill changes and push them to this machine's own branch.
# Never writes to main; main is merged server-side by GitHub Actions.
set -u
. "$(dirname "$0")/lib.sh"
cd "$SKILLS_DIR" || exit 1

NAME="$(resolve_machine_name)"
valid_machine_name "$NAME" || die "invalid machine name '$NAME' (set SKILLS_MACHINE or ~/.hermes-skills-machine)"

[ -z "$(git status --porcelain)" ] && exit 0

git add -A
git commit -m "skills: sync $(date '+%F %H:%M')" >/dev/null 2>&1 || { echo "COMMIT_FAILED" >&2; exit 1; }

if git push origin "HEAD:refs/heads/machine/$NAME" >/dev/null 2>&1; then
  exit 0
fi
echo "PUSH_FAILED" >&2
exit 1
