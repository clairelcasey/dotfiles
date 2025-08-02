#!/usr/bin/env bash
# --------------------------------------------------------------
# sync-claude-commands.sh
#
# Usage:
#   ~/dotfiles/ai/sync-claude-commands.sh
#
# - Combines all markdown files from global/ directory
# - Creates a unified ~/.claude/CLAUDE.md file with all rules
# --------------------------------------------------------------

set -euo pipefail

AI_RULE_DIR="$HOME/dotfiles/ai"
RULES_DIR="$AI_RULE_DIR/rules"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_FILE="$CLAUDE_DIR/CLAUDE.md"

if [ ! -d "$RULES_DIR" ]; then
  echo "Error: expected rules directory $RULES_DIR not found" >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

# Build combined CLAUDE.md file
build_claude_md() {
  echo "# AI Assistant Rules"
  echo ""
  echo "This file contains all AI assistant rules and preferences combined from the rules configuration."
  echo ""
  echo "Last updated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  echo ""
  echo "---"
  echo ""
  
  # Process each markdown file in the rules directory
  find "$RULES_DIR" -name "*.md" -type f | sort | while read -r md_file; do
    filename=$(basename "$md_file")
    echo "<!-- START: $filename -->"
    echo ""
    
    # Add the content of the file
    cat "$md_file"
    
    echo ""
    echo "<!-- END: $filename -->"
    echo ""
    echo "---"
    echo ""
  done
}

# Create the unified CLAUDE.md file
build_claude_md > "$CLAUDE_FILE"

echo "✔︎ Created unified Claude rules file at $CLAUDE_FILE"

# Show summary
echo ""
echo "📋 Files Combined:"
find "$RULES_DIR" -name "*.md" -type f | while read -r md_file; do
  filename=$(basename "$md_file")
  lines=$(wc -l < "$md_file")
  echo "  - $filename ($lines lines)"
done

echo ""
echo "✅ Claude rules unified and updated."

# Sync Claude prompts
echo ""
echo "🔧 Syncing Claude prompts..."
CLAUDE_PROMPTS_SCRIPT="$(dirname "$0")/sync-claude-prompts.sh"
"$CLAUDE_PROMPTS_SCRIPT" 