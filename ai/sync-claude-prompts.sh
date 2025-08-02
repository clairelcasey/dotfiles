#!/usr/bin/env bash
# --------------------------------------------------------------
# sync-claude-prompts.sh
#
# Usage:
#   ~/dotfiles/ai/sync-claude-prompts.sh
#
# - Combines all markdown files from prompts/ directory
# - Updates ~/.claude/ with individual prompt files for Claude Code
# --------------------------------------------------------------

set -euo pipefail

AI_RULE_DIR="$HOME/dotfiles/ai"
PROMPTS_DIR="$AI_RULE_DIR/prompts"
CLAUDE_DIR="$HOME/.claude"

if [ ! -d "$PROMPTS_DIR" ]; then
  echo "Info: prompts directory $PROMPTS_DIR not found - skipping prompts sync" >&2
  exit 0
fi

mkdir -p "$CLAUDE_DIR"

# Copy each prompt file to ~/.claude/ as a .prompt file
prompt_count=0
for prompt_file in "$PROMPTS_DIR"/*.md; do
  if [ -f "$prompt_file" ]; then
    filename=$(basename "$prompt_file" .md)
    dest_file="$CLAUDE_DIR/${filename}.prompt"
    
    # Copy the content, Claude Code will recognize .prompt files
    cp "$prompt_file" "$dest_file"
    echo "✔︎ Synced prompt: $filename"
    ((prompt_count++))
  fi
done

if [ $prompt_count -eq 0 ]; then
  echo "Info: No prompt files found in $PROMPTS_DIR"
else
  echo "✅ Synced $prompt_count prompt(s) to $CLAUDE_DIR"
fi