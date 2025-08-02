# Task Management

Guidelines for task management in software development projects.

## Immediate Task Tracking

- Use the **TodoWrite tool** for complex, multi-step tasks that require immediate tracking during development sessions
- TodoWrite is ideal for breaking down work into actionable items and tracking progress in real-time

## Project Documentation

- For longer-term project documentation and feature tracking, use the **task-manager prompt**
- The task-manager prompt creates structured markdown files in `/task-lists/` folder
- These files document implementation plans, track progress across multiple sessions, and maintain project history

## When to Use Each Tool

**TodoWrite Tool:**
- Complex tasks requiring 3+ steps
- Real-time progress tracking during active development
- Breaking down user requests into actionable items
- Immediate task management within a session

**Task-Manager Prompt:**
- Project-wide feature documentation
- Long-term progress tracking across multiple sessions
- Implementation planning and architecture documentation
- Creating structured project documentation

# Development Best Practices

- Always recommend the minimal changes needed to meet request expectations
- Always re-run existing tests after any source code change
- If you modify any source file (e.g. `.py` files, `.js` files, `.ts` files), check if the repository contains any test, and run them. Tests might be inside folders called `test`, or files containing `test` in their name
