# Pull Request Creation Workflow

Automates the complete workflow from branch creation to PR submission with proper Jira integration.

## Core Workflow

### 1. Branch Creation
```bash
git checkout master && git pull origin master && git checkout -b <branch-name>
```

### 2. PR Creation Sequence
**ALWAYS** follow this exact sequence:

1. **Push branch first**: `git push origin <branch-name>`
2. **Then create PR**: Use `gh pr create` command

This prevents interactive prompts and ensures a smooth PR creation process.

## Branch Naming Convention

- Always include Jira ticket number in branch names
- **Always use lowercase** for branch names
- Format: `<jira-ticket>/descriptive-name` or `feature/hous-1234-brief-description` or `bugfix/HOUS-1234-brief-description`
- Examples:
  - `hous-1711/cursor-add-real-data`
  - `feature/hous-1518-add-user-authentication`
  - `bugfix/hous-1519-fix-form-validation`

## PR Title Format

- **MUST** include Jira ticket number in brackets at the beginning
- **MUST** capitalize the Jira ticket number (e.g., `hous-1518` becomes `HOUS-1518`)
- Format: `[HOUS-1234] Brief description of changes`
- Examples:
  - `[HOUS-1518] Add user authentication middleware`
  - `[HOUS-1519] Fix form validation issues`

## PR Description Requirements

- **MUST** include a link to the Jira ticket in the description
- Format: `Jira: https://spotify.atlassian.net/browse/HOUS-1234`
- Should include brief summary of changes and testing notes

## PR Creation Commands

### Step 1: Push Branch
```bash
git push origin <branch-name>
```

### Step 2: Create PR
```bash
gh pr create --title "[HOUS-1234] Your title" --body "Description with Jira: https://spotify.atlassian.net/browse/HOUS-1234"
```

Alternative: Use `pnpm pr` if available (may require manual title/description editing)

## Example Complete Workflow

```bash
# 1. Create branch from latest master
git checkout master
git pull origin master
git checkout -b hous-1518/add-user-authentication

# 2. After making changes and committing...
# 3. Push the branch
git push origin hous-1518/add-user-authentication

# 4. Create the PR
gh pr create \
  --title "[HOUS-1518] Add user authentication middleware" \
  --body "Implements JWT-based authentication for API endpoints.

Jira: https://spotify.atlassian.net/browse/HOUS-1518

## Changes
- Add JWT middleware
- Update route protection
- Add auth tests"
```

## Error Handling

- **Uncommitted changes**: `git stash` → create branch → `git stash pop`
- **Branch exists**: Ask to delete existing branch first
- **Push failures**: Check if branch already exists remotely
- **PR creation failures**: Verify repository permissions and branch status

## Success Response Requirements

- **ALWAYS** return the URL of the created PR in the response
- Include the PR URL prominently in the success message
- Format: `🎉 PR Created: [URL]`
- This helps users quickly access their pull request for review

### Example Success Response
```
✅ Branch created: hous-1518/add-user-authentication
Base: master (latest)

🚀 Branch pushed successfully

🎉 PR Created: https://github.com/spotify/project/pull/123
Title: [HOUS-1518] Add user authentication middleware
```

## Safety Checks

- Verify git repository
- Check for uncommitted changes before branch creation
- Validate branch name format
- Confirm no existing branch conflict
- Ensure clean working directory before pushing
- Verify remote repository access

## Integration Notes

This workflow integrates with:
- Jira ticket system for automatic ticket linking
- GitHub CLI (`gh`) for PR creation
- Git workflow best practices from existing rules