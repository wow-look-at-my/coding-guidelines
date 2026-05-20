# Go Style

## Naming

### Types

PascalCase for exported, camelCase for unexported. No stutter relative to the package name.

```go
type Updater struct { ... }          // exported
type VersionFilter struct { ... }    // exported
type commandConfig struct { ... }    // unexported
type proxyConfig struct { ... }      // unexported
```

### Functions

Verb or verb-noun. Predicates use `is`/`has`/`can` prefix and return `bool`.

```go
func detectLatest(slug string) (*Release, error)
func installRelease(rel *Release, dest string) error
func normalizeSlug(slug string) string

func isGHA() bool
func hasFilters() bool
func canUseTokenForDomain(token, domain string) (bool, error)
```

### Variables

camelCase for package-level unexported, PascalCase for exported. Short names for
short-lived locals (`r`, `w`, `f`, `d`, `cfg`), descriptive for longer-lived ones.

```go
var defaultUpdater *Updater           // unexported singleton
var EmbeddedVersion string            // exported, settable via ldflags
var ghTokenPrefixes = []string{...}   // unexported, plural noun for slices
```

### Constants

Grouped in `const (...)` blocks. camelCase for unexported, PascalCase for exported.
Clear prefix when constants form a set.

```go
const (
    fileLengthWarn  = 500
    fileLengthError = 750
)
```

### Files

Lowercase. Underscores only for platform-specific build tags (`_linux.go`, `_darwin.go`,
`_windows.go`). Multi-word concept files use underscores (`github_source.go`,
`repository_slug.go`). Test files mirror their source (`detect.go` / `detect_test.go`).

## Imports

Three groups separated by blank lines: stdlib, external, internal. Alphabetical within
each group. Import aliases only to disambiguate collisions.

```go
import (
    "context"
    "fmt"
    "os"

    "github.com/spf13/cobra"
    selfupdate "github.com/wow-look-at-my/go-selfupdate-mini"

    "github.com/wow-look-at-my/wow-cli/store"
)
```

## Comments

Doc comments on all exported identifiers. Start with the identifier name.

```go
// Updater is responsible for managing the context of self-update.
type Updater struct { ... }

// NewUpdater creates a new updater instance.
// If you don't specify a source in the config object, GitHub will be used.
func NewUpdater(config Config) (*Updater, error) { ... }
```

Unexported identifiers get a doc comment when the purpose is not obvious from the name.
Trivial helpers can go without.

```go
// proxyConfig is the JSON structure inside GO_PROXY_CONFIG (base64-encoded).
type proxyConfig struct { ... }
```

Inline comments explain the "why", never the "what":

```go
// Use GONOSUMDB instead of GOSUMDB=off so toolchain auto-downloads still work.
os.Setenv("GONOSUMDB", "*")

// Check extensions longest-first to match .tar.gz before .gz
for _, ext := range sortedExtensions(decompressors) {
```

Use double-dash (`--`) for em-dashes in comments, never Unicode characters.
No non-ASCII in source files.

Use Go doc links (`[Symbol]`) to cross-reference within package documentation:

```go
// When this option is omitted, the version is auto-detected via [CurrentVersion].
```

## Formatting

No named return values. All returns are explicit.

`defer f.Close()` immediately after opening a file or response body, before any reads:

```go
f, err := os.Open(path)
if err != nil {
    return err
}
defer f.Close()
```

Use `errors.Is(err, target)` for sentinel comparison, never `err == target`.

Atomic file writes for anything that might be read concurrently -- write to a temp
file then rename:

```go
tmp, err := os.CreateTemp(dir, ".config-tmp-*")
// ... write, chmod, close ...
os.Rename(tmp.Name(), targetPath)
```

`sync.Once` for lazy memoization of expensive operations:

```go
var (
    detectOnce sync.Once
    detected   string
)

func CurrentVersion() string {
    detectOnce.Do(detect)
    return detected
}
```
