#!/bin/bash

# Sync agents from ai/ repository to ~/.claude
# This ensures single source of truth in the ai/ repo

set -e

CLAUDE_DIR="$HOME/.claude"
DOTFILES_DIR="$(dirname "$(dirname "$0")")"
AGENTS_DIR="$DOTFILES_DIR/ai/agents"

echo "🔄 Syncing agents to ~/.claude..."

# Create ~/.claude/agents directory if it doesn't exist
mkdir -p "$CLAUDE_DIR/agents"

# Copy all agent files
if [ -d "$AGENTS_DIR" ]; then
    cp -r "$AGENTS_DIR"/* "$CLAUDE_DIR/agents/"
    echo "✅ Copied agents from $AGENTS_DIR to $CLAUDE_DIR/agents/"
    
    # List what was synced
    echo "📋 Synced agents:"
    ls -la "$CLAUDE_DIR/agents/"
else
    echo "❌ Agents directory not found at $AGENTS_DIR"
    exit 1
fi

echo "🎉 Agent sync complete!"