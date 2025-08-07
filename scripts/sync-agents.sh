#!/usr/bin/env bash
# --------------------------------------------------------------
# sync-agents.sh
#
# Usage:
#   ~/dotfiles/scripts/sync-agents.sh
#
# Orchestrates syncing of all Claude-related components:
# - Claude prompts
# - Claude agents  
# - Claude commands/rules
# --------------------------------------------------------------

set -euo pipefail

# Get the actual directory of this script, following symlinks
SCRIPT_PATH="$0"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
done
AI_DIR="$(dirname "$SCRIPT_PATH")"

echo "🚀 Starting Claude agents sync..."

# 1. Sync Claude prompts
echo ""
echo "📝 Syncing Claude prompts..."
CLAUDE_PROMPTS_SCRIPT="$AI_DIR/sync-claude-prompts.sh"
if [ -f "$CLAUDE_PROMPTS_SCRIPT" ]; then
    "$CLAUDE_PROMPTS_SCRIPT"
else
    echo "⚠️  Warning: $CLAUDE_PROMPTS_SCRIPT not found"
fi

# 2. Sync Claude agents
echo ""
echo "🤖 Syncing Claude agents..."
CLAUDE_AGENTS_SCRIPT="$AI_DIR/sync-claude-agents.sh"
if [ -f "$CLAUDE_AGENTS_SCRIPT" ]; then
    "$CLAUDE_AGENTS_SCRIPT"
else
    echo "⚠️  Warning: $CLAUDE_AGENTS_SCRIPT not found"
fi

# 3. Sync Claude commands/rules
echo ""
echo "⚙️  Syncing Claude commands..."
CLAUDE_COMMANDS_SCRIPT="$AI_DIR/sync-claude-commands.sh"
if [ -f "$CLAUDE_COMMANDS_SCRIPT" ]; then
    "$CLAUDE_COMMANDS_SCRIPT"
else
    echo "⚠️  Warning: $CLAUDE_COMMANDS_SCRIPT not found"
fi

# 4. Sync Cursor rules (only if in a git repo)
echo ""
echo "📝 Syncing Cursor rules..."
CURSOR_RULES_SCRIPT="$AI_DIR/sync-cursor-rules.sh"
if [ -f "$CURSOR_RULES_SCRIPT" ]; then
    if git rev-parse --show-toplevel &>/dev/null; then
        "$CURSOR_RULES_SCRIPT"
    else
        echo "ℹ️  Not in a git repository - skipping Cursor rules sync"
    fi
else
    echo "⚠️  Warning: $CURSOR_RULES_SCRIPT not found"
fi

echo ""
echo "✅ Claude agents sync completed successfully!"