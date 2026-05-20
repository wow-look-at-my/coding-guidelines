#!/usr/bin/env bash
set -euo pipefail

rm -rf build
mkdir -p build

# Order matches README structure
go_files=(
    go-style.md
    go-project-structure.md
    go-error-handling.md
    go-testing.md
    go-cli-design.md
    go-interfaces.md
)
ts_files=(
    typescript-style.md
)
general_files=(
    file-organization.md
    ci-cd.md
    git-workflow.md
)

all_files=("${go_files[@]}" "${ts_files[@]}" "${general_files[@]}")

# --- llms.txt (index) ---
# Extract description for a file from README.md (text after " -- ")
desc_for() {
    grep -F "($1)" README.md | sed 's/.*-- //' | head -1
}

{
    cat <<'EOF'
# Coding Guidelines

> Code style and conventions for the wow-look-at-my org. Covers Go, TypeScript, file organization, CI/CD, and git workflow.

## Go

EOF
    for f in "${go_files[@]}"; do
        title="$(head -1 "$f" | sed 's/^# //')"
        printf -- '- [%s](%s): %s\n' "$title" "$f" "$(desc_for "$f")"
    done

    cat <<'EOF'

## TypeScript

EOF
    for f in "${ts_files[@]}"; do
        title="$(head -1 "$f" | sed 's/^# //')"
        printf -- '- [%s](%s): %s\n' "$title" "$f" "$(desc_for "$f")"
    done

    cat <<'EOF'

## General

EOF
    for f in "${general_files[@]}"; do
        title="$(head -1 "$f" | sed 's/^# //')"
        printf -- '- [%s](%s): %s\n' "$title" "$f" "$(desc_for "$f")"
    done

    printf '\n## Full content\n\n'
    printf -- '- [llms-full.txt](llms-full.txt): All coding guidelines in a single file\n'
} > build/llms.txt

# --- llms-full.txt (concatenated) ---
{
    printf '# Coding Guidelines\n\n'
    printf '> Code style and conventions for the wow-look-at-my org.\n\n'
    for f in "${all_files[@]}"; do
        cat "$f"
        printf '\n\n---\n\n'
    done
} > build/llms-full.txt

# Copy individual markdown files so links in llms.txt resolve
for f in "${all_files[@]}"; do
    cp "$f" "build/$f"
done

echo "Built $(ls build/ | wc -l) files into build/"
