# Agent Reference

This document provides comprehensive information about the specialized AI agents available in the dotfiles system.

## Overview

Agents are specialized AI configurations designed for specific tasks. Each agent has:

- **Defined purpose** and expertise area
- **Limited tool access** for security and focus
- **Specialized prompts** for optimal performance
- **Color coding** for organization

## Available Agents

### 1. docs-audit

**Purpose**: Documentation audit specialist that creates accurate developer-focused documentation

**Configuration**:
```yaml
name: docs-audit
description: Documentation audit specialist that creates accurate developer-focused documentation
tools: "Read, Write, Glob, Grep, LS, Bash"
color: "blue"
```

**Capabilities**:
- Repository structure analysis
- Code architecture understanding
- Documentation gap identification
- Comprehensive documentation creation

**Use Cases**:
- Repository documentation audits
- Creating missing documentation
- Standardizing documentation across projects
- Architecture documentation

**Workflow**:
1. Analyze entire codebase structure
2. Examine dependencies and configuration
3. Identify key components and functionality
4. Create structured documentation in `docs/` folder
5. Focus on accuracy over assumptions

**Output Files**:
- `README.md` - Project overview and getting started
- `ARCHITECTURE.md` - System design and components  
- `API.md` - API endpoints and interfaces (if applicable)
- `DEVELOPMENT.md` - Setup, testing, contribution guides
- `DEPLOYMENT.md` - Deployment instructions (if configs exist)

### 2. route-walkthrough

**Purpose**: API flow explainer optimized for monorepos and natural-language queries

**Configuration**:
```yaml
name: route-walkthrough
description: |
  API-flow explainer. **Use PROACTIVELY** whenever the user asks what happens 
  when an endpoint is hit, or requests architecture diagrams / docs for a 
  specific code path. Optimised for monorepos, single-service repos, and 
  natural-language queries.
tools: Read, Grep, Glob, Bash, Write, Web
color: "green"
```

**Capabilities**:
- API endpoint flow analysis
- Code path tracing
- Architecture diagram generation
- Cross-service interaction mapping

**Use Cases**:
- "What happens when endpoint X is hit?"
- API documentation creation
- Understanding request/response flows
- Debugging API issues
- Architecture visualization

**Proactive Usage**: This agent should be used automatically when users ask about:
- API endpoint behavior
- Request flow analysis
- Architecture documentation
- Service interaction patterns

### 3. general-explainer

**Purpose**: General-purpose code explanation and analysis

**Configuration**:
```yaml
name: general-explainer
description: General purpose code explainer for any codebase analysis
tools: "Read, Grep, Glob, Write"
color: "purple"
```

**Capabilities**:
- Code structure analysis
- Function and class explanation
- Design pattern identification
- General code documentation

**Use Cases**:
- Understanding unfamiliar codebases
- Code review assistance
- Legacy code analysis
- Educational code explanation

## Agent Usage

### Invoking Agents

Agents are invoked automatically by Claude Code based on:

1. **Task Type**: Specific request patterns trigger appropriate agents
2. **User Intent**: Natural language processing identifies suitable agent
3. **Context**: Repository structure and content influence agent selection

### Agent Selection Guidelines

| Task Type | Recommended Agent | Reason |
|-----------|------------------|---------|
| Documentation audit | docs-audit | Specialized documentation creation |
| API flow analysis | route-walkthrough | API-specific expertise |
| Code explanation | general-explainer | General code analysis |
| Architecture docs | docs-audit or route-walkthrough | Depends on API focus |

### Manual Agent Selection

While agents are typically selected automatically, you can request specific agents:

```
# Request specific agent
Please use the docs-audit agent to analyze this repository

# Or describe the task that would trigger the agent
I need to understand what happens when the /api/users endpoint is called
```

## Agent Architecture

### Agent File Structure

```yaml
---
name: agent-name              # Unique identifier
description: |                # Multi-line description
  What the agent does
  and its capabilities
tools: "Tool1, Tool2, Tool3"  # Allowed tools (space-separated)
color: "color-name"           # Visual organization
---

# Agent prompt content follows...
```

### Tool Restrictions

Each agent has access to specific tools only:

| Agent | Tools | Security Rationale |
|-------|-------|-------------------|
| docs-audit | Read, Write, Glob, Grep, LS, Bash | Full access for comprehensive analysis |
| route-walkthrough | Read, Grep, Glob, Bash, Write, Web | Web access for external API docs |
| general-explainer | Read, Grep, Glob, Write | Limited to safe analysis tools |

### Agent Distribution

Agents are synchronized via [`sync-claude-agents.sh`](../ai/sync-claude-agents.sh):

```bash
# Sync agents to Claude Code
~/dotfiles/ai/sync-claude-agents.sh

# Agents copied to ~/.claude/agents/
ls ~/.claude/agents/
```

## Creating Custom Agents

### Agent Template

```yaml
---
name: my-custom-agent
description: Brief description of agent purpose and capabilities
tools: "Read, Write, Grep"
color: "orange"
---

# Custom Agent Name

You are a specialized agent that performs [specific task].

## Your Role

[Detailed description of agent's role and capabilities]

## Guidelines

1. Always [specific behavior]
2. Never [forbidden behavior]
3. When [condition], do [action]

## Output Format

[Specify expected output format]
```

### Development Process

1. **Create Agent File**:
   ```bash
   vim ~/dotfiles/ai/agents/my-custom-agent.md
   ```

2. **Test Agent**:
   ```bash
   # Sync to Claude
   ~/dotfiles/ai/sync-claude-agents.sh
   
   # Test in Claude Code
   # Verify agent appears in agent list
   ```

3. **Refine Agent**:
   - Test agent behavior with various inputs
   - Adjust prompt for better performance
   - Validate tool usage is appropriate

### Best Practices for Agent Creation

#### Agent Design

1. **Single Purpose**: Each agent should have one clear, focused purpose
2. **Clear Boundaries**: Define what the agent should and shouldn't do
3. **Tool Minimalism**: Only include tools actually needed
4. **Consistent Naming**: Use descriptive, hyphenated names

#### Prompt Engineering

1. **Clear Instructions**: Specific, actionable guidance
2. **Context Setting**: Establish agent's role and expertise
3. **Output Specification**: Define expected output format
4. **Error Handling**: Guide agent behavior for edge cases

#### Security Considerations

1. **Tool Limitations**: Restrict tools to minimum necessary set
2. **Scope Boundaries**: Prevent agent from exceeding intended scope
3. **Safe Defaults**: Default to safe behavior when uncertain
4. **Validation**: Include input validation where appropriate

## Agent Maintenance

### Updating Agents

1. **Edit Agent File**:
   ```bash
   vim ~/dotfiles/ai/agents/agent-name.md
   ```

2. **Sync Changes**:
   ```bash
   ~/dotfiles/ai/sync-claude-agents.sh
   ```

3. **Test Updates**: Verify agent behavior meets expectations

### Agent Versioning

Track agent changes through git:

```bash
# View agent history
git log --follow ai/agents/agent-name.md

# Compare agent versions
git diff HEAD~1 ai/agents/agent-name.md
```

### Performance Monitoring

Monitor agent effectiveness:

1. **Task Completion**: Does agent complete intended tasks?
2. **Tool Usage**: Are agent tool restrictions appropriate?
3. **Output Quality**: Does agent produce expected output?
4. **User Feedback**: Are users satisfied with agent performance?

## Troubleshooting

### Agent Not Available

**Check Sync Status**:
```bash
# Verify agent file exists
ls ai/agents/agent-name.md

# Check Claude directory
ls ~/.claude/agents/

# Re-sync if needed
~/dotfiles/ai/sync-claude-agents.sh
```

### Agent Behaving Incorrectly

**Review Agent Configuration**:
1. Check agent prompt for clarity
2. Verify tool restrictions are appropriate
3. Test with simplified inputs
4. Compare with working agents

**Debug Process**:
1. Isolate problematic behavior
2. Review agent prompt for ambiguity
3. Test individual components
4. Refine prompt incrementally

### Tool Access Issues

**Verify Tool Configuration**:
```yaml
# Check tools are correctly specified
tools: "Read, Write, Grep"  # Correct: space-separated
tools: Read,Write,Grep      # Incorrect: comma-separated
```

**Check Tool Permissions**: Ensure Claude Code has necessary permissions for agent tools.

## Integration with Workflow

### AI-Clone Integration

Agents are automatically available in projects cloned via [`ai-clone`](../ai/ai-clone):

```bash
# Clone repository with agent setup
ai-clone git@github.com:user/repo.git

# Agents automatically available in Claude Code
```

### Project-Specific Agents

While global agents are available everywhere, you can create project-specific agents:

1. Create agent in project's `.cursor/rules/` directory
2. Agent available only in that project
3. Useful for project-specific workflows

### CI/CD Integration

Agents can be integrated into CI/CD pipelines:

```bash
# Use docs-audit agent for automated documentation checks
# Use route-walkthrough for API documentation generation
# Use general-explainer for code review assistance
```

## Future Enhancements

### Planned Agent Features

1. **Agent Composition**: Combine multiple agents for complex tasks
2. **Dynamic Tool Selection**: Agents adapt tool usage based on context
3. **Learning Capabilities**: Agents improve based on usage patterns
4. **Integration APIs**: Programmatic agent invocation

### Contributing New Agents

1. Identify common task patterns that would benefit from specialization
2. Design agent with clear scope and purpose
3. Implement and test agent thoroughly
4. Document agent capabilities and use cases
5. Submit agent for inclusion in dotfiles system

## Reference

### Agent File Locations

- **Source**: `~/dotfiles/ai/agents/*.md`
- **Deployed**: `~/.claude/agents/*.md`
- **Sync Script**: [`~/dotfiles/ai/sync-claude-agents.sh`](../ai/sync-claude-agents.sh)

### Related Documentation

- [Architecture Overview](ARCHITECTURE.md) - System design
- [AI Rules Reference](AI_RULES.md) - Rule system documentation
- [Development Guide](DEVELOPMENT.md) - Setup and testing