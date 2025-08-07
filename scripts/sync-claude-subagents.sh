#!/bin/bash

# Sync subagents from ai/ repository to ~/.claude
# This ensures single source of truth in the ai/ repo

set -e

CLAUDE_DIR="$HOME/.claude"
DOTFILES_DIR="$(dirname "$(dirname "$0")")"
SUBAGENTS_DIR="$DOTFILES_DIR/ai/subagents"

echo "🔄 Syncing subagents to ~/.claude..."

# Create ~/.claude/agents directory if it doesn't exist
mkdir -p "$CLAUDE_DIR/agents"

# Copy all subagent files
if [ -d "$SUBAGENTS_DIR" ]; then
    cp -r "$SUBAGENTS_DIR"/* "$CLAUDE_DIR/agents/"
    echo "✅ Copied subagents from $SUBAGENTS_DIR to $CLAUDE_DIR/agents/"
    
    # List what was synced
    echo "📋 Synced subagents:"
    ls -la "$CLAUDE_DIR/agents/"
else
    echo "❌ Subagents directory not found at $SUBAGENTS_DIR"
    exit 1
fi

echo "🎉 Subagent sync complete!"