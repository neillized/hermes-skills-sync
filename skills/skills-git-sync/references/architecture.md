# Architecture notes

## The failure this avoids

Two machines on the same branch:

```
A: fetch -> main = X -> commit B -> push "X -> B"   ok
B: fetch -> main = X -> commit C -> push "X -> C"   rejected
```

Git compares the expected old value with the actual one. The second push is refused
because `main` is no longer `X`. Accepting it would erase B's commit - so the rejection
is the safety feature, not a bug.

## The fix

Serialise the writer. Machines push `machine/<name>` (a ref only they write, so never
rejected), and one CI job merges them into `main` in a fixed order. `concurrency:` in the
workflow makes GitHub run one merge job at a time; later pushes queue.

## Trade-offs

| | |
|---|---|
| Cost | one extra branch per machine, one CI job |
| Benefit | no push races, linear `main`, conflict isolated to its origin machine |
| Requires | a CI service; GitHub Actions is used here |
| Not needed for | a single machine - there a plain push is simpler |

## What "conflict" means here

Only when two machines edited the same file. The workflow fails with the branch name;
that machine rebases onto `main`, resolves, and pushes again. Other machines are never
blocked, because they write separate refs.

## Factory skills

Bundled skills change with each Hermes release. Tracking them turns every upgrade into
phantom diffs, so `bootstrap.sh` finds byte-identical copies and untracks them. The check
is content-based, not name-based, and per machine.
