# Go CLI Design

## Framework

Use [cobra](https://github.com/spf13/cobra) for all CLI tools. Consistency across the
org matters more than saving a dependency.

## Entry point

`main.go` is a one-liner that calls `cmd.Execute()`:

```go
package main

import "github.com/wow-look-at-my/myapp/cmd"

func main() {
    cmd.Execute()
}
```

## Root command

Define in `cmd/root.go`. Export only `Execute()`.

```go
package cmd

import (
    "os"

    "github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
    Use:   "myapp",
    Short: "One-line description",
    Long:  `Longer description with context about what the tool does.`,
}

func Execute() {
    if err := rootCmd.Execute(); err != nil {
        os.Exit(1)
    }
}
```

## One command per file

Each subcommand lives in its own file and registers itself via `init()`. The root
command never manually registers subcommands -- each file is responsible for its own
registration.

```go
// cmd/install.go
package cmd

import "github.com/spf13/cobra"

var installCmd = &cobra.Command{
    Use:   "install <name>",
    Short: "Download and install a binary",
    Args:  cobra.ExactArgs(1),
    RunE:  runInstall,
}

func init() {
    installCmd.Flags().StringVar(&installName, "name", "", "binary name")
    installCmd.Flags().StringVar(&installPath, "path", "", "install path")
    rootCmd.AddCommand(installCmd)
}

func runInstall(cmd *cobra.Command, args []string) error {
    // ...
}
```

## Nested subcommands

For command groups (e.g. `myapp repo add`, `myapp repo list`), create a parent
command file and child files:

```go
// cmd/repo_cmd.go -- parent group
var repoCmd = &cobra.Command{
    Use:   "repo",
    Short: "Manage manifest repositories",
}

func init() {
    rootCmd.AddCommand(repoCmd)
}

// cmd/repo_add.go -- child command
var repoAddCmd = &cobra.Command{
    Use:  "add <url>",
    RunE: runRepoAdd,
}

func init() {
    repoCmd.AddCommand(repoAddCmd)
}
```

## Flags

Long flags use double-hyphen (`--verbose`, `--output`). Short aliases use
single-hyphen (`-v`, `-o`). Cobra and pflag enforce this automatically. Never use
the `flag` stdlib package -- it only supports single-hyphen for all flags.

Bind flags to package-level variables in `init()`, not struct fields:

```go
var (
    releaseTag    string
    releaseBuild  bool
    releaseCosign bool
)

func init() {
    cmd.Flags().StringVar(&releaseTag, "tag", "", "tag name for the release")
    cmd.Flags().BoolVar(&releaseBuild, "build", false, "run matrix build first")
    cmd.Flags().BoolVar(&releaseCosign, "cosign", false, "sign release artifacts")
    rootCmd.AddCommand(cmd)
}
```

## RunE, not Run

Always use `RunE` (returns `error`) instead of `Run`. Let cobra handle error printing.
Set `SilenceUsage: true` to prevent the usage message from printing on every error.

```go
var myCmd = &cobra.Command{
    Use:          "my-command",
    Short:        "Does a thing",
    SilenceUsage: true,
    RunE:         runMyCommand,
}
```

## Output

Use `cmd.OutOrStdout()` and `cmd.ErrOrStderr()` instead of `os.Stdout` / `os.Stderr`.
This makes commands testable with captured output.

```go
func runInstall(cmd *cobra.Command, args []string) error {
    fmt.Fprintf(cmd.OutOrStdout(), "Installing %s %s...\n", name, version)
    // ...
    fmt.Fprintf(cmd.OutOrStdout(), "Installed %s -> %s\n", name, dest)
    return nil
}
```

## Context

Use `cmd.Context()` inside `RunE` handlers to propagate context. Never call
`context.Background()` when you already have a command context.

```go
func runInstall(cmd *cobra.Command, args []string) error {
    ctx := cmd.Context()
    rel, found, err := up.DetectLatest(ctx, slug)
    // ...
}
```

## Version and self-update

For tools distributed as binaries, use `go-selfupdate-mini` to wire up `version`
and `update` commands:

```go
func init() {
    selfupdate.RegisterCommands(rootCmd, selfupdate.ParseSlug("wow-look-at-my/myapp"))
}
```

The library auto-detects the running binary's version from build info. No need to
set `EmbeddedVersion` manually -- the autorelease tag scheme (`v0.0.<unix-seconds>`)
is detected from VCS metadata.

## Testing commands

Test helpers that execute commands and capture output:

```go
func execute(args ...string) (string, string, error) {
    stdout := &bytes.Buffer{}
    stderr := &bytes.Buffer{}
    rootCmd.SetOut(stdout)
    rootCmd.SetErr(stderr)
    rootCmd.SetArgs(args)
    err := rootCmd.Execute()
    return stdout.String(), stderr.String(), err
}
```

Since cobra binds flags to package-level vars, tests must restore them:

```go
func resetFlags(t *testing.T) {
    t.Helper()
    old := installVersion
    t.Cleanup(func() { installVersion = old })
}
```

Use `withTempState(t)` patterns to isolate tests from real on-disk state.
