# Go Testing

## Test library

Use `github.com/wow-look-at-my/testify` (assert + require). Never bare
`t.Error` / `t.Fatal`.

`require` for preconditions that must hold before further assertions can run.
`assert` for independent checks that should all be evaluated.

```go
rel, found, err := up.DetectLatest(ctx, slug)
require.Nil(t, err)
require.True(t, found)
assert.Equal(t, "2.0.0", rel.Version.Version)
```

Prefer `require.Nil(t, err)` / `assert.Nil(t, err)` over `require.NoError` /
`assert.NoError`. This is the dominant pattern across the org.

## Test package

Tests live in the same package (white-box testing), not a `_test` package. This gives
full access to unexported identifiers.

```go
// detect_test.go
package selfupdate

func TestParseVersion(t *testing.T) { ... }
```

## Table-driven tests

Use for pure functions with many input/output variations. The struct literal defines
inputs and expected outputs; `t.Run` uses a descriptive name for each case.

```go
func TestParseVersion(t *testing.T) {
    tests := []struct {
        tag     string
        wantOK  bool
        version string
        major   int
    }{
        {"v1.2.3", true, "1.2.3", 1},
        {"not-a-version", false, "", 0},
    }
    for _, tt := range tests {
        t.Run(tt.tag, func(t *testing.T) {
            v, ok := parseVersion(tt.tag)
            require.Equal(t, tt.wantOK, ok)
            if !ok {
                return
            }
            assert.Equal(t, tt.version, v.Version)
        })
    }
}
```

## Separate functions for distinct scenarios

When tests need different setup or exercise fundamentally different behavior, use
separate top-level test functions instead of subtests:

```go
func TestDetectSkipsDrafts(t *testing.T) { ... }
func TestDetectIncludesDraftsWhenEnabled(t *testing.T) { ... }
func TestDetectSkipsPrereleases(t *testing.T) { ... }
```

## Test naming

`Test<Subject><Scenario>` or `Test<Subject>_<Scenario>`:

```go
TestParseProxyConfig_Valid
TestParseProxyConfig_UsernameField
TestWriteNetrc_CreatesFile
TestDetectLatestNoReleases
TestDetectLatestSourceError
```

## Test helpers

All helpers call `t.Helper()` so failures report the caller's line:

```go
func fakeNpmServer(t *testing.T, name, version string) *httptest.Server {
    t.Helper()
    srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // ...
    }))
    t.Cleanup(srv.Close)
    return srv
}
```

Constructor-style helpers for test data use the `newTest` prefix:

```go
func newTestRelease(tag string, assets ...SourceAsset) *mockRelease { ... }
func newTestAsset(name string) *mockAsset { ... }
```

## Test isolation

Use stdlib facilities for isolation -- no manual cleanup code:

```go
t.Setenv("HOME", t.TempDir())
t.Setenv("GO_PROXY_CONFIG", encoded)
```

For cleanup that can't use `t.Setenv` / `t.TempDir`, use `t.Cleanup`:

```go
prev := EmbeddedVersion
EmbeddedVersion = "1.2.3"
t.Cleanup(func() { EmbeddedVersion = prev })
```

## Resetting memoized state

For singletons that use `sync.Once`, provide an unexported reset helper for tests:

```go
func resetDetectedVersion() {
    detectVersionOnce = sync.Once{}
    detectedVersion = ""
}
```

## HTTP mocking

Use `net/http/httptest` -- no external mock libraries:

```go
srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    switch r.URL.Path {
    case "/repos/owner/repo/releases":
        json.NewEncoder(w).Encode(releases)
    default:
        http.NotFound(w, r)
    }
}))
t.Cleanup(srv.Close)
```

## Interface mocks

Define mock types in the test file that uses them. Use the `mock` prefix:

```go
type mockSource struct {
    releases []SourceRelease
    err      error
    assets   map[int64]string
}

func (s *mockSource) ListReleases(_ context.Context, _ Repository) ([]SourceRelease, error) {
    return s.releases, s.err
}
```

## Skip guards

Skip slow or environment-dependent tests under `-short`:

```go
if testing.Short() {
    t.Skip("builds a real binary; skipped under -short")
}
```

## Cobra command testing

Cobra binds flags to package-level vars. Tests that exercise commands must restore
flag state in `t.Cleanup`:

```go
func resetFlags(t *testing.T) {
    t.Helper()
    old := installVersion
    t.Cleanup(func() { installVersion = old })
}
```

Capture command output via `execute(args...)` helpers that run the cobra command
and return stdout + stderr as strings.
