# /jira - Jira Ticket Management for Howcome

Create and manage Jira tickets for the Howcome project using the acli CLI tool.

## Usage

```bash
/jira create [--summary "Summary"] [--description "Description"] [--type task|bug|story|sub-task] [--parent OH-XXXX]
/jira search [epics|tickets] [--jql "custom JQL"]
/jira view <ticket-key>
```

## Project Configuration

- **Project**: HOUS (always)
- **Assignee**: @me (always)
- **Parent Epic**: Dynamically selected from current open epics

## Epic Selection

When creating tickets, I will:

1. **Search current open epics** to find the best match for your work
2. **Suggest appropriate epic** based on the task context
3. **Ask for confirmation** if the epic assignment is unclear

## Examples

**Create a database task:**

```bash
/jira create --summary "Add index for tagged comment queries" --description "Create composite index on tagged_comments table to optimize filtering by tag and episode" --type task --parent OH-3014
```

**Create a bug:**

```bash
/jira create --summary "Comment filtering returns incorrect results" --description "When filtering by CONTAINS_QUESTION tag, some comments are missing from results" --type bug --parent OH-3184
```

**View epics:**

```bash
/jira search epics
```

**View specific ticket:**

```bash
/jira view OH-3184
```

## Implementation

When you use this command, I will:

1. **Ask for clarification** when requirements are vague or incomplete
2. **Confirm details** before creating tickets with specific technical specs
3. **Search open epics** and suggest best match based on conversation context
4. **Let user provide** summary and description, or ask targeted questions
5. **Select proper ticket type** (task/bug/story/sub-task)
6. **Execute acli command** with proper OH project settings

**Important**: Don't make assumptions about technical requirements. Always ask for confirmation on:

- Specific features and functionality needed
- Technical implementation details
- Business requirements and constraints
- Database schema or API specifications

## Success Response Format

After successfully creating any ticket, **ALWAYS** provide the ticket link in this format:

```
✅ Ticket created: [HOUS-1234] Summary text here
🔗 Link: https://spotify.atlassian.net/browse/HOUS-1234
```
