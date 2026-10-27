# When a merge conflicts

The workflow fails and names the branch:

```
::error::conflict merging machine/laptop-yyyy - resolve it on that machine
```

Nothing is lost. On that machine:

```bash
cd <skills dir>
git fetch origin main
git rebase origin/main
# resolve each file, then:
git add <files>
git rebase --continue
git push origin HEAD:refs/heads/machine/<name>
```

The workflow reruns on the push and merges again.

## If the local sync script reported a conflict

`skills-sync.sh` aborts the rebase automatically and prints
`SKILLS_SYNC_CONFLICT_NEEDS_HERMES` plus the conflicted paths. Resolve by hand as above;
the script never leaves a half-finished rebase behind and never force-pushes.

## Avoiding them

- Edit different skills on different machines when you can.
- Do not rewrite history on a `machine/*` branch that other work was based on.
