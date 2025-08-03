# AI-Enhanced Dotfiles System

A comprehensive development environment configuration system with integrated AI tooling for Claude Code, designed to streamline development workflows and provide consistent AI assistance across projects.

## Overview

This dotfiles repository provides:

- **AI Rule Management**: Global and project-specific rules for AI assistants
- **Claude Code Integration**: Seamless integration with Anthropic's Claude Code
- **Development Workflow Automation**: Git workflows, command policies, and task management
- **Agent System**: Specialized AI agents for different development tasks
- **Repository Cloning Automation**: Intelligent cloning with automatic rule synchronization

## Quick Start

### Initial Setup

1. **Clone and Setup**:
   ```bash
   git clone <this-repo> ~/dotfiles
   cd ~/dotfiles
   chmod +x ai/*.sh ai/ai-clone
   ```

2. **Add to PATH** (add to your shell profile):
   ```bash
   export PATH="$HOME/dotfiles/ai:$PATH"
   ```

3. **Sync Claude Rules**:
   ```bash
   ~/dotfiles/ai/sync-claude-commands.sh
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
- **Global Rules** ([`ai/rules/`](ai/rules/)): User-level development policies
- **Project Rules**: Repository-specific AI configuration
- **Command Policies**: Allowed/forbidden commands for AI assistants

### Agents
- **docs-audit** ([`ai/agents/docs-audit.md`](ai/agents/docs-audit.md)): Documentation audit specialist
- **route-walkthrough** ([`ai/agents/route-walkthrough.md`](ai/agents/route-walkthrough.md)): API flow explainer
- **general-explainer** ([`ai/agents/general-explainer.md`](ai/agents/general-explainer.md)): General purpose code explainer

### Sync Scripts
- **sync-user-rules.sh** ([`ai/sync-user-rules.sh`](ai/sync-user-rules.sh)): Syncs global rules to projects
- **sync-claude-commands.sh** ([`ai/sync-claude-commands.sh`](ai/sync-claude-commands.sh)): Updates Claude configuration
- **sync-claude-prompts.sh** ([`ai/sync-claude-prompts.sh`](ai/sync-claude-prompts.sh)): Syncs prompts to Claude
- **sync-claude-agents.sh** ([`ai/sync-claude-agents.sh`](ai/sync-claude-agents.sh)): Syncs agents to Claude

## File Structure

```
~/dotfiles/
├── ai/                              # AI tooling and configuration
│   ├── agents/                      # Specialized AI agents
│   │   ├── docs-audit.md           # Documentation specialist
│   │   ├── route-walkthrough.md    # API flow explainer
│   │   └── general-explainer.md    # Code explainer
│   ├── prompts/                     # Reusable prompts
│   │   └── task-manager.md         # Task management prompt
│   ├── rules/                       # Global AI rules
│   │   ├── _global.md              # Core command policies
│   │   ├── git_workflows.md        # Git workflow rules
│   │   └── task_lists.md           # Task management rules
│   ├── ai-clone*                    # Main cloning script
│   ├── sync-user-rules.sh*         # Rule synchronization
│   ├── sync-claude-commands.sh*    # Claude command sync
│   ├── sync-claude-prompts.sh*     # Prompt sync
│   ├── sync-claude-agents.sh*      # Agent sync
│   └── sync-or-create-project-rules.sh*  # Project rule setup
├── .claude/                         # Claude Code configuration
│   └── settings.local.json         # Claude permissions
└── .cursor/                         # Cursor IDE configuration
    └── rules/
        └── user-rules/              # Symlinked user rules
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

### 3. Agent-Based AI Assistance
- Specialized agents for different tasks
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