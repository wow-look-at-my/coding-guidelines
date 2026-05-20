# Go Interfaces and Constructors

## Interface design

Interfaces are small (1-3 methods) and focused on a single behavior:

```go
type Source interface {
    ListReleases(ctx context.Context, repository Repository) ([]SourceRelease, error)
    DownloadReleaseAsset(ctx context.Context, rel *Release, assetID int64) (io.ReadCloser, error)
}

type Decompressor interface {
    Decompress(src io.Reader, cmd string) (io.Reader, error)
}

type Logger interface {
    Print(v ...interface{})
    Printf(format string, v ...interface{})
}
```

Avoid broad interfaces with many methods. If an interface has more than 3-4 methods,
it probably needs to be split.

## Where to define interfaces

Define interfaces where they are consumed, not alongside the implementation:

- `Source` interface in `source.go` (consumer side)
- `GitHubSource` implementation in `github_source.go`
- `NpmSource` implementation in `npm_source.go`

For test-only interfaces, define them in the test file:

```go
// cmd/release.go
type releaseExecutor interface {
    gitOutput(args ...string) (string, error)
    gitRun(args ...string) error
}
```

## Compile-time interface checks

Place `var _ Interface = &Implementation{}` at the end of the implementation file:

```go
var _ Source = &GitHubSource{}
var _ SourceRelease = &githubRelease{}
var _ SourceAsset = &githubAsset{}
var _ Repository = RepositorySlug{}
```

## Func adapter types

For single-method interfaces, provide a `Func` adapter so callers can pass plain
functions:

```go
type DecompressorFunc func(src io.Reader, cmd string) (io.Reader, error)

func (f DecompressorFunc) Decompress(src io.Reader, cmd string) (io.Reader, error) {
    return f(src, cmd)
}
```

## Dependency injection

Inject dependencies through the `Config` struct passed to the constructor:

```go
type Config struct {
    Source          Source
    Platform        Platform
    Validate        func(*Release, []byte) error
    CompareVersions func(current, candidate Version) bool
    Install         func(io.Reader, string) error
    Decompressors   map[string]Decompressor
}
```

For simpler cases where full DI would be overkill, use package-level function
variables:

```go
var inDockerCheck = defaultInDockerCheck
var environFunc = os.Environ
```

With a setter that returns a restore function for tests:

```go
func SetInDockerCheck(f func() bool) func() {
    old := inDockerCheck
    inDockerCheck = f
    return func() { inDockerCheck = old }
}
```

## Constructors

### Config struct pattern

Use a `Config` struct for constructors with multiple parameters. Zero values are valid
defaults. Never use long argument lists.

```go
type Config struct {
    // Source where to load releases from. Defaults to GitHubSource.
    Source Source

    // Platform targeting. Defaults to runtime.GOOS/GOARCH.
    Platform Platform

    // CompareVersions returns true if candidate is newer than current.
    // If nil, semantic versioning comparison is used.
    CompareVersions func(current, candidate Version) bool
}

func NewUpdater(config Config) (*Updater, error) {
    if config.Source == nil {
        config.Source = defaultSource()
    }
    // ...
}
```

### Simple value constructors

For value types that can't fail, return the value directly (no pointer, no error):

```go
func NewRepositorySlug(owner, repo string) RepositorySlug { ... }
func ParseSlug(slug string) RepositorySlug { ... }
```

### Functional options

For optional configuration on top of required arguments, use functional options:

```go
type CommandOption func(*commandConfig)

func WithConfig(cfg Config) CommandOption {
    return func(c *commandConfig) { c.config = &cfg }
}

func WithVersion(v string) CommandOption {
    return func(c *commandConfig) { c.currentVersion = v }
}

func RegisterCommands(rootCmd *cobra.Command, repo Repository, opts ...CommandOption) {
    cfg := applyOptions(opts)
    // ...
}
```

### Singletons

Lazy-initialize singletons with a package-level variable:

```go
var defaultUpdater *Updater

func DefaultUpdater() *Updater {
    if defaultUpdater != nil {
        return defaultUpdater
    }
    defaultUpdater, _ = NewUpdater(Config{})
    return defaultUpdater
}
```

For thread-safe lazy init, use `sync.Once`:

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
