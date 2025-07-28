#!/usr/bin/env bash
# --------------------------------------------------------------
# sync-claude-commands.sh
#
# Usage:
#   ~/dotfiles/ai_rules/sync-claude-commands.sh
#
# - Parses allowed and forbidden commands from _global.md
# - Updates ~/.claude/settings.local.json with command policies
# --------------------------------------------------------------

set -euo pipefail

AI_RULE_DIR="$HOME/dotfiles/ai_rules"
GLOBAL_FILE="$AI_RULE_DIR/global/_global.md"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.local.json"

if [ ! -f "$GLOBAL_FILE" ]; then
  echo "Error: expected rule file $GLOBAL_FILE not found" >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

# Parse allowed commands from _global.md
parse_allowed_commands() {
  # Extract lines between "## Always Allowed Commands" and next "##" marker
  sed -n '/^## Always Allowed Commands$/,/^##/p' "$GLOBAL_FILE" | \
  grep '^- `' | \
  sed 's/^- `\([^`]*\)`.*/\1/' | \
  sort
}

# Parse forbidden commands from _global.md  
parse_forbidden_commands() {
  # Extract lines between "## Forbidden Commands" and end of file (since it's the last section)
  # Only get the first command before any parenthetical explanations
  sed -n '/^## Forbidden Commands$/,$p' "$GLOBAL_FILE" | \
  grep '^- `' | \
  sed 's/^- `\([^`(]*\).*/\1/' | \
  sed 's/[[:space:]]*$//' | \
  sort
}

# Build JSON structure
build_settings_json() {
  # Start JSON structure
  echo "{"
  echo "  \"command_execution\": {"
  echo "    \"policy\": {"
  
  # Add allowed commands
  echo "      \"allowed_commands\": ["
  local first=true
  while read -r cmd; do
    if [ "$first" = true ]; then
      first=false
      echo "        \"$cmd\""
    else
      echo "        ,\"$cmd\""
    fi
  done < <(parse_allowed_commands)
  echo "      ],"
  
  # Add forbidden commands  
  echo "      \"forbidden_commands\": ["
  first=true
  while read -r cmd; do
    if [ "$first" = true ]; then
      first=false
      echo "        \"$cmd\""
    else
      echo "        ,\"$cmd\""
    fi
  done < <(parse_forbidden_commands)
  echo "      ]"
  
  echo "    },"
  echo "    \"description\": \"Command execution policy synced from ai_rules/_global.md\","
  echo "    \"last_updated\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
  echo "  }"
  echo "}"
}

# Create or update settings file
build_settings_json > "$SETTINGS_FILE"

echo "✔︎ Updated Claude command policies at $SETTINGS_FILE"

# Show summary
echo ""
echo "📋 Command Policy Summary:"
echo "  Allowed: $(parse_allowed_commands | wc -l | tr -d ' ') commands"
echo "  Forbidden: $(parse_forbidden_commands | wc -l | tr -d ' ') commands"
echo ""
echo "✅ Claude settings updated." 