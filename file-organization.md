# File Organization

## One language per file

Always put content in the correct file type. Do not embed one language inside another
when it can be a separate file.

- JavaScript -> `.js` files
- TypeScript -> `.ts` files
- CSS -> `.css` files
- GLSL shaders -> `.glsl` files
- WGSL shaders -> `.wgsl` files
- HTML -> `.html` files

Do not embed shaders as strings in JavaScript or TypeScript files. Load them from
`.glsl` / `.wgsl` files instead, using the appropriate loader (e.g.
`--loader:.wgsl=text` in esbuild).

## One concern per file

Split files by logical concern. A file should do one thing.

In Go:

| Concern | File |
|---------|------|
| Sentinel errors | `errors.go` |
| Configuration types | `config.go` |
| Interface definitions | `source.go`, `types.go` |
| Each interface implementation | `github_source.go`, `npm_source.go` |
| Logging infrastructure | `log.go` |
| Version detection | `version.go` |
| Each CLI subcommand | `install.go`, `upgrade.go`, `search.go` |

## File size limits

Go files: 500-line soft limit, 750-line hard limit. If a file exceeds this, split it
by concern -- not arbitrarily.

## Built output is never committed

`dist/`, `build/`, compiled `.js` from `.ts` sources -- none of this goes in git.
Use `.gitignore`:

```gitignore
dist/
build/
*.js
!build.ts
```

## Binary artifacts

Go binaries go in `build/` or `~/.local/bin/`. The `.gitignore` for Go repos:

```gitignore
/build/
```

## No non-ASCII in source files

Em-dashes, ellipses, smart quotes are UTF-8 multi-byte. Use plain ASCII equivalents:

- `--` not `--` (em-dash)
- `...` not `...` (ellipsis)
- `"` not `"` or `"` (smart quotes)

Check with: `LC_ALL=C grep -P '[^[:print:][:space:]]' file`
