# Why one branch per machine

See `skills/skills-git-sync/references/architecture.md` for the full explanation.

Short version: a git push is a compare-and-swap on a ref. Two machines pushing `main`
means the second one's base is stale, so it is rejected - correctly, because accepting it
would drop the first machine's commits. Large projects avoid the race by giving every
contributor a private branch and doing the merge in one serialised place. This project
applies the same shape at the scale of one person's computers: a `machine/<name>` branch
each, and a single CI job that merges them into a protected `main`.
