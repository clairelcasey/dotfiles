#!/usr/bin/env bash
# --------------------------------------------------------------
# generate-command-rules.sh
#
# Generates command execution rules from commands.json for different AI tools
# Usage: ./generate-command-rules.sh [target]
# Targets: claude, cursor, all (default)
# --------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
COMMANDS_JSON="$DOTFILES_DIR/ai/config/commands.json"
AI_RULES_DIR="$DOTFILES_DIR/ai/rules"

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

# Function to generate markdown command list for Claude Code
generate_claude_commands() {
    local output_file="$AI_RULES_DIR/AGENTS.md"
    local temp_file=$(mktemp)
    
    # Read the current file and extract non-command sections
    if [[ -f "$output_file" ]]; then
        # Extract everything before "## Always Allowed Commands"
        sed '/^## Always Allowed Commands$/,$d' "$output_file" > "$temp_file"
    else
        # Create basic header if file doesn't exist
        cat > "$temp_file" << 'EOF'
# User Rules Update Policy

- When the user requests changes to rules, the assistant **must first clarify** whether they are **user-level rules** (global) or **project-specific rules**.
- If they are **user rules**, the assistant must apply the changes to the files inside `~/dotfiles/ai` (the global rules repository).
- If they are **project rules**, the assistant may create or edit the rule files within the current project repository.

# Command Execution Policy

EOF
    fi
    
    # Add generated command sections
    cat >> "$temp_file" << 'EOF'
## Always Allowed Commands

EOF
    
    # Generate always allowed commands list
    jq -r '.always_allowed[] | "- `\(.command)`"' "$COMMANDS_JSON" >> "$temp_file"
    
    cat >> "$temp_file" << 'EOF'

## Commands Requiring Explicit Confirmation

EOF
    
    # Generate confirmation required commands
    jq -r '.needs_confirmation[] | "- `\(.command)` - **\(.confirmation_message)**"' "$COMMANDS_JSON" >> "$temp_file"
    
    cat >> "$temp_file" << 'EOF'

## Forbidden Commands

EOF
    
    # Generate forbidden commands (if any)
    local forbidden_count=$(jq '.forbidden | length' "$COMMANDS_JSON")
    if [[ "$forbidden_count" -gt 0 ]]; then
        jq -r '.needs_confirmation[] | "- `\(.command)` - \(.reason)"' "$COMMANDS_JSON" >> "$temp_file"
    else
        echo "- None (all commands may be executed with appropriate confirmation)" >> "$temp_file"
    fi
    
    cat >> "$temp_file" << 'EOF'

> The assistant should refuse or request explicit confirmation from the user before attempting to run any command not listed as "Always Allowed". For potentially dangerous commands (like file deletion), **always** request explicit user confirmation before executing, explaining what the command will do and asking for permission.

EOF
    
    # Replace the original file
    mv "$temp_file" "$output_file"
    echo "✅ Generated Claude Code command rules: $output_file"
}

# Function to generate cursor-compatible format
generate_cursor_commands() {
    local output_file="$DOTFILES_DIR/ai/config/personal-global.mdc"
    local temp_file=$(mktemp)
    
    # Generate cursor format with metadata
    cat > "$temp_file" << 'EOF'
---
description: Personal global dev guidelines
globs:
alwaysApply: true
---

## _global

# User Rules Update Policy

- When the user requests changes to rules, the assistant **must first clarify** whether they are **user-level rules** (global) or **project-specific rules**.
- If they are **user rules**, the assistant must apply the changes to the files inside `~/dotfiles/ai` (the global rules repository).
- If they are **project rules**, the assistant may create or edit the rule files within the current project repository.

# Command Execution Policy

## Always Allowed Commands

EOF
    
    # Generate always allowed commands list
    jq -r '.always_allowed[] | "- `\(.command)`"' "$COMMANDS_JSON" >> "$temp_file"
    
    cat >> "$temp_file" << 'EOF'

## Commands Requiring Explicit Confirmation

EOF
    
    # Generate confirmation required commands
    jq -r '.needs_confirmation[] | "- `\(.command)` - **\(.confirmation_message)**"' "$COMMANDS_JSON" >> "$temp_file"
    
    cat >> "$temp_file" << 'EOF'

## Forbidden Commands

EOF
    
    # Generate forbidden commands (if any)
    local forbidden_count=$(jq '.forbidden | length' "$COMMANDS_JSON")
    if [[ "$forbidden_count" -gt 0 ]]; then
        jq -r '.needs_confirmation[] | "- `\(.command)` - \(.reason)"' "$COMMANDS_JSON" >> "$temp_file"
    else
        echo "- None (all commands may be executed with appropriate confirmation)" >> "$temp_file"
    fi
    
    cat >> "$temp_file" << 'EOF'

> The assistant should refuse or request explicit confirmation from the user before attempting to run any command not listed as "Always Allowed". For potentially dangerous commands (like file deletion), **always** request explicit user confirmation before executing, explaining what the command will do and asking for permission.


EOF
    
    # Read the current file and extract non-command sections (everything after command policy)
    if [[ -f "$output_file" ]]; then
        # Find where command policy ends and append the rest
        local start_line=$(grep -n "^> The assistant should refuse" "$output_file" | head -1 | cut -d: -f1)
        if [[ -n "$start_line" ]]; then
            # Skip the policy line and empty lines, then append the rest
            tail -n +$((start_line + 3)) "$output_file" >> "$temp_file"
        fi
    fi
    
    # Replace the original file
    mv "$temp_file" "$output_file"
    echo "✅ Generated Cursor command rules: $output_file"
}

# Main execution
TARGET="${1:-all}"

case "$TARGET" in
    "claude")
        generate_claude_commands
        ;;
    "cursor")
        generate_cursor_commands
        ;;
    "all")
        generate_claude_commands
        generate_cursor_commands
        ;;
    *)
        echo "Usage: $0 [claude|cursor|all]" >&2
        echo "  claude - Generate rules for Claude Code only" >&2
        echo "  cursor - Generate rules for Cursor only" >&2
        echo "  all    - Generate rules for both (default)" >&2
        exit 1
        ;;
esac

echo "🎉 Command rules generation completed!"