# Architecture Overview

This document describes the high-level architecture of the AI-enhanced dotfiles system and how its components interact.

## System Overview

The dotfiles system is built around three core concepts:

1. **Rule Management**: Centralized AI behavior configuration
2. **Sync Automation**: Automated synchronization between global and project rules
3. **Agent Specialization**: Task-specific AI agents with defined capabilities

## Component Architecture

### 1. Rule Management System

```
Global Rules (~/dotfiles/ai/rules/)
        ↓
    Compilation & Sync
        ↓
Project Rules (.cursor/rules/ + CLAUDE.md)
        ↓
    AI Assistant Behavior
```

#### Rule Types

**Global Rules** ([`ai/rules/`](../ai/rules/)):
- `_global.md` - Core command policies and user rule management
- `git_workflows.md` - Git operations, branching, and PR creation
- `task_lists.md` - Task management and development practices

**Project Rules**:
- `.cursor/rules/` - IDE-specific rule files
- `CLAUDE.md` - Claude Code configuration file
- Individual `.mdc` files with front-matter metadata

#### Rule Compilation Process

1. **Source**: Individual `.md` files in [`ai/rules/`](../ai/rules/)
2. **Compilation**: [`sync-user-rules.sh`](../ai/sync-user-rules.sh) combines rules
3. **Distribution**: Rules copied to both Cursor and Claude directories
4. **Application**: AI assistants read rules for behavior guidance

### 2. Sync Script Architecture

The sync system uses a hierarchical approach:

```
ai-clone (entry point)
    ├── sync-claude-prompts.sh (prompts)
    ├── sync-user-rules.sh (global rules)
    │   └── sync-claude-commands.sh (Claude config)
    └── sync-or-create-project-rules.sh (project setup)
```

#### Script Responsibilities

| Script | Purpose | Triggers |
|--------|---------|----------|
| [`ai-clone`](../ai/ai-clone) | Repository cloning + setup | Manual execution |
| [`sync-user-rules.sh`](../ai/sync-user-rules.sh) | Global rule distribution | Called by ai-clone |
| [`sync-claude-commands.sh`](../ai/sync-claude-commands.sh) | Claude configuration update | Called by sync-user-rules |
| [`sync-claude-prompts.sh`](../ai/sync-claude-prompts.sh) | Prompt synchronization | Called by ai-clone |
| [`sync-claude-agents.sh`](../ai/sync-claude-agents.sh) | Agent synchronization | Manual/called by others |
| [`sync-or-create-project-rules.sh`](../ai/sync-or-create-project-rules.sh) | Project rule setup | Called by ai-clone |

### 3. Agent System Architecture

Agents are specialized AI configurations with defined:

```yaml
---
name: agent-name
description: Agent purpose and capabilities
tools: "Tool1, Tool2, Tool3"
color: "color-code"
---
```

#### Agent Categories

| Agent | Specialization | Tools | Use Case |
|-------|---------------|-------|----------|
| [docs-audit](../ai/agents/docs-audit.md) | Documentation analysis | Read, Write, Glob, Grep, LS, Bash | Repository documentation audits |
| [route-walkthrough](../ai/agents/route-walkthrough.md) | API flow explanation | Read, Grep, Glob, Bash, Write, Web | API architecture documentation |
| [general-explainer](../ai/agents/general-explainer.md) | Code explanation | Read, Grep, Glob, Write | General code analysis |

## Data Flow

### 1. Repository Setup Flow

```
User runs: ai-clone git@host:user/repo.git
    ↓
Clone repository to target directory
    ↓
Sync Claude prompts (sync-claude-prompts.sh)
    ↓
Sync global rules (sync-user-rules.sh)
    ├── Compile rules into personal-global.mdc
    ├── Create individual .mdc files
    ├── Update ~/.claude/CLAUDE.md
    └── Call sync-claude-commands.sh
    ↓
Setup project rules (sync-or-create-project-rules.sh)
    ├── Create .cursor/rules/ if needed
    ├── Symlink or create CLAUDE.md
    └── Ensure consistency
    ↓
Repository ready for development
```

### 2. Rule Update Flow

```
User modifies ~/dotfiles/ai/rules/*.md
    ↓
Run sync-user-rules.sh (manual or via ai-clone)
    ↓
Rules compiled and distributed to:
    ├── ~/.claude/CLAUDE.md (unified file)
    ├── .cursor/rules/user-rules/*.mdc (individual files)
    └── Git exclusion patterns updated
```

### 3. Agent Invocation Flow

```
User requests specialized task
    ↓
Claude Code loads appropriate agent
    ↓
Agent configuration provides:
    ├── Specialized prompt
    ├── Tool restrictions
    └── Behavioral guidelines
    ↓
Agent executes with constrained capabilities
```

## Integration Points

### Claude Code Integration

The system integrates with Claude Code through:

1. **Configuration File**: `~/.claude/CLAUDE.md` contains all rules
2. **Agent Files**: `~/.claude/agents/` contains agent definitions
3. **Prompt Files**: `~/.claude/*.prompt` contains reusable prompts
4. **Permissions**: `.claude/settings.local.json` defines allowed operations

### Cursor IDE Integration

Integration with Cursor IDE via:

1. **Rule Files**: `.cursor/rules/user-rules/*.mdc` contains individual rules
2. **Front-matter**: Each rule has metadata for IDE processing
3. **Git Exclusion**: Rules directory excluded from version control

### Git Integration

Git integration includes:

1. **Exclusion Patterns**: Auto-added to `.git/info/exclude`
2. **Workflow Rules**: Standardized git operations
3. **Branch Naming**: Enforced naming conventions
4. **Commit Standards**: Conventional commit format

## Security Model

### Command Execution Policy

Rules define allowed/forbidden commands:

```markdown
## Always Allowed Commands
- pnpm install, git status, ls, pwd, etc.

## Forbidden Commands  
- rm (any variant)
```

### Permission System

Claude Code permissions in `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(rm:*)",                    # Specific rm allowance
      "Bash(~/dotfiles/ai/*:*)",      # Dotfiles script execution
      "WebFetch(domain:docs.anthropic.com)"
    ],
    "deny": []
  }
}
```

## Extensibility

### Adding New Rules

1. Create `.md` file in [`ai/rules/`](../ai/rules/)
2. Run [`sync-user-rules.sh`](../ai/sync-user-rules.sh)
3. Rules automatically distributed to all projects

### Adding New Agents

1. Create agent file in [`ai/agents/`](../ai/agents/)
2. Run [`sync-claude-agents.sh`](../ai/sync-claude-agents.sh)
3. Agent available in Claude Code

### Adding New Prompts

1. Create `.md` file in [`ai/prompts/`](../ai/prompts/)
2. Run [`sync-claude-prompts.sh`](../ai/sync-claude-prompts.sh)
3. Prompt available as `.prompt` file in Claude

## Error Handling

The system includes robust error handling:

1. **Script Validation**: All scripts check for required tools and directories
2. **Git Repository Validation**: Scripts verify git repository context
3. **Path Resolution**: Handles symlinks and relative paths
4. **Graceful Degradation**: Continues operation when optional components fail

## Performance Considerations

- **Lazy Loading**: Rules only compiled when needed
- **Incremental Updates**: Only changed files are processed
- **Symlink Usage**: Avoids file duplication where possible
- **Selective Sync**: Only relevant components synced per operation