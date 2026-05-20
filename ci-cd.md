# CI/CD

## Go projects

All Go projects use `go-toolchain` for building, testing, and releasing. Never run
bare `go build`, `go test`, or `go mod tidy` -- use `go-toolchain` instead.

### Standard CI workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:

permissions:
  id-token: write
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: wow-look-at-my/go-toolchain@v1
```

The `permissions` block with `id-token: write` is required. Without it, the
go-toolchain action fails.

### What go-toolchain does

`go-toolchain` handles the complete build pipeline:

1. Downloads the correct Go version automatically (do not modify `go.mod`'s Go
   version to work around mismatches)
2. Runs `go mod tidy`
3. Runs `go vet`
4. Runs tests with coverage profiling
5. Enforces minimum 80% coverage
6. Produces binaries only if coverage targets are met
7. Handles cross-compilation, benchmarking, and autorelease

### Installing go-toolchain locally

Binaries for all platforms are at
`https://github.com/wow-look-at-my/go-toolchain/releases/latest`:

- Linux amd64: `go-toolchain_linux_amd64`
- Linux arm64: `go-toolchain_linux_arm64`
- macOS amd64: `go-toolchain_darwin_amd64`
- macOS arm64: `go-toolchain_darwin_arm64`
- Windows amd64: `go-toolchain_windows_amd64.exe`
- Windows arm64: `go-toolchain_windows_arm64.exe`

## Workflow triggers

### CI/test workflows

Use `on: push:` only. No `pull_request:` triggers, branch filters, or path filters.

```yaml
on:
  push:
```

### Deploy/release workflows

Workflows that deploy (GitHub Pages, cloud) or publish releases (GoReleaser, npm)
**must** keep their branch filters and special triggers intact:

```yaml
# GitHub Pages deploy -- keep the branch filter
on:
  push:
    branches: [master]
```

**Rule of thumb:** if a workflow's jobs include `deploy`, `publish`, `release`,
`pages`, or push to a production environment, preserve its trigger configuration
exactly as-is.

## GitHub Actions rules

### Allowed actions

Only use actions from:

- `actions/*` (GitHub-owned)
- `wow-look-at-my/*`
- `PazerOP/*`

Third-party community actions are **not allowed**. The org allowlist blocks them.
Use the runner's built-in `gh` CLI instead of reaching for community actions.

### Reusable actions

Before writing a new workflow step from scratch, check `wow-look-at-my/actions` for
something reusable.

## PR preview (GitHub Pages repos)

All repositories that use GitHub Pages must include a PR preview workflow using
`PazerOP/pr-preview-action`:

```yaml
# .github/workflows/preview.yml
name: Deploy PR previews

on:
  pull_request:
    types: [opened, reopened, synchronize, closed]

jobs:
  deploy-preview:
    uses: PazerOP/pr-preview-action/.github/workflows/preview.yml@v1
    with:
      source-dir: ./build/
    secrets: inherit
```

For repos with a build step, use `artifact-name` instead of `source-dir`.

Set the repo's **Settings > Pages** source to **GitHub Actions** (not "Deploy from a
branch").

## Waiting for CI

Use `gh wait-ci` after pushing when you need to check CI results. Never use
`sleep` + `gh run list` polling loops.

```bash
gh wait-ci                        # current branch, latest commit
gh wait-ci --sha <commit-sha>    # specific commit
gh wait-ci --interval 10         # poll every 10 seconds
```

## CI must pass

No PRs can be merged in the `wow-look-at-my` org without passing CI. Always ensure CI
is configured and passing before marking a PR as ready.
