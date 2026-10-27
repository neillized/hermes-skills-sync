#!/usr/bin/env bash
# One-time setup on a new machine: identity, branch, scripts, sanity checks.
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"
cd "$SKILLS_DIR" || exit 1

NAME="$(resolve_machine_name)"
valid_machine_name "$NAME" || die "invalid machine name '$NAME' (set SKILLS_MACHINE or ~/.hermes-skills-machine)"
echo "machine name : $NAME"
echo "branch       : machine/$NAME"

# 1. identity
[ -n "$(git config --global user.name || true)" ]  || git config --global user.name "skills-sync"
[ -n "$(git config --global user.email || true)" ] || git config --global user.email "skills-sync@localhost"
command -v gh >/dev/null 2>&1 && gh auth setup-git >/dev/null 2>&1 || true

# 2. refuse a name that another machine already owns
if [ -n "$(git ls-remote --heads origin "refs/heads/machine/$NAME" 2>/dev/null)" ] \
   && ! git rev-parse --verify "refs/heads/machine/$NAME" >/dev/null 2>&1; then
  cat >&2 <<EOF
!! machine/$NAME already exists on the remote and not locally.
   Another machine probably has the same hostname. Pick a distinct name:
     echo my-workstation > ~/.hermes-skills-machine
   or export SKILLS_MACHINE=my-workstation before running this again.
EOF
  exit 1
fi

# 3. create / update this machine's branch
git checkout -B "machine/$NAME" >/dev/null 2>&1

# register this machine in the merge order (append-only, idempotent)
ORDER=".github/machine-order"
if [ -f "$ORDER" ] && ! tr -d '\r' < "$ORDER" | grep -qx "$NAME"; then
  printf '%s\n' "$NAME" >> "$ORDER"
  git add "$ORDER"
  git commit -q -m "skills: register $NAME in merge order" || true
  echo "order        : registered (appended to $ORDER)"
fi

git push -u origin "HEAD:refs/heads/machine/$NAME" >/dev/null 2>&1 && echo "pushed branch"
git fetch origin main >/dev/null 2>&1 && git rebase --autostash origin/main >/dev/null 2>&1 && echo "rebased onto main"

# 4. install the pre-push hook that blocks writes to main
mkdir -p "$SKILLS_DIR/.git/hooks"
cp "$SCRIPT_DIR/hooks/pre-push" "$SKILLS_DIR/.git/hooks/pre-push"
chmod +x "$SKILLS_DIR/.git/hooks/pre-push"
echo "hook         : blocks direct pushes to main"

# 5. install the script copies
mkdir -p "$HERMES_DIR/scripts"
cp "$SCRIPT_DIR/lib.sh" "$SCRIPT_DIR/skills-pull.sh" "$SCRIPT_DIR/skills-push.sh" "$SCRIPT_DIR/skills-sync.sh" "$HERMES_DIR/scripts/"
chmod +x "$HERMES_DIR/scripts/"*.sh 2>/dev/null || true
echo "scripts      : $HERMES_DIR/scripts"

# 6. untrack factory-identical skills (local only, via .git/info/exclude)
FAC="${HERMES_DIR%/hermes}/hermes/hermes-agent/skills"
[ -d "$FAC" ] || FAC="$HERMES_DIR/hermes-agent/skills"
if [ -d "$FAC" ]; then
  # python3 is a Microsoft Store stub on some Windows boxes; fall back to `python`.
  PYRUN=python3
  python3 -c 'pass' >/dev/null 2>&1 || PYRUN=python
  if "$PYRUN" -c 'pass' >/dev/null 2>&1; then
  "$PYRUN" - "$SKILLS_DIR" "$FAC" <<'PY'
import os, sys, hashlib, subprocess
sk, fac = sys.argv[1], sys.argv[2]
def h(d):
    m = hashlib.md5()
    for dp, dn, fn in os.walk(d):
        dn[:] = [x for x in dn if x not in ("__pycache__",".venv","node_modules","data","logs")]
        for f in sorted(fn):
            if f.endswith((".pyc",".log",".jsonl")): continue
            p = os.path.join(dp, f)
            m.update(os.path.relpath(p, d).replace("\\","/").encode())
            m.update(open(p,"rb").read().replace(b"\r\n",b"\n"))
    return m.hexdigest()
excl = os.path.join(sk, ".git", "info", "exclude")
have = open(excl).read() if os.path.exists(excl) else ""
tracked = set(subprocess.run(["git","-C",sk,"ls-files"],capture_output=True,text=True).stdout.splitlines())
added = []
for dp, dn, fn in os.walk(sk):
    dn[:] = [x for x in dn if x not in (".git","__pycache__",".venv","node_modules","index-cache")]
    if "SKILL.md" not in fn: continue
    rel = os.path.relpath(dp, sk).replace("\\","/")
    twin = os.path.join(fac, rel)
    if os.path.isfile(os.path.join(twin,"SKILL.md")) and h(dp) == h(twin):
        if not any(t.startswith(rel+"/") for t in tracked): continue
        subprocess.run(["git","-C",sk,"rm","-r","--cached","--quiet",rel],capture_output=True)
        line = "/"+rel+"/"
        if line not in have:
            with open(excl,"a") as f: f.write(line+"\n")
            have += line+"\n"
        added.append(rel)
print("untracked factory copies:", len(added))
PY
  else
    echo "factory-untrack: SKIPPED (no usable python3/python on PATH)"
  fi
fi

echo
echo "next: add the daily cron job (every machine can use 09:00 now — each machine"
echo "      writes only its own branch, and the workflow merges main in join order)"
echo "      running: skills-sync.sh   (push this machine's edits, then rebase onto main)"
