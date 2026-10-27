---
name: skills-git-sync
description: Use when syncing Hermes skills across several machines. Branch-per-machine git sync with server-side merge.
version: 1.1.1
---

# Syncing skills across machines

One private repo holds the skills library. Each machine writes **its own branch**;
`main` is merged server-side. Two machines syncing at the same time cannot collide,
because they never write the same ref.

## When to use

- A user runs Hermes on more than one computer and wants one skills library
- Skills edited on one machine must reach the others
- Someone asks why "push to main from both machines" gets rejected

## Model

```
main                      <- written only by the merge workflow
  ^ merges machine/* in join order
machine/<name>            <- one per machine
```

A push is a compare-and-swap on a ref: if the remote moved since your last fetch it is
rejected, which is correct - accepting it would drop the other machine's commits. Large
projects avoid that race by having each contributor write a private branch and letting one
serialised place do the merge. Here that place is a GitHub Actions job with a
`concurrency` group.

## Set up a machine

```bash
cd <skills dir>                     # the clone
bash skills/skills-git-sync/scripts/bootstrap.sh
```

Then schedule `scripts/skills-sync.sh` daily. All machines may use the same hour.

## Rules

- Never push to `main`; the pre-push hook blocks it. Write `machine/<name>`.
- Never `push --force`.
- Factory/bundled skills must stay untracked: `bootstrap.sh` compares each skill with the
  installed Hermes copy byte for byte and moves identical ones to `.git/info/exclude`
  (per-clone, so it cannot pollute other machines). Do not put them in `.gitignore`.
- Keep generated data, caches and secrets out of the repo.

See `references/architecture.md` for the failure modes and `docs/conflicts.md` upstream.
