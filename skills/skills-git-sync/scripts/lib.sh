#!/usr/bin/env bash
# Shared helpers for the Hermes skills sync scripts.
set -u

PROXY="${SKILLS_PROXY:-$(cat "$HOME/.hermes-skills-proxy" 2>/dev/null | head -1 | tr -d '\r\n')}"
HERMES_DIR="${HERMES_HOME:-${LOCALAPPDATA:-$HOME}/hermes}"
# Running from _sync/ inside the repo, or from the installed copy in $HERMES_DIR/scripts.
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../_sync/lib.sh" ]; then
  SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
else
  SKILLS_DIR="${SKILLS_DIR:-$HERMES_DIR/skills}"
fi
[ -n "$PROXY" ] && export HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY"
export GIT_TERMINAL_PROMPT=0
die() { echo "$*" >&2; exit 1; }

# Precedence: SKILLS_MACHINE env -> ~/.hermes-skills-machine -> sanitised hostname.
resolve_machine_name() {
  if [ -n "${SKILLS_MACHINE:-}" ]; then printf '%s' "$SKILLS_MACHINE"; return; fi
  if [ -f "$HOME/.hermes-skills-machine" ]; then
    head -1 "$HOME/.hermes-skills-machine" | tr -d '\r\n'; return
  fi
  hostname 2>/dev/null | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

# Lowercase alnum + dash, <=40 chars, and not a reserved ref name.
valid_machine_name() {
  case "$1" in main|master|head|origin|refs) return 1 ;; esac
  printf '%s' "$1" | grep -Eq '^[a-z0-9][a-z0-9-]{0,39}$'
}
