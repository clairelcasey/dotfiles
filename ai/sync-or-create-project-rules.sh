#!/usr/bin/env bash
# --------------------------------------------------------------
# sync-or-create-project-rules.sh
#
# Usage (inside a Git repo):
#   ~/dotfiles/ai/sync-or-create-project-rules.sh
#
# Ensures consistency between CLAUDE.md and .cursor/rules directory.
# - If CLAUDE.md exists but .cursor/rules doesn't, creates symlink
# - If .cursor/rules exists but CLAUDE.md doesn't, creates CLAUDE.md from rules
# - If neither exists, suggests running `/init` from Claude
# - If both exist, assumes they're managed and skips
# --------------------------------------------------------------

set -euo pipefail

# Verify we are in a Git repository
if ! git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo "Error: must be run inside a Git repository" >&2
  exit 1
fi

CLAUDE_FILE="$git_root/CLAUDE.md"
CURSOR_RULES_DIR="$git_root/.cursor/rules"

# Check what exists
claude_exists=false
cursor_rules_exists=false

if [ -f "$CLAUDE_FILE" ]; then
  claude_exists=true
fi

if [ -d "$CURSOR_RULES_DIR" ]; then
  # Check if directory has any .md files
  if ls "$CURSOR_RULES_DIR"/*.md >/dev/null 2>&1; then
    cursor_rules_exists=true
  fi
fi

# Function to create .cursor/rules from existing CLAUDE.md
create_cursor_rules_from_claude() {
  mkdir -p "$CURSOR_RULES_DIR"
  
  # Create a symlink to the existing CLAUDE.md
  local symlink_target="$CURSOR_RULES_DIR/project.md"
  local relative_path="../../CLAUDE.md"
  
  if [ -L "$symlink_target" ]; then
    rm "$symlink_target"
  fi
  
  ln -s "$relative_path" "$symlink_target"
  echo "✅ Created symlink: .cursor/rules/project.md -> CLAUDE.md"
}

# Function to create CLAUDE.md from .cursor/rules files
create_claude_from_cursor_rules() {
  local rule_files=()
  
  # Find all .md files in .cursor/rules
  while IFS= read -r -d '' file; do
    rule_files+=("$(basename "$file")")
  done < <(find "$CURSOR_RULES_DIR" -maxdepth 1 -name "*.md" -print0 2>/dev/null || true)
  
  if [ ${#rule_files[@]} -eq 0 ]; then
    echo "⚠️  No .md files found in .cursor/rules directory"
    return
  fi
  
  # Create CLAUDE.md with references
  {
    echo "# Development Standards"
    echo ""
    
    for file in "${rule_files[@]}"; do
      # Convert filename to readable title
      local title=$(basename "$file" .md | tr '_-' ' ' | sed 's/\b\w/\U&/g')
      echo "$title: @.cursor/rules/$file"
    done
    
    echo ""
    echo "<!-- This file was auto-created from .cursor/rules directory -->"
    echo "<!-- Edit the individual rule files in .cursor/rules/ -->"
  } > "$CLAUDE_FILE"
  
  echo "✅ Created CLAUDE.md with ${#rule_files[@]} rule references"
}

echo "🔍 Checking project rules setup..."

# Handle the four cases
if $claude_exists && $cursor_rules_exists; then
  echo "✅ Both CLAUDE.md and .cursor/rules exist - assuming they're managed"
  exit 0
elif ! $claude_exists && ! $cursor_rules_exists; then
  echo "ℹ️  Neither CLAUDE.md nor .cursor/rules directory found."
  echo "   You may want to run \`/init\` from Claude to set up project rules."
  exit 0
elif $claude_exists && ! $cursor_rules_exists; then
  echo "📝 Found CLAUDE.md but no .cursor/rules - creating symlink..."
  create_cursor_rules_from_claude
elif ! $claude_exists && $cursor_rules_exists; then
  echo "📁 Found .cursor/rules but no CLAUDE.md - creating CLAUDE.md..."
  create_claude_from_cursor_rules
fi

echo "✅ Project rules sync completed"