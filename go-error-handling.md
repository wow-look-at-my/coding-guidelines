# Go Error Handling

## Wrap with context

Always wrap errors with `fmt.Errorf` and `%w` so callers can inspect the chain with
`errors.Is` / `errors.As`:

```go
return fmt.Errorf("failed to create tag %s: %w", tag, err)
return fmt.Errorf("build failed: %w", err)
return fmt.Errorf("create install directory: %w", err)
```

For errors that have both a root cause and a secondary failure (e.g. rollback), use
`%w` for the primary and `%v` for the secondary:

```go
return fmt.Errorf("install failed (%w) and rollback also failed (%v)", err, rerr)
```

## Sentinel errors

Define sentinel errors in a dedicated `errors.go` file using `errors.New`:

```go
var (
    ErrInvalidSlug                 = errors.New("invalid slug format, expected 'owner/name'")
    ErrAssetNotFound               = errors.New("asset not found")
    ErrCannotDecompressFile        = errors.New("failed to decompress")
    ErrExecutableNotFoundInArchive = errors.New("executable not found")
)
```

Compose sentinels into wrapped errors for specific context:

```go
return nil, fmt.Errorf("%w zip file: %v", ErrCannotDecompressFile, err)
return nil, fmt.Errorf("%w in tar: %q", ErrExecutableNotFoundInArchive, cmd)
```

## Early returns

Return early on error instead of nesting. Each error check is a guard clause:

```go
func (r RepositorySlug) GetSlug() (string, string, error) {
    if r.owner == "" && r.repo == "" {
        return "", "", ErrInvalidSlug
    }
    if r.owner == "" {
        return r.owner, r.repo, ErrIncorrectParameterOwner
    }
    if r.repo == "" {
        return r.owner, r.repo, ErrIncorrectParameterRepo
    }
    return r.owner, r.repo, nil
}
```

## Intentional discards

When an error is intentionally ignored, use `_ =` to make it explicit. This only
applies to non-critical cleanup:

```go
_ = os.Remove(oldPath)   // stale file from prior failed update
_ = os.Remove(newPath)   // cleanup on rename failure
```

Never silently discard errors on paths that matter.

## Non-fatal warnings

For non-fatal errors in CLI tools, print to stderr with a consistent
`"subsystem: message"` prefix and return without propagating:

```go
fmt.Fprintf(os.Stderr, "proxy: GO_PROXY_CONFIG decode error: %v\n", err)
fmt.Fprintf(os.Stderr, "cacheprog: base64 decode error: %v\n", err)
```

## Comparison

Always use `errors.Is(err, target)` for sentinel comparison, never `==`:

```go
if errors.Is(err, io.EOF) {
    break
}
if errors.Is(statErr, fs.ErrNotExist) {
    // file doesn't exist yet, that's fine
}
```
