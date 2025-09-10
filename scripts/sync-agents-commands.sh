#!/usr/bin/env bash
# --------------------------------------------------------------
# sync-agents-commands.sh
#
# Usage:
#   ~/dotfiles/scripts/sync-agents-commands.sh
#
# - Combines all markdown files from rules/ directory
# - Creates a unified ~/.claude/AGENTS.md file with all rules
# - Creates symlink from CLAUDE.md to AGENTS.md for backward compatibility
# --------------------------------------------------------------

set -euo pipefail

AI_RULE_DIR="$HOME/dotfiles/ai"
RULES_DIR="$AI_RULE_DIR/rules"
CLAUDE_DIR="$HOME/.claude"
AGENTS_FILE="$CLAUDE_DIR/AGENTS.md"
CLAUDE_FILE="$CLAUDE_DIR/CLAUDE.md"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ ! -d "$RULES_DIR" ]; then
  echo "Error: expected rules directory $RULES_DIR not found" >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

# Build combined AGENTS.md file
build_agents_md() {
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
    
    # Add the content of the file, excluding command permission sections
    if [ "$filename" = "AGENTS.md" ]; then
      # For AGENTS.md, exclude the command permission sections since they're in settings.json
      sed '/^## Always Allowed Commands$/,/^> The assistant should refuse/d' "$md_file"
    else
      cat "$md_file"
    fi
    
    echo ""
    echo "<!-- END: $filename -->"
    echo ""
    echo "---"
    echo ""
  done
}

# Parse allowed commands from AGENTS.md
parse_allowed_commands() {
  local global_file="$RULES_DIR/AGENTS.md"
  if [ ! -f "$global_file" ]; then
    echo "Warning: AGENTS.md not found" >&2
    return
  fi
  
  # Extract commands between "## Always Allowed Commands" and next "##" section
  sed -n '/^## Always Allowed Commands$/,/^##/p' "$global_file" | \
    grep '^- `' | \
    sed 's/^- `\([^`]*\)`.*/\1/' | \
    while read -r cmd; do
      if [ "$cmd" = "WebFetch" ]; then
        echo "\"WebFetch\""
      else
        echo "\"Bash($cmd:*)\""
      fi
    done
}

# Parse forbidden commands from AGENTS.md
parse_forbidden_commands() {
  local global_file="$RULES_DIR/AGENTS.md"
  if [ ! -f "$global_file" ]; then
    echo "Warning: AGENTS.md not found" >&2
    return
  fi
  
  # Extract commands between "## Forbidden Commands" and next "##" section
  sed -n '/^## Forbidden Commands$/,/^##/p' "$global_file" | \
    grep '^- `' | \
    sed 's/^- `\([^`]*\)`.*/\1/' | \
    while read -r cmd; do
      echo "\"Bash($cmd:*)\""
    done
}

# Update or create settings.json with permissions
update_settings_json() {
  local allowed_commands=()
  local forbidden_commands=()
  
  # Read allowed commands into array
  while IFS= read -r cmd; do
    [ -n "$cmd" ] && allowed_commands+=("$cmd")
  done < <(parse_allowed_commands)
  
  # Read forbidden commands into array  
  while IFS= read -r cmd; do
    [ -n "$cmd" ] && forbidden_commands+=("$cmd")
  done < <(parse_forbidden_commands)
  
  # Add additional pre-configured allowed commands (not in AGENTS.md)
  allowed_commands+=(
    "\"Bash(~/dotfiles/scripts/sync-or-create-project-rules.sh:*)\""
    "\"Bash(mv:*)\""
    "\"Bash(find:*)\""
    "\"Bash(git fetch:*)\""
    "\"Bash(bash:*)\""
  )
  
  # Create permissions object
  local allow_list=""
  local deny_list=""
  
  if [ ${#allowed_commands[@]} -gt 0 ]; then
    allow_list=$(IFS=','; echo "${allowed_commands[*]}")
  fi
  
  if [ ${#forbidden_commands[@]} -gt 0 ]; then
    deny_list=$(IFS=','; echo "${forbidden_commands[*]}")
  fi
  
  # Read existing settings or create base structure
  local existing_settings="{}"
  if [ -f "$SETTINGS_FILE" ]; then
    existing_settings=$(cat "$SETTINGS_FILE")
  fi
  
  # Create new settings with permissions
  local new_settings
  if command -v jq >/dev/null 2>&1; then
    # Use jq if available for proper JSON manipulation
    new_settings=$(echo "$existing_settings" | jq --argjson allow "[$allow_list]" --argjson deny "[$deny_list]" '
      . + {
        "$schema": "https://json.schemastore.org/claude-code-settings.json",
        "permissions": {
          "allow": $allow,
          "deny": $deny
        }
      }
    ')
  else
    # Fallback to manual JSON construction
    new_settings=$(cat <<EOF
{
  "\$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [$allow_list],
    "deny": [$deny_list]
  }
}
EOF
)
    # Preserve existing feedbackSurveyState if it exists
    if echo "$existing_settings" | grep -q "feedbackSurveyState"; then
      local feedback_state=$(echo "$existing_settings" | grep -o '"feedbackSurveyState":[^}]*}' || echo "")
      if [ -n "$feedback_state" ]; then
        new_settings=$(echo "$new_settings" | sed "s/}$/,\"$feedback_state\"}/" | sed 's/""feedbackSurveyState"//')
      fi
    fi
  fi
  
  # Write updated settings
  echo "$new_settings" > "$SETTINGS_FILE"
}

# Create the unified AGENTS.md file
build_agents_md > "$AGENTS_FILE"

echo "✔︎ Created unified agents rules file at $AGENTS_FILE"

# Create symlink from CLAUDE.md to AGENTS.md for backward compatibility
if [ -L "$CLAUDE_FILE" ] || [ -f "$CLAUDE_FILE" ]; then
  rm "$CLAUDE_FILE"
fi
ln -s "$(basename "$AGENTS_FILE")" "$CLAUDE_FILE"
echo "✔︎ Created symlink from CLAUDE.md to AGENTS.md"

# Update settings.json with command permissions
update_settings_json

echo "✔︎ Updated agent settings file at $SETTINGS_FILE"

# Show summary
echo ""
echo "📋 Files Combined:"
find "$RULES_DIR" -name "*.md" -type f | while read -r md_file; do
  filename=$(basename "$md_file")
  lines=$(wc -l < "$md_file")
  echo "  - $filename ($lines lines)"
done

echo ""
echo "✅ Agent rules and settings unified and updated."

# Sync Claude prompts
echo ""
echo "🔧 Syncing Claude prompts..."
CLAUDE_PROMPTS_SCRIPT="$(dirname "$0")/sync-claude-prompts.sh"
"$CLAUDE_PROMPTS_SCRIPT" 