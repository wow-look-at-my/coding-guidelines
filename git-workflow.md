# Git Workflow

## Default branch

The default branch is `master` across the org.

## Commit frequency

Commit and push frequently. Do not accumulate a large batch of changes before
committing. Work can be lost if the environment resets before pushing.

## Commit messages

Concise, imperative mood. Focus on the "why" rather than the "what". One to two
sentences.

```
Add manifest encryption support for multi-recipient keys

Fix version detection falling back to 0.0.0 for pseudo-versions
```

## Squash merge

Pull requests are squash-merged. This means:

- You can keep adding commits to your PR branch instead of rebasing
- The commit history is cleaned up automatically on merge
- Do not force push or rebase to clean up history -- it's unnecessary and often blocked

When working on a PR:

1. Make changes and commit normally
2. If corrections are needed, add new commits
3. Use `git merge` (not rebase) if you need to update from the base branch
4. The entire PR becomes a single commit on merge

## Branch protection

Many repos have branch protection rules that prevent force pushing. This is not a
problem because of squash merge (see above).

## Documentation updates

When making changes, check whether `CLAUDE.md` and `README.md` need updating. If they
do, update them in the same commit or PR. Outdated docs are worse than no docs.
