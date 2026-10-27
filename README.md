# hermes-skills-sync

Sync one Hermes skills library across several computers, without merge pain.

One private repo, **one branch per machine**, `main` merged server-side by a GitHub
Actions workflow. Every machine writes only its own branch, so two machines syncing at
the same moment can never collide. `main` stays linear and is the single source of truth.

```
main                      <- written only by the merge workflow
  ^ merges machine/* in join order
machine/desktop-xxxx      <- one branch per machine, pushed on a schedule
machine/laptop-yyyy
```

## Why branches instead of pushing straight to main

Git refuses the second of two pushes to the same branch: a push is a
compare-and-swap on that ref, and a stale base is rejected rather than silently
discarding the other machine's commits. That safety is correct, but it makes
"everyone push main" a race. The fix is the one large projects use - contributors
write their own branch, and the merge happens in one serialised place. Here that
place is a GitHub Actions job with a `concurrency` group.

## Install

```bash
hermes skills tap add <owner>/hermes-skills-sync
hermes skills install skills-git-sync
```

Or copy `skills/skills-git-sync/` into your skills directory by hand.

## Join a machine

```bash
cd <your skills dir>            # the git clone
bash skills/skills-git-sync/scripts/bootstrap.sh
```

`bootstrap.sh` picks a machine name (env `SKILLS_MACHINE`, else
`~/.hermes-skills-machine`, else the sanitised hostname), creates and pushes
`machine/<name>`, installs the pre-push hook that blocks writes to `main`, and
untracks any skill that is byte-identical to the Hermes factory copy so bundled
skills never enter the repo.

Then schedule `skills-sync.sh` once a day. Every machine may use the same time:
they push different refs.

## Daily behaviour

`skills-sync.sh` commits local edits, pushes `machine/<name>`, then rebases onto
`origin/main`. Silent on success, non-zero with a stable marker on failure.

| marker | meaning |
|---|---|
| `SKILLS_SYNC_FETCH_FAILED` | network / credentials |
| `SKILLS_SYNC_CONFLICT_NEEDS_HERMES` | rebase conflict; files listed on stderr |
| `COMMIT_FAILED` / `PUSH_FAILED` | local git problem |

## Requirements

- `git`, `bash`, and a GitHub repo you can push to
- `gh` CLI for credentials (or any credential helper)
- Python 3 only for the optional factory-untracking step

The branch model works with any git host. Only `.github/workflows/merge-machines.yml`
is GitHub-specific; on GitLab or Gitea, reproduce it as a single serialised CI job
that merges each `machine/*` branch into `main`.

## Layout

```
skills/skills-git-sync/   the skill: SKILL.md, scripts, references
.github/workflows/        the merge workflow
.github/machine-order     merge order (append on join)
docs/                     design notes and conflict handling
```

MIT licensed.
