# AI-Enhanced Dotfiles System

A comprehensive development environment configuration system with integrated AI tooling for Claude Code, designed to streamline development workflows and provide consistent AI assistance across projects.

## Overview

This dotfiles repository provides:

- **AI Rule Management**: Global and project-specific rules for AI assistants
- **Claude Code Integration**: Seamless integration with Anthropic's Claude Code
- **Development Workflow Automation**: Git workflows, command policies, and task management
- **Subagent System**: Specialized AI subagents for different development tasks
- **Repository Cloning Automation**: Intelligent cloning with automatic rule synchronization

## Quick Start

### Initial Setup

1. **Clone and Setup**:
   ```bash
   git clone <this-repo> ~/dotfiles
   cd ~/dotfiles
   chmod +x scripts/*.sh bin/ai-clone
   ```

2. **Add to PATH** (add to your shell profile):
   ```bash
   export PATH="$HOME/dotfiles/scripts:$HOME/dotfiles/bin:$PATH"
   ```

3. **Sync Claude Rules**:
   ```bash
   ~/dotfiles/scripts/sync-agents.sh
   ```

### Using the ai-clone Command

The main entry point for new projects:

```bash
# Clone a repository with automatic AI setup
ai-clone git@github.com:user/repo.git

# Clone to specific directory
ai-clone git@github.com:user/repo.git ~/my-projects
```

This automatically:
- Clones the repository
- Syncs global AI rules
- Sets up project-specific rules
- Configures Claude Code integration

## Core Components

### AI Rules System
- **Global Rules** ([`ai/rules/`](ai/rules/)): User-level development policies (stored as `AGENTS.md`)
- **Project Rules**: Repository-specific AI configuration
- **Command Policies**: Allowed/forbidden commands for AI assistants

### AI Components

#### Subagents ([`ai/subagents/`](ai/subagents/))
| Subagent | Purpose | Tools | Color |
|----------|---------|-------|-------|
| [docs-audit](ai/subagents/docs-audit.md) | Documentation audit specialist | Read, Write, Glob, Grep, LS, Bash | - |
| [general-explainer](ai/subagents/general-explainer.md) | Code explanation and walkthroughs | Read, Grep, Glob, WebFetch, Write | - |
| [code-reviewer](ai/subagents/code-reviewer.md) | Ruthless pre-check code reviewer | Read, Grep, Glob, Bash, Write | Yellow |
| [java-style-writer](ai/subagents/java-style-writer.md) | Java code style analysis | Read, Grep, Glob, Bash, Write | - |

#### Prompts ([`ai/prompts/`](ai/prompts/))
| Prompt | Purpose | Integration |
|--------|---------|-------------|
| [task-manager](ai/prompts/task-manager.md) | Project task list management | Creates `/task-lists/` markdown files |
| [jira](ai/prompts/jira.md) | Jira ticket management for Howcome | Uses `acli` CLI tool |
| [branch](ai/prompts/branch.md) | Git branch creation with Jira integration | Auto-fetches ticket details |
| [jira-ticket-creator](ai/prompts/jira-ticket-creator.md) | Automated Jira ticket creation | OH project integration |
| [smart-precheck](ai/prompts/smart-precheck.md) | Intelligent code review workflow | Integrates with precheck-reviewer |
| [java-style-compare](ai/prompts/java-style-compare.md) | Java style analysis and comparison | Generates style guides |
| [git-commit-push](ai/prompts/git-commit-push.md) | Git commit and push automation | Branch workflow integration |

#### Rules ([`ai/rules/`](ai/rules/))
| Rule | Purpose | Scope |
|------|---------|-------|
| [AGENTS](ai/rules/AGENTS.md) | Core command execution policies and user context | All projects |

*Note: Additional rule files are generated and stored in `.cursor/rules/user-rules/` including `_global.mdc` and `git_workflows.mdc`*

### Sync Scripts ([`scripts/`](scripts/))
- **sync-agents.sh**: Main orchestration script for all AI component syncing
- **sync-agents-commands.sh**: Creates unified AGENTS.md rule file for Claude
- **sync-claude-subagents.sh**: Syncs subagents to Claude Code
- **sync-claude-prompts.sh**: Syncs prompts to Claude Code
- **sync-cursor-rules.sh**: Cursor IDE rule synchronization
- **sync-or-create-project-rules.sh**: Project setup and rule synchronization

### Utilities ([`bin/`](bin/))
- **ai-clone**: Intelligent repository cloning with automatic AI setup
- **pr-list**: GitHub pull request listing and management

## File Structure

```
~/dotfiles/
├── ai/                              # AI tooling and configuration
│   ├── subagents/                   # Specialized AI subagents
│   │   ├── docs-audit.md           # Documentation audit specialist
│   │   ├── general-explainer.md    # Code explanation and walkthroughs
│   │   ├── code-reviewer.md        # Ruthless pre-check code reviewer
│   │   └── java-style-writer.md    # Java code style analysis
│   ├── prompts/                     # Reusable AI prompts
│   │   ├── task-manager.md         # Project task list management
│   │   ├── jira.md                 # Jira ticket management for Howcome
│   │   ├── branch.md               # Git branch creation with Jira integration
│   │   ├── jira-ticket-creator.md  # Automated Jira ticket creation
│   │   ├── smart-precheck.md       # Intelligent code review workflow
│   │   ├── java-style-compare.md   # Java style analysis and comparison
│   │   └── git-commit-push.md      # Git commit and push automation
│   ├── rules/                       # Global AI rules
│   │   └── AGENTS.md               # Core user context and command policies
│   ├── config/                      # AI configuration files
│   │   ├── personal-global.mdc     # Personal global configuration
│   │   ├── commands.json           # Command configurations
│   │   └── allowed-commands.json   # Allowed command list
│   └── guides/                      # Language-specific guides
│       ├── java/                   # Java best practices and patterns
│       └── javascript/             # JavaScript best practices
├── scripts/                         # Shell scripts for automation
│   ├── sync-agents.sh              # Main orchestration script
│   ├── sync-agents-commands.sh     # Rule compilation and sync
│   ├── sync-claude-prompts.sh      # Prompts synchronization
│   ├── sync-claude-subagents.sh    # Subagents synchronization
│   ├── sync-cursor-rules.sh        # Cursor IDE rule sync
│   ├── sync-or-create-project-rules.sh # Project setup and rule sync
│   └── other automation scripts...
├── bin/                             # Executable utilities
│   ├── ai-clone*                   # Intelligent repository cloning
│   └── pr-list*                    # GitHub pull request management
├── .cursor/rules/user-rules/        # Generated rule files for Cursor IDE
│   ├── _global.mdc                 # Global user rules
│   └── git_workflows.mdc           # Git workflow rules
├── .claude/                         # Claude Code configuration
│   ├── AGENTS.md                   # Combined rules (symlinked to CLAUDE.md)
│   ├── agents/                     # Subagent definitions
│   └── settings.local.json         # Claude permissions
└── docs/                            # Documentation
    ├── ARCHITECTURE.md             # System design and components
    ├── DEVELOPMENT.md              # Setup, testing, and contribution
    ├── AI_RULES.md                 # Complete rule documentation
    └── AGENTS.md                   # Available agents and capabilities
```

## Key Features

### 1. Intelligent Repository Cloning
- Automatic rule synchronization during clone
- Smart directory structure creation
- Project-specific rule configuration

### 2. Global Rule Management
- Centralized AI behavior policies
- Command execution controls
- Git workflow standardization

### 3. Subagent-Based AI Assistance
- Specialized subagents for different tasks
- Color-coded organization
- Tool-specific capabilities

### 4. Development Workflow Integration
- Standardized git workflows
- Automated task management
- Build and test integration

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md) - System design and components
- [Development Guide](docs/DEVELOPMENT.md) - Setup, testing, and contribution
- [AI Rules Reference](docs/AI_RULES.md) - Complete rule documentation
- [Agent Reference](docs/AGENTS.md) - Available agents and their capabilities

## Requirements

- Bash shell environment
- Git
- Claude Code (for AI integration)
- Unix-like operating system (macOS, Linux)

## Support

This is a personal dotfiles configuration. Key design decisions:

- **Security**: Command execution policies prevent destructive operations
- **Consistency**: Global rules ensure consistent AI behavior across projects
- **Automation**: Minimal manual setup required for new projects
- **Extensibility**: Easy to add new rules, agents, and prompts

---

**Note**: This system is designed for use with Claude Code and follows Anthropic's recommended practices for AI-assisted development.