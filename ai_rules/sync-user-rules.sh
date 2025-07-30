#!/usr/bin/env bash
# --------------------------------------------------------------
# sync-user-rules.sh
#
# Usage (inside a Git repo):
#   ~/dotfiles/ai_rules/sync-user-rules.sh
#
# - Creates or updates ~/dotfiles/ai_rules/personal-global.mdc
#   by concatenating **all** markdown rule files found in
#   ~/dotfiles/ai_rules/global/ (alphabetical order).
# - Symlinks that file into .cursor/rules/user-rules/ in
#   the current repository, overwriting any previous symlink.
# - Adds '.cursor/rules/user-rules/' to .git/info/exclude.
# --------------------------------------------------------------

set -euo pipefail

AI_RULE_DIR="$HOME/dotfiles/ai_rules"
GLOBAL_DIR="$AI_RULE_DIR/global"
COMBINED="$AI_RULE_DIR/personal-global.mdc"
DEST_SUBDIR=".cursor/rules/user-rules"
DEST_FILE="personal-global.mdc"

if [ ! -d "$GLOBAL_DIR" ]; then
  echo "Error: expected rule directory $GLOBAL_DIR not found" >&2
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
  for src in $(ls -1 "$GLOBAL_DIR"/*.md 2>/dev/null | sort); do
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
for src in $(ls -1 "$GLOBAL_DIR"/*.md 2>/dev/null | sort); do
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

# 2b. Create/update symlinks in ~/.claude and index file
CLAUDE_DIR="$HOME/.claude"
CLAUDE_FILE="$CLAUDE_DIR/CLAUDE.md"
mkdir -p "$CLAUDE_DIR"

# Iterate over global rule files and create/update symlinks in ~/.claude
for src in $(ls -1 "$GLOBAL_DIR"/*.md 2>/dev/null | sort); do
  ln -sf "$src" "$CLAUDE_DIR/$(basename "$src")"
  created_symlinks+=("$(basename "$src")")
done

# Rebuild CLAUDE.md with list of links to symlinked files
{
  echo "# Claude Global Rule Symlinks"
  echo ""
  echo "These are symlinks to the current set of personal global rule files."
  echo ""
  for file in "${created_symlinks[@]}"; do
    echo "- [${file}](${file})"
  done
} > "$CLAUDE_FILE"

echo "✔︎ Updated symlinks and index at $CLAUDE_FILE"

# 3. Ensure folder is ignored by Git
exclude_file="$git_root/.git/info/exclude"
pattern="$DEST_SUBDIR/"
if ! grep -qxF "$pattern" "$exclude_file" 2>/dev/null; then
  echo "$pattern" >> "$exclude_file"
  echo "✔︎ Added $pattern to .git/info/exclude"
fi

echo "✅ User rules synced and linked."

# 4. Sync Claude command policies
echo ""
echo "🔧 Syncing Claude command policies..."
CLAUDE_SYNC_SCRIPT="$(dirname "$0")/sync-claude-commands.sh"
"$CLAUDE_SYNC_SCRIPT"
