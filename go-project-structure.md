# Go Project Structure

## Binaries (CLI tools, servers)

Top-level `main.go` does nothing but call into a `cmd` package:

```go
// main.go
package main

import "github.com/wow-look-at-my/myapp/cmd"

func main() {
    cmd.Execute()
}
```

Organize by responsibility:

```
main.go
cmd/
    root.go         # rootCmd definition + Execute()
    install.go      # one file per subcommand
    upgrade.go
    version.go
store/              # data persistence
manifest/           # domain logic
.github/
    workflows/
        ci.yml
go.mod
go.sum
```

Each subcommand file registers itself via `init()`. The main file never manually
registers commands.

## Libraries

Flat single-package layout at the repo root. One concept per file.

```
updater.go
detect.go
update.go
install.go
decompress.go
source.go
github_source.go
errors.go
config.go
log.go
```

No subdirectories unless the library genuinely has independent subsystems. Splitting a
flat package into sub-packages "for organization" adds import friction with no benefit.

## Multi-package repos

When a binary has internal subsystems complex enough to warrant separate packages, use
purpose-named directories:

```
src/
    main.go
    goenv.go
    cmd/
        release.go
        matrix.go
    build/
        build.go
        docker.go
    codeql/
        codeql.go
```

Each sub-package owns one concern. Cross-package dependencies flow downward
(cmd -> build, cmd -> codeql), never sideways between peer packages.

## File size

Soft limit: 500 lines per `.go` file. Hard limit: 750 lines. If a file exceeds this,
split by concern.

## What goes where

| Content | Location |
|---------|----------|
| Sentinel errors | `errors.go` |
| Config struct + related types | `config.go` |
| Interface definitions | Same file as the consumer, or a dedicated `source.go` / `types.go` |
| Interface implementations | Separate file per implementation (`github_source.go`, `npm_source.go`) |
| Test mocks | In the `_test.go` file that uses them |
| Compile-time interface checks | End of the implementation file |
| Package-level doc comment | On the `package` declaration in the primary file |
