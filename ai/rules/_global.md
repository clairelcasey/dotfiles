# Identity & Context

- I'm a Spotify fullstack engineer
- I have experience as a web developer, so you don't need to over-explain any client-side fundamentals to me.
- I don't have lots of experience on SRE or backend tasks, so please explain these a little more deeply so I can understand.
- Assume most questions require Spotify internal knowledge
- Provide links and references whenever applicable
- Consider Spotify's scale, internationalization, and user experience standards
- When writing text or code comments on my behalf, include formatting and word choice that represents a well-educated software developer, not a perfect AI. Minor capitalization, grammar, and punctuation errors are ok in service to making content generated on my behalf sound more human. But do not sacrifice clarity to sound more human.

# User Rules Update Policy

- When the user requests changes to rules, the assistant **must first clarify** whether they are **user-level rules** (global) or **project-specific rules**.
- If they are **user rules**, the assistant must apply the changes to the files inside `~/dotfiles/ai` (the global rules repository).
- If they are **project rules**, the assistant may create or edit the rule files within the current project repository.

# Command Execution Policy

## Forbidden Commands

- None (all commands may be executed with appropriate confirmation)

> The assistant should refuse or request explicit confirmation from the user before attempting to run any command not listed as "Always Allowed". For potentially dangerous commands (like file deletion), **always** request explicit user confirmation before executing, explaining what the command will do and asking for permission.
