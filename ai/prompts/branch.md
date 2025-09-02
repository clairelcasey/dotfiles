# Git Branch Creation Workflow

Automates branch creation from latest master with Jira integration.

## Core Workflow

```bash
git checkout master && git pull origin master && git checkout -b <branch-name>
```

## Branch Name Processing

**Jira ticket only** (`HOUS-1234`):
- Fetch ticket details: `acli jira workitem view HOUS-1234 --json`
- Auto-generate from summary: `hous-1234/summary-in-kebab-case`

**Jira with description** (`HOUS-1234 custom desc`):
- Use provided description: `hous-1234/custom-desc`

**Custom names**: Convert to lowercase, replace spaces with hyphens

## Error Handling

- **Uncommitted changes**: `git stash` → create branch → `git stash pop`
- **Branch exists**: Ask to delete existing branch first
- **Jira fetch fails**: Fallback to manual description

## Success Response

```
✅ Branch created: hous-1234/feature-name
Base: master (latest)
Jira: [HOUS-1234] Feature Summary
```

## Safety Checks

- Verify git repository
- Check for uncommitted changes  
- Validate branch name format
- Confirm no existing branch conflict
