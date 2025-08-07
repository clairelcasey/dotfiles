#!/usr/bin/env bash
# --------------------------------------------------------------
# sync-cursor-rules.sh
#
# Usage (inside a Git repo):
#   ~/dotfiles/scripts/sync-cursor-rules.sh
#
# - Creates or updates ~/dotfiles/ai/config/personal-global.mdc
#   by concatenating **all** markdown rule files found in
#   ~/dotfiles/ai/rules/ (alphabetical order).
# - Symlinks that file into .cursor/rules/user-rules/ in
#   the current repository, overwriting any previous symlink.
# - Adds '.cursor/rules/user-rules/' to .git/info/exclude.
# --------------------------------------------------------------

set -euo pipefail

AI_RULE_DIR="$HOME/dotfiles/ai"
RULES_DIR="$AI_RULE_DIR/rules"
COMBINED="$AI_RULE_DIR/config/personal-global.mdc"
DEST_SUBDIR=".cursor/rules/user-rules"
DEST_FILE="personal-global.mdc"

if [ ! -d "$RULES_DIR" ]; then
  echo "Error: expected rule directory $RULES_DIR not found" >&2
  exit 1
fi

# Verify we are in a Git repository
if ! git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo "Error: must be run inside a Git repository" >&2
  exit 1
fi

# 1. Build/overwrite the combined MDC file
{
  echo "---"
  echo "description: Personal global dev guidelines"
  echo "globs:"
  echo "alwaysApply: true"
  echo "---"
  echo
  for src in $(ls -1 "$RULES_DIR"/*.md 2>/dev/null | sort); do
    rule="$(basename "$src")"
    printf "## %s\n\n" "${rule%.md}"
    cat "$src"
    echo -e "\n\n"
  done
} > "$COMBINED"
echo "✔︎ Built $COMBINED"

# 2. Symlink **each** rule file into the current repo (better granularity for Cursor)
dest_dir="$git_root/$DEST_SUBDIR"
mkdir -p "$dest_dir"

# Clean out previous rule files (.md/.mdc) in dest_dir to avoid stale copies
find "$dest_dir" -maxdepth 1 -type f \( -name "*.md" -o -name "*.mdc" \) -exec rm {} + || true

# Create an .mdc file for each rule with always-apply front-matter
for src in $(ls -1 "$RULES_DIR"/*.md 2>/dev/null | sort); do
  rule_basename="$(basename "$src" .md)"
  dest_mdc="$dest_dir/${rule_basename}.mdc"
  {
    echo "---"
    echo "description: ${rule_basename//_/ }"
    echo "globs:"
    echo "alwaysApply: true"
    echo "---"
    echo
    cat "$src"
  } > "$dest_mdc"
done

echo "✔︎ Generated individual .mdc rule files into $dest_dir"

# 3. Ensure folders are ignored by Git
exclude_file="$git_root/.git/info/exclude"

# Exclude cursor rules directory
pattern="$DEST_SUBDIR/"
if ! grep -qxF "$pattern" "$exclude_file" 2>/dev/null; then
  echo "$pattern" >> "$exclude_file"
  echo "✔︎ Added $pattern to .git/info/exclude"
fi

# Exclude task-lists directory
task_lists_pattern="task-lists/"
if ! grep -qxF "$task_lists_pattern" "$exclude_file" 2>/dev/null; then
  echo "$task_lists_pattern" >> "$exclude_file"
  echo "✔︎ Added $task_lists_pattern to .git/info/exclude"
fi

echo "✅ Cursor rules synced and linked."