# Command Reference

Essential commands and file locations for the AI-enhanced dotfiles system.

## Core Commands

### ai-clone
Main entry point for new projects with automatic AI setup:

```bash
# Clone with auto-setup
ai-clone git@github.com:user/repo.git

# Clone to specific directory  
ai-clone git@github.com:user/repo.git ~/projects
```

### sync-agents.sh
Main orchestration script for all AI component synchronization:

```bash
# Sync all AI components
~/dotfiles/scripts/sync-agents.sh
```

## Sync Scripts

All located in `~/dotfiles/scripts/`:

| Script | Purpose |
|--------|---------|
| `sync-agents.sh` | Main orchestration - syncs all components |
| `sync-agents-commands.sh` | Compile and distribute AI rules |
| `sync-claude-subagents.sh` | Sync subagents to Claude Code |
| `sync-claude-prompts.sh` | Sync prompts to Claude Code |
| `sync-cursor-rules.sh` | Sync rules to Cursor IDE |
| `sync-or-create-project-rules.sh` | Project setup and rule consistency |

## File Locations

### Source Files
| Location | Contents |
|----------|----------|
| `~/dotfiles/ai/rules/AGENTS.md` | Global rules source |
| `~/dotfiles/ai/subagents/*.md` | Subagent definitions |
| `~/dotfiles/ai/prompts/*.md` | Reusable prompts |

### Generated Files
| Location | Contents |
|----------|----------|
| `~/.claude/AGENTS.md` | Compiled rules for Claude Code |
| `~/.claude/agents/*.md` | Subagent files for Claude Code |
| `~/.claude/*.prompt` | Prompt files for Claude Code |
| `.cursor/rules/user-rules/*.mdc` | Rules for Cursor IDE |
| `CLAUDE.md` | Project-level Claude config |

## Quick Status Checks

```bash
# Check Claude integration
ls -la ~/.claude/AGENTS.md ~/.claude/agents/

# Check project rules
ls -la .cursor/rules/user-rules/

# Check if in git repo
git status

# Verify scripts are executable
ls -la ~/dotfiles/scripts/*.sh ~/dotfiles/bin/*
```

## Quick Fixes

**Command not found:**
```bash
export PATH="$HOME/dotfiles/scripts:$HOME/dotfiles/bin:$PATH"
```

**Missing files:**
```bash
~/dotfiles/scripts/sync-agents.sh
```

**Permission denied:**
```bash
chmod +x ~/dotfiles/scripts/*.sh ~/dotfiles/bin/*
```