# Development Guide

This guide covers development setup, testing, and contribution guidelines for the AI-enhanced dotfiles system.

## Development Setup

### Prerequisites

- **Operating System**: macOS or Linux (Unix-like environment)
- **Shell**: Bash 4.0+ (most systems have this)
- **Git**: Version 2.0+
- **Claude Code**: For AI integration testing
- **Cursor IDE**: (Optional) For IDE rule testing

### Initial Development Setup

1. **Clone the Repository**:

   ```bash
   git clone <repository-url> ~/dotfiles-dev
   cd ~/dotfiles-dev
   ```

2. **Make Scripts Executable**:

   ```bash
   chmod +x scripts/*.sh bin/ai-clone
   ```

3. **Set Up Development Environment**:

   ```bash
   # Add to your shell profile for testing
   export PATH="$HOME/dotfiles-dev/scripts:$HOME/dotfiles-dev/bin:$PATH"
   ```

4. **Test Basic Functionality**:
   ```bash
   # Test rule compilation
   ./scripts/sync-claude-commands.sh

   # Test agent sync
   ./scripts/sync-claude-agents.sh

   # Test main orchestration
   ./scripts/sync-agents.sh
   ```

## Project Structure

```
~/dotfiles/
├── ai/                              # AI configuration and data
│   ├── agents/                      # Agent definitions
│   ├── prompts/                     # Reusable prompts
│   ├── rules/                       # Global rules
│   └── config/                      # AI tool configurations
├── scripts/                         # Executable synchronization scripts
│   └── sync-*.sh*                   # All sync scripts
├── bin/                             # Utility binaries
│   └── ai-clone*                    # Main entry script
├── docs/                           # Documentation
├── .claude/                        # Claude Code config
└── .cursor/                        # Cursor IDE config
```

## Testing

### Manual Testing

#### 1. Rule System Testing

```bash
# Test rule compilation
cd ~/dotfiles
./scripts/sync-claude-commands.sh

# Verify output
cat ~/.claude/CLAUDE.md

# Test in project context
mkdir /tmp/test-project
cd /tmp/test-project
git init
~/dotfiles/scripts/sync-agents.sh

# Check rule files created
ls -la .cursor/rules/user-rules/
```

#### 2. Repository Cloning Testing

```bash
# Test with a small public repository
ai-clone git@github.com:user/small-repo.git /tmp/test-clone

# Verify setup completed
cd /tmp/test-clone/small-repo
ls -la .cursor/rules/
cat CLAUDE.md
```

#### 3. Agent Testing

```bash
# Test agent sync
./scripts/sync-claude-agents.sh

# Verify agents available
ls -la ~/.claude/agents/
```

### Validation Scripts

#### Script Syntax Validation

```bash
# Check all shell scripts for syntax errors
for script in ai/*.sh ai/ai-clone; do
    echo "Checking $script..."
    bash -n "$script" && echo "✅ $script syntax OK" || echo "❌ $script has syntax errors"
done
```

#### Rule Validation

```bash
# Check rule files are valid markdown
for rule in ai/rules/*.md; do
    echo "Checking $rule..."
    # Add markdown linting if needed
done
```

## Code Guidelines

### Shell Script Standards

1. **Use `set -euo pipefail`** for strict error handling
2. **Quote all variables** to prevent word splitting
3. **Use meaningful variable names** in ALL_CAPS for globals
4. **Add descriptive comments** for complex logic
5. **Validate inputs** before processing

#### Example Script Structure

```bash
#!/usr/bin/env bash
# --------------------------------------------------------------
# script-name.sh
#
# Description of what the script does
#
# Usage: script-name.sh [arguments]
# --------------------------------------------------------------

set -euo pipefail

# Global variables
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
DEFAULT_VALUE="some-default"

# Function definitions
validate_requirements() {
    if ! command -v git &> /dev/null; then
        echo "Error: git is required" >&2
        exit 1
    fi
}

# Main execution
main() {
    validate_requirements
    # ... rest of script logic
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Markdown Standards

1. **Use consistent heading levels** (# for main, ## for sections)
2. **Include code examples** in appropriate language blocks
3. **Link to source files** using relative paths
4. **Keep line length reasonable** (80-100 characters)

### Rule File Standards

1. **Clear section headers** for different rule categories
2. **Specific, actionable rules** rather than vague guidelines
3. **Examples** where helpful
4. **Consistent formatting** across all rule files

## Adding New Components

### Adding a New Global Rule

1. **Create Rule File**:

   ```bash
   # Create new rule file
   cat > ai/rules/new_feature.md << 'EOF'
   # New Feature Rules

   ## Rule Category

   - Specific rule 1
   - Specific rule 2

   EOF
   ```

2. **Test Rule Integration**:

   ```bash
   # Test compilation
   ./scripts/sync-claude-commands.sh

   # Verify in output
   grep -A 5 "new_feature" ~/.claude/CLAUDE.md
   ```

3. **Test in Project Context**:
   ```bash
   cd /tmp/test-project
   ~/dotfiles/scripts/sync-agents.sh
   ls .cursor/rules/user-rules/new_feature.mdc
   ```

### Adding a New Agent

1. **Create Agent File**:

   ```bash
   cat > ai/agents/new-agent.md << 'EOF'
   ---
   name: new-agent
   description: Description of what this agent does
   tools: "Read, Write, Grep"
   color: "blue"
   ---

   # Agent Instructions

   You are a specialized agent that...
   EOF
   ```

2. **Sync and Test**:
   ```bash
   ./scripts/sync-claude-agents.sh
   ls ~/.claude/agents/new-agent.md
   ```

### Adding a New Sync Script

1. **Create Script**:

   ```bash
   cat > scripts/sync-new-feature.sh << 'EOF'
   #!/usr/bin/env bash
   set -euo pipefail

   # Script implementation
   EOF
   chmod +x scripts/sync-new-feature.sh
   ```

2. **Integrate with Existing Scripts**:
   - Add call to [`ai-clone`](../bin/ai-clone) if needed during setup
   - Add call to [`sync-agents.sh`](../scripts/sync-agents.sh) if related to main workflow

## Debugging

### Common Issues

#### 1. Script Execution Failures

```bash
# Check script permissions
ls -la ai/*.sh

# Make executable if needed
chmod +x ai/sync-script-name.sh

# Test script directly
bash -x ai/sync-script-name.sh
```

#### 2. Rule Compilation Issues

```bash
# Check rule directory exists
ls -la ai/rules/

# Check for markdown syntax issues
for rule in ai/rules/*.md; do
    echo "=== $rule ==="
    head -10 "$rule"
done
```

#### 3. Path Resolution Issues

```bash
# Check current directory context
pwd
git rev-parse --show-toplevel 2>/dev/null || echo "Not in git repo"

# Check symlink resolution
ls -la ~/.claude/
ls -la .cursor/rules/user-rules/
```

### Debug Mode

Enable debug output in scripts:

```bash
# Run with debug output
bash -x ai/sync-agents.sh

# Or set in environment
export BASH_DEBUG=1
./ai/sync-agents.sh
```

### Log Analysis

Scripts output status messages:

```bash
# Successful sync shows:
✔︎ Built ~/dotfiles/ai/personal-global.mdc
✔︎ Generated individual .mdc rule files
✔︎ Updated symlinks and index at ~/.claude/CLAUDE.md
✅ User rules synced and linked

# Check for error patterns
./ai/sync-agents.sh 2>&1 | grep -E "(Error|❌|Failed)"
```

## Performance Testing

### Rule Compilation Performance

```bash
# Time rule compilation
time ./scripts/sync-claude-commands.sh

# Check output file sizes
ls -lh ~/.claude/CLAUDE.md
ls -lh ai/personal-global.mdc
```

### Large Repository Testing

Test with repositories containing many files:

```bash
# Clone large repository
ai-clone git@github.com:user/large-repo.git /tmp/large-test

# Time the setup process
time ai-clone git@github.com:user/large-repo.git /tmp/large-test-2
```

## Contributing

### Pull Request Process

1. **Create Feature Branch**:

   ```bash
   git checkout -b feature/new-enhancement
   ```

2. **Make Changes** following code guidelines

3. **Test Changes**:

   ```bash
   # Test all affected scripts
   ./scripts/sync-claude-commands.sh
   ./scripts/sync-agents.sh

   # Test in clean environment
   ai-clone git@github.com:test/repo.git /tmp/test-pr
   ```

4. **Update Documentation** if needed

5. **Submit Pull Request** with:
   - Clear description of changes
   - Test results
   - Any breaking changes noted

### Code Review Checklist

- [ ] Scripts have proper error handling (`set -euo pipefail`)
- [ ] Variables are properly quoted
- [ ] Functions have descriptive comments
- [ ] Changes are tested in clean environment
- [ ] Documentation is updated if needed
- [ ] No hardcoded paths (use variables)
- [ ] Error messages are clear and actionable

## Troubleshooting

### Environment Issues

1. **Check Shell**: Ensure using bash (not zsh/fish for scripts)
2. **Check PATH**: Verify dotfiles scripts are in PATH
3. **Check Permissions**: Ensure scripts are executable
4. **Check Git**: Verify git is properly configured

### Integration Issues

1. **Claude Code**: Check `.claude/` directory permissions
2. **Cursor IDE**: Verify `.cursor/rules/` structure
3. **Symlinks**: Check symlink targets are correct

### Recovery

If the system gets into a bad state:

```bash
# Clean Claude directory
rm -rf ~/.claude/CLAUDE.md ~/.claude/agents/

# Re-sync everything
cd ~/dotfiles
./scripts/sync-claude-commands.sh
./scripts/sync-claude-agents.sh

# Re-sync in project
cd /path/to/project
~/dotfiles/scripts/sync-agents.sh
```
