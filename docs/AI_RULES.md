# AI Rules Reference

This document provides a comprehensive reference for all AI rules and policies in the dotfiles system.

## Overview

The AI rules system provides consistent behavior across all AI assistants by defining:

- **Command execution policies** (allowed/forbidden operations)
- **Development workflow standards** (git, testing, deployment)
- **Task management guidelines** (how to break down and track work)
- **User vs project rule distinctions** (global vs local configuration)

## Rule Categories

### 1. Global Rules ([`_global.md`](../ai/rules/_global.md))

Core policies that apply system-wide across all projects.

#### User Rules Update Policy

```markdown
- When the user requests changes to rules, the assistant **must first clarify** 
  whether they are **user-level rules** (global) or **project-specific rules**.
- If they are **user rules**, the assistant must apply the changes to the files 
  inside `~/dotfiles/ai` (the global rules repository).
- If they are **project rules**, the assistant may create or edit the rule files 
  within the current project repository.
```

**Implementation**: Ensures rules are updated in the correct location and scope.

#### Command Execution Policy

**Always Allowed Commands**:
- `pnpm install`, `pnpm list`, `npm list`
- `ls`, `pwd`, `cat`, `grep`
- `git status`, `git log`, `git diff`, `git checkout`, `git pull origin master`
- `pnpm audit`, `pnpm test`, `pnpm test:ci`, `pnpm build`

**Forbidden Commands**:
- `rm` (and any variant such as `rm -rf`, `rimraf`, etc.)

**Enforcement**: The assistant should refuse or request explicit confirmation before attempting to run any command not listed as "Always Allowed" and must **never** run forbidden commands.

### 2. Git Workflow Rules ([`git_workflows.md`](../ai/rules/git_workflows.md))

Comprehensive git workflow standardization covering branching, commits, and PRs.

#### Branch Creation Workflow

**Required Sequence**:
1. `git checkout master`
2. `git pull origin master`
3. `git checkout -b <branch-name>`

**Purpose**: Ensures branching from latest codebase and prevents merge conflicts.

#### Branch Naming Convention

**Format**: `<jira-ticket>/descriptive-name`

**Examples**:
- `hous-1711/cursor-add-real-data`
- `feature/hous-1518-add-user-authentication`
- `bugfix/hous-1519-fix-form-validation`

**Requirements**:
- Always use lowercase
- Include Jira ticket number
- Use descriptive names

#### Commit Best Practices

**File Selection Rules**:
- **NEVER use `git commit .`** - can commit unintended changes
- **NEVER use `git add .`**
- Always commit only specific files that were recently changed
- Always ask before committing files - confirm with user what should be committed
- Use `git add <specific-file>` for each file intended for commit

**Commit Message Format**:
Follow conventional commits with these prefixes:
- `build:`, `chore:`, `ci:`, `docs:`, `feat:`, `fix:`, `perf:`, `refactor:`, `revert:`, `style:`, `test:`

**Jira Integration**:
- Include Jira ticket number: `[HOUS-1234] Brief description`
- Example: `[HOUS-1518] Add user authentication middleware`

#### Build Validation

**Required Actions**:
- Always run `pnpm build` if `package.json` has been modified
- Ensures dependency changes don't break the build
- Fix build issues before committing

#### PR Creation Rules

**Title Format**:
- **MUST** include Jira ticket number in brackets at beginning
- **MUST** capitalize Jira ticket number
- Format: `[HOUS-1234] Brief description of changes`

**Description Requirements**:
- **MUST** include link to Jira ticket: `Jira: https://spotify.atlassian.net/browse/HOUS-1234`
- Should include brief summary of changes and testing notes

**Creation Workflow**:
1. **Push branch first**: `git push origin <branch-name>`
2. **Then create PR**: Use `gh pr create` command
3. **Return PR URL**: Always return the URL prominently in response

### 3. Task Management Rules ([`task_lists.md`](../ai/rules/task_lists.md))

Guidelines for task management in software development projects.

#### Tool Selection

**TodoWrite Tool Usage**:
- Complex tasks requiring 3+ steps
- Real-time progress tracking during active development
- Breaking down user requests into actionable items
- Immediate task management within a session

**Task-Manager Prompt Usage**:
- Project-wide feature documentation
- Long-term progress tracking across multiple sessions
- Implementation planning and architecture documentation
- Creating structured project documentation in `/task-lists/` folder

#### Development Best Practices

**Change Management**:
- Always recommend minimal changes needed to meet request expectations
- Always re-run existing tests after any source code change
- If modifying source files (`.py`, `.js`, `.ts`), check for tests and run them
- Tests might be in folders called `test` or files containing `test` in their name

## Rule Application

### Scope Hierarchy

```
Global Rules (~/dotfiles/ai/rules/)
    ↓ (applied to all projects)
Project Rules (.cursor/rules/, CLAUDE.md)
    ↓ (applied to specific project)
Session Rules (temporary overrides)
```

### Rule Compilation Process

1. **Source Files**: Individual `.md` files in [`ai/rules/`](../ai/rules/)
2. **Compilation**: [`sync-claude-commands.sh`](../scripts/sync-claude-commands.sh) combines all rules
3. **Output**: Unified `~/.claude/CLAUDE.md` file
4. **Distribution**: Individual `.mdc` files in project `.cursor/rules/user-rules/`

### Rule Updates

**Global Rule Changes**:
```bash
# Edit rule file
vim ~/dotfiles/ai/rules/rule_name.md

# Sync to all systems
~/dotfiles/scripts/sync-claude-commands.sh

# Apply to current project via sync-agents
~/dotfiles/scripts/sync-agents.sh
```

**Project Rule Changes**:
- Edit `.cursor/rules/*.md` files directly
- Or modify `CLAUDE.md` in project root
- Changes apply only to current project

## Enforcement Mechanisms

### Claude Code Integration

Rules are enforced through:

1. **Configuration File**: `~/.claude/CLAUDE.md` contains all rules
2. **Front-matter Metadata**: Rules have `alwaysApply: true` directive
3. **Permission System**: `.claude/settings.local.json` defines allowed operations

### Cursor IDE Integration

Rules are applied via:

1. **Rule Files**: `.cursor/rules/user-rules/*.mdc` files
2. **Metadata**: Each rule has front-matter for IDE processing
3. **Auto-application**: `alwaysApply: true` ensures consistent enforcement

### Git Integration

Rules are enforced through:

1. **Exclusion Patterns**: Rules directories automatically excluded from git
2. **Workflow Validation**: Git operations checked against workflow rules
3. **Commit Standards**: Commit messages validated against conventional format

## Rule Customization

### Adding New Rules

1. **Create Rule File**:
   ```bash
   cat > ~/dotfiles/ai/rules/new_rule.md << 'EOF'
   # New Rule Category
   
   ## Specific Rule Section
   
   - Rule 1 description
   - Rule 2 description
   
   EOF
   ```

2. **Sync Rules**:
   ```bash
   ~/dotfiles/scripts/sync-claude-commands.sh
   ```

3. **Apply to Projects**:
   ```bash
   cd /path/to/project
   ~/dotfiles/scripts/sync-agents.sh
   ```

### Modifying Existing Rules

1. **Edit Source File**:
   ```bash
   vim ~/dotfiles/ai/rules/existing_rule.md
   ```

2. **Test Changes**:
   ```bash
   # Check compilation
   ~/dotfiles/scripts/sync-claude-commands.sh
   
   # Verify output
   grep -A 10 "existing_rule" ~/.claude/CLAUDE.md
   ```

3. **Deploy Changes**:
   ```bash
   # Apply to all future projects (automatic)
   # Apply to current project
   ~/dotfiles/scripts/sync-agents.sh
   ```

### Rule Precedence

When rules conflict:

1. **Project-specific rules** override global rules
2. **Later rules** in same file override earlier rules
3. **Explicit commands** override rule defaults
4. **User confirmation** can override rule restrictions

## Best Practices

### Rule Writing

1. **Be Specific**: Clear, actionable rules rather than vague guidelines
2. **Provide Examples**: Show good and bad examples where helpful
3. **Explain Why**: Include rationale for important rules
4. **Keep Updated**: Review and update rules as practices evolve

### Rule Organization

1. **Logical Grouping**: Group related rules in same file
2. **Clear Headers**: Use consistent section headers
3. **Cross-references**: Link to related rules or documentation
4. **Version Control**: Use git to track rule changes

### Testing Rules

1. **Local Testing**: Test rule changes in development environment
2. **Project Testing**: Apply rules to test project and verify behavior
3. **AI Testing**: Interact with AI to ensure rules are followed
4. **Edge Cases**: Test rule behavior in unusual situations

## Troubleshooting

### Rules Not Applied

**Check Compilation**:
```bash
# Verify rules compiled
ls -la ~/.claude/CLAUDE.md
grep "rule-name" ~/.claude/CLAUDE.md
```

**Check Distribution**:
```bash
# Verify project rules
ls -la .cursor/rules/user-rules/
cat CLAUDE.md
```

**Re-sync Rules**:
```bash
# Force re-sync
~/dotfiles/scripts/sync-claude-commands.sh
cd /path/to/project && ~/dotfiles/scripts/sync-agents.sh
```

### Rule Conflicts

1. **Identify Conflict**: Determine which rules are conflicting
2. **Check Precedence**: Understand rule hierarchy and precedence
3. **Resolve Conflict**: Modify rules to eliminate ambiguity
4. **Test Resolution**: Verify conflict is resolved

### Performance Issues

**Large Rule Files**:
- Split large rules into multiple files
- Use consistent formatting to aid parsing
- Remove redundant or obsolete rules

**Sync Performance**:
- Rule compilation is fast but can be optimized
- Consider rule caching for large projects
- Monitor sync script execution time

## Reference

### File Locations

| Component | Location | Purpose |
|-----------|----------|---------|
| Global Rules | `~/dotfiles/ai/rules/*.md` | Source rule files |
| Compiled Rules | `~/.claude/CLAUDE.md` | Unified rule file for Claude |
| Project Rules | `.cursor/rules/user-rules/*.mdc` | Individual rule files for Cursor |
| Sync Scripts | `~/dotfiles/ai/sync-*.sh` | Rule distribution scripts |

### Related Documentation

- [Architecture Overview](ARCHITECTURE.md) - System design
- [Development Guide](DEVELOPMENT.md) - Setup and testing
- [Main README](../README.md) - Quick start guide