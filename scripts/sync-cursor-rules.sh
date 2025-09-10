#!/usr/bin/env bash
# --------------------------------------------------------------
# sync-cursor-rules.sh
#
# Usage (inside a Git repo):
#   ~/dotfiles/scripts/sync-cursor-rules.sh
#
# - Copies the unified ~/.claude/AGENTS.md file to .cursor/rules/AGENTS.md
#   in the current repository.
# - Adds '.cursor/rules/' to .git/info/exclude.
# --------------------------------------------------------------

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
AGENTS_FILE="$CLAUDE_DIR/AGENTS.md"
DEST_SUBDIR=".cursor/rules"
DEST_FILE="AGENTS.md"

if [ ! -f "$AGENTS_FILE" ]; then
  echo "Error: AGENTS.md not found at $AGENTS_FILE" >&2
  echo "Run sync-agents-commands.sh first to create the AGENTS.md file" >&2
  exit 1
fi

# Verify we are in a Git repository
if ! git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo "Error: must be run inside a Git repository" >&2
  exit 1
fi

# 1. Copy AGENTS.md to destination
dest_dir="$git_root/$DEST_SUBDIR"
mkdir -p "$dest_dir"
cp "$AGENTS_FILE" "$dest_dir/$DEST_FILE"
echo "✔︎ Copied $AGENTS_FILE to $dest_dir/$DEST_FILE"

# 2. Ensure cursor rules directory is ignored by Git
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

echo "✅ AGENTS.md copied to Cursor rules directory."