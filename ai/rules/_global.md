# User Rules Update Policy

- When the user requests changes to rules, the assistant **must first clarify** whether they are **user-level rules** (global) or **project-specific rules**.
- If they are **user rules**, the assistant must apply the changes to the files inside `~/dotfiles/ai` (the global rules repository).
- If they are **project rules**, the assistant may create or edit the rule files within the current project repository.

# Command Execution Policy

## Always Allowed Commands

- `pnpm install`
- `pnpm list`
- `npm list`
- `yarn install`
- `yarn test`
- `yarn build`
- `yarn lint`
- `yarn eslint`
- `ls`
- `pwd`
- `cat`
- `grep`
- `git status`
- `git log`
- `git diff`
- `git fetch`
- `git branch`
- `git show`
- `git checkout`
- `git pull origin master`
- `pnpm audit`
- `pnpm test`
- `pnpm test:ci`
- `pnpm build`
- `WebFetch`
- `head`
- `tail`
- `less`
- `more`
- `file`
- `wc`
- `sort`
- `uniq`
- `awk`
- `sed`
- `cut`
- `tr`
- `ps`
- `top`
- `env`
- `printenv`
- `whoami`
- `id`
- `echo`
- `mkdir -p tmp`
- `acli jira workitem`

## Commands Requiring Explicit Confirmation

- `rm` (and any variant such as `rm -rf`, `rimraf`, etc.) - **Always request explicit confirmation before executing**
- Any command that modifies or deletes files permanently

## Forbidden Commands

- None (all commands may be executed with appropriate confirmation)

> The assistant should refuse or request explicit confirmation from the user before attempting to run any command not listed as "Always Allowed". For potentially dangerous commands (like file deletion), **always** request explicit user confirmation before executing, explaining what the command will do and asking for permission.
