# Architecture Overview

Core design of the AI-enhanced dotfiles system and how components interact.

## System Overview

The dotfiles system is built around three core concepts:

1. **Rule Management**: Centralized AI behavior configuration
2. **Sync Automation**: Automated synchronization between global and project rules  
3. **Subagent Specialization**: Task-specific AI subagents with defined capabilities

## Component Architecture

### Rule Management System

```
Global Rules (~/dotfiles/ai/rules/AGENTS.md)
        ↓
    Compilation & Sync
        ↓
Project Rules (.cursor/rules/user-rules/ + ~/.claude/AGENTS.md)
        ↓
    AI Assistant Behavior
```

**Rule Types:**
- **Global Rules**: `ai/rules/AGENTS.md` - Core command policies, user context, development policies
- **Generated Project Rules**: `.cursor/rules/user-rules/*.mdc` + `~/.claude/AGENTS.md`

### Sync Script Architecture

```
ai-clone (entry point)
    └── sync-agents.sh (main orchestration)
        ├── sync-claude-prompts.sh
        ├── sync-claude-subagents.sh  
        ├── sync-agents-commands.sh
        └── sync-cursor-rules.sh
```

### Subagent System

Specialized AI configurations with defined capabilities:

| Subagent | Purpose | Tools |
|----------|---------|-------|
| docs-audit | Documentation audit specialist | Read, Write, Glob, Grep, LS, Bash |
| general-explainer | Code explanation and walkthroughs | Read, Grep, Glob, WebFetch, Write |
| code-reviewer | Ruthless pre-check code reviewer | Read, Grep, Glob, Bash, Write |
| java-style-writer | Java code style analysis | Read, Grep, Glob, Bash, Write |

## Data Flow

### Repository Setup Flow

```
User: ai-clone git@host:user/repo.git
    ↓
Clone repository to target directory
    ↓
Run sync-agents.sh (main orchestration)
    ├── Sync Claude prompts
    ├── Sync Claude subagents
    ├── Sync global rules → ~/.claude/AGENTS.md
    └── Sync Cursor rules → .cursor/rules/user-rules/
    ↓
Repository ready with full AI integration
```

### Rule Update Flow

```
User modifies ~/dotfiles/ai/rules/AGENTS.md
    ↓
Run sync-agents-commands.sh
    ↓ 
Rules distributed to:
    ├── ~/.claude/AGENTS.md (unified file)
    └── .cursor/rules/user-rules/*.mdc (individual files)
```

## Integration Points

### Claude Code Integration
- **Configuration**: `~/.claude/AGENTS.md` contains all rules
- **Subagents**: `~/.claude/agents/` contains subagent definitions
- **Prompts**: `~/.claude/*.prompt` contains reusable prompts

### Cursor IDE Integration  
- **Rule Files**: `.cursor/rules/user-rules/*.mdc` contains individual rules
- **Metadata**: Each rule has front-matter for IDE processing

### Git Integration
- **Exclusion Patterns**: Auto-added to `.git/info/exclude`
- **Workflow Rules**: Standardized git operations
- **Branch Naming**: Enforced naming conventions

## File Structure

```
~/dotfiles/
├── ai/
│   ├── subagents/          # Specialized AI subagents
│   ├── prompts/            # Reusable AI prompts  
│   ├── rules/              # Global AI rules
│   └── config/             # AI tool configurations
├── scripts/                # Sync automation scripts
├── bin/                    # Utility binaries (ai-clone, pr-list)
├── docs/                   # Documentation (this file)
├── .claude/                # Claude Code configuration
└── .cursor/                # Cursor IDE configuration
```

## Security Model

**Command Execution Policy**: Rules define allowed operations with explicit confirmation for potentially dangerous commands.

**Permission System**: Claude Code permissions in `.claude/settings.local.json` control tool access.

## Extensibility

- **New Rules**: Edit `ai/rules/AGENTS.md` → run `sync-agents-commands.sh`
- **New Subagents**: Create file in `ai/subagents/` → run `sync-claude-subagents.sh`  
- **New Prompts**: Create `.md` file in `ai/prompts/` → run `sync-claude-prompts.sh`