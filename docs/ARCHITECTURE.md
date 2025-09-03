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
- `git_workflows.md` - Git operations, branching, and PR creation standards
- `task_lists.md` - Task management and development best practices

**Project Rules**:
- `.cursor/rules/` - IDE-specific rule files
- `CLAUDE.md` - Claude Code configuration file
- Individual `.mdc` files with front-matter metadata

#### Rule Compilation Process

1. **Source**: Individual `.md` files in [`ai/rules/`](../ai/rules/)
2. **Compilation**: [`sync-claude-commands.sh`](../scripts/sync-claude-commands.sh) combines rules
3. **Distribution**: Rules copied to both Cursor and Claude directories
4. **Application**: AI assistants read rules for behavior guidance

### 2. Sync Script Architecture

The sync system uses a hierarchical approach:

```
ai-clone (entry point)
    └── sync-or-create-project-rules.sh (main project setup)
        ├── sync-claude-prompts.sh (prompts)
        ├── sync-claude-agents.sh (subagents)
        ├── sync-claude-commands.sh (rules)
        └── setup-cursor-rules.sh (Cursor IDE rules)
```

#### Script Responsibilities

| Script | Purpose | Triggers |
|--------|---------|----------|
| [`ai-clone`](../bin/ai-clone) | Repository cloning + setup | Manual execution |
| [`sync-or-create-project-rules.sh`](../scripts/sync-or-create-project-rules.sh) | Main project setup and rule sync | Called by ai-clone |
| [`sync-claude-commands.sh`](../scripts/sync-claude-commands.sh) | Claude Code rule compilation | Called by sync-or-create |
| [`sync-claude-prompts.sh`](../scripts/sync-claude-prompts.sh) | Claude Code prompt synchronization | Called by sync-or-create |
| [`sync-claude-agents.sh`](../scripts/sync-claude-agents.sh) | Claude Code subagent synchronization | Called by sync-or-create |
| [`setup-cursor-rules.sh`](../scripts/setup-cursor-rules.sh) | Cursor IDE rule synchronization | Called by sync-or-create |

### 3. Subagent System Architecture

Subagents are specialized AI configurations with defined front-matter:

```yaml
---
name: subagent-name
description: Subagent purpose and capabilities
tools: Read, Write, Glob, Grep, Bash
color: color-code
arguments: [optional-args]
---
```

#### Subagent Categories

| Subagent | Specialization | Tools | Use Case |
|----------|---------------|-------|----------|
| [docs-audit](../ai/subagents/docs-audit.md) | Documentation audit specialist | Read, Write, Glob, Grep, LS, Bash | Repository documentation audits |
| [general-explainer](../ai/subagents/general-explainer.md) | Code explanation and walkthroughs | Read, Grep, Glob, WebFetch, Write | General code analysis and explanation |
| [code-reviewer](../ai/subagents/code-reviewer.md) | Ruthless pre-check code reviewer | Read, Grep, Glob, Bash, Write | Code quality and standards review |
| [java-style-writer](../ai/subagents/java-style-writer.md) | Java code style analysis | Read, Grep, Glob, Bash, Write | Java-specific style guide generation |

#### Prompt System

| Prompt | Purpose | Integration |
|--------|---------|-------------|
| [task-manager](../ai/prompts/task-manager.md) | Project task list management | Creates `/task-lists/` markdown files |
| [jira](../ai/prompts/jira.md) | Jira ticket management for Howcome | Uses `acli` CLI tool with OH project |
| [branch](../ai/prompts/branch.md) | Git branch creation with Jira integration | Auto-fetches ticket details via `acli` |
| [smart-precheck](../ai/prompts/smart-precheck.md) | Intelligent code review workflow | Integrates with precheck-reviewer subagent |
| [java-style-compare](../ai/prompts/java-style-compare.md) | Java style analysis and comparison | Generates project-specific style guides |

## Data Flow

### 1. Repository Setup Flow

```
User runs: ai-clone git@host:user/repo.git
    ↓
Clone repository to target directory
    ↓
Run sync-or-create-project-rules.sh
    ├── Sync Claude prompts (sync-claude-prompts.sh)
    ├── Sync Claude subagents (sync-claude-agents.sh)
    ├── Sync global rules (sync-claude-commands.sh)
    │   ├── Compile rules into ~/.claude/CLAUDE.md
    │   └── Update Claude configuration
    ├── Setup Cursor rules (setup-cursor-rules.sh)
    ├── Create .cursor/rules/ if needed
    ├── Symlink or create CLAUDE.md
    └── Ensure project-specific consistency
    ↓
Repository ready for development with full AI integration
```

### 2. Rule Update Flow

```
User modifies ~/dotfiles/ai/rules/*.md
    ↓
Run sync-claude-commands.sh (manual or via sync-or-create-project-rules)
    ↓
Rules compiled and distributed to:
    ├── ~/.claude/CLAUDE.md (unified file with combined rules)
    ├── .cursor/rules/user-rules/*.mdc (individual files with front-matter)
    └── Git exclusion patterns updated (.git/info/exclude)
```

### 3. Subagent Invocation Flow

```
User requests specialized task (e.g., @agent-docs-audit)
    ↓
Claude Code loads appropriate subagent configuration
    ↓
Subagent configuration provides:
    ├── Specialized system prompt
    ├── Tool access restrictions
    ├── Color coding for organization
    └── Behavioral guidelines and workflows
    ↓
Subagent executes with defined capabilities and constraints
    ↓
Results delivered back to user with specialized expertise
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
2. Run [`sync-claude-commands.sh`](../scripts/sync-claude-commands.sh)
3. Rules automatically distributed to all projects

### Adding New Agents

1. Create agent file in [`ai/agents/`](../ai/agents/)
2. Run [`sync-claude-agents.sh`](../scripts/sync-claude-agents.sh)
3. Agent available in Claude Code

### Adding New Prompts

1. Create `.md` file in [`ai/prompts/`](../ai/prompts/)
2. Run [`sync-claude-prompts.sh`](../scripts/sync-claude-prompts.sh)
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