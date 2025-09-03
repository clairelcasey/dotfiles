#!/usr/bin/env bash
# --------------------------------------------------------------
# manage-commands.sh
#
# Manage allowed commands in commands.json
# Usage: 
#   ./manage-commands.sh add <command> <description> <category> [examples...]
#   ./manage-commands.sh remove <command>
#   ./manage-commands.sh list [category]
#   ./manage-commands.sh validate
#   ./manage-commands.sh sync
# --------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
COMMANDS_JSON="$DOTFILES_DIR/ai/config/commands.json"

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    echo "Install with: brew install jq" >&2
    exit 1
fi

# Check if commands.json exists
if [[ ! -f "$COMMANDS_JSON" ]]; then
    echo "Error: commands.json not found at $COMMANDS_JSON" >&2
    exit 1
fi

# Function to add a command
add_command() {
    local command="$1"
    local description="$2"
    local category="$3"
    shift 3
    local examples=("$@")
    
    # Validate category
    local valid_categories=("package_management" "file_operations" "git" "system_info" "text_processing" "web" "tools")
    if [[ ! " ${valid_categories[@]} " =~ " ${category} " ]]; then
        echo "Error: Invalid category '$category'" >&2
        echo "Valid categories: ${valid_categories[*]}" >&2
        exit 1
    fi
    
    # Check if command already exists
    if jq -e --arg cmd "$command" '.always_allowed[] | select(.command == $cmd)' "$COMMANDS_JSON" >/dev/null; then
        echo "Error: Command '$command' already exists" >&2
        exit 1
    fi
    
    # Create new command object
    local new_command=$(jq -n \
        --arg cmd "$command" \
        --arg desc "$description" \
        --arg cat "$category" \
        --argjson examples "$(printf '%s\n' "${examples[@]}" | jq -R . | jq -s .)" \
        '{
            command: $cmd,
            description: $desc,
            category: $cat,
            examples: $examples
        }')
    
    # Add to commands.json
    local temp_file=$(mktemp)
    jq --argjson new_cmd "$new_command" \
        '.always_allowed += [$new_cmd] | .always_allowed |= sort_by(.command)' \
        "$COMMANDS_JSON" > "$temp_file"
    
    mv "$temp_file" "$COMMANDS_JSON"
    echo "✅ Added command: $command"
}

# Function to remove a command
remove_command() {
    local command="$1"
    
    # Check if command exists
    if ! jq -e --arg cmd "$command" '.always_allowed[] | select(.command == $cmd)' "$COMMANDS_JSON" >/dev/null; then
        echo "Error: Command '$command' not found" >&2
        exit 1
    fi
    
    # Remove from commands.json
    local temp_file=$(mktemp)
    jq --arg cmd "$command" \
        '.always_allowed = [.always_allowed[] | select(.command != $cmd)]' \
        "$COMMANDS_JSON" > "$temp_file"
    
    mv "$temp_file" "$COMMANDS_JSON"
    echo "✅ Removed command: $command"
}

# Function to list commands
list_commands() {
    local category="${1:-}"
    
    if [[ -n "$category" ]]; then
        echo "📋 Commands in category '$category':"
        jq -r --arg cat "$category" \
            '.always_allowed[] | select(.category == $cat) | "  \(.command) - \(.description)"' \
            "$COMMANDS_JSON"
    else
        echo "📋 All allowed commands:"
        jq -r '.always_allowed[] | "  \(.command) (\(.category)) - \(.description)"' "$COMMANDS_JSON"
        
        echo ""
        echo "📋 Commands requiring confirmation:"
        jq -r '.needs_confirmation[] | "  \(.command) (\(.risk_level)) - \(.description)"' "$COMMANDS_JSON"
    fi
}

# Function to validate commands.json
validate_commands() {
    echo "🔍 Validating commands.json..."
    
    # Check JSON syntax
    if ! jq empty "$COMMANDS_JSON" 2>/dev/null; then
        echo "❌ Invalid JSON syntax" >&2
        exit 1
    fi
    
    # Check for duplicate commands
    local duplicates=$(jq -r '.always_allowed[].command' "$COMMANDS_JSON" | sort | uniq -d)
    if [[ -n "$duplicates" ]]; then
        echo "❌ Duplicate commands found:" >&2
        echo "$duplicates" >&2
        exit 1
    fi
    
    # Check required fields
    local missing_fields=$(jq -r '
        .always_allowed[] | 
        select(.command == null or .description == null or .category == null) |
        "Missing required fields in: \(.command // "unknown")"
    ' "$COMMANDS_JSON")
    
    if [[ -n "$missing_fields" ]]; then
        echo "❌ Commands with missing required fields:" >&2
        echo "$missing_fields" >&2
        exit 1
    fi
    
    echo "✅ commands.json is valid"
}

# Function to sync changes to rule files
sync_rules() {
    echo "🔄 Syncing command rules..."
    "$SCRIPT_DIR/generate-command-rules.sh" all
    
    # Update metadata
    local temp_file=$(mktemp)
    jq --arg date "$(date -u +%Y-%m-%d)" \
        '.metadata.last_updated = $date' \
        "$COMMANDS_JSON" > "$temp_file"
    
    mv "$temp_file" "$COMMANDS_JSON"
    echo "✅ Sync completed"
}

# Main execution
case "${1:-}" in
    "add")
        if [[ $# -lt 4 ]]; then
            echo "Usage: $0 add <command> <description> <category> [examples...]" >&2
            exit 1
        fi
        add_command "$2" "$3" "$4" "${@:5}"
        ;;
    "remove")
        if [[ $# -ne 2 ]]; then
            echo "Usage: $0 remove <command>" >&2
            exit 1
        fi
        remove_command "$2"
        ;;
    "list")
        list_commands "${2:-}"
        ;;
    "validate")
        validate_commands
        ;;
    "sync")
        validate_commands
        sync_rules
        ;;
    *)
        echo "Usage: $0 {add|remove|list|validate|sync}" >&2
        echo "" >&2
        echo "Commands:" >&2
        echo "  add <command> <description> <category> [examples...]  - Add a new command" >&2
        echo "  remove <command>                                       - Remove a command" >&2
        echo "  list [category]                                        - List commands" >&2
        echo "  validate                                               - Validate commands.json" >&2
        echo "  sync                                                   - Sync changes to rule files" >&2
        echo "" >&2
        echo "Categories: package_management, file_operations, git, system_info, text_processing, web, tools" >&2
        exit 1
        ;;
esac