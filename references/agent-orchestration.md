# Agent Orchestration Protocol

This document defines how agents coordinate through the **dispatcher** (`AGENTS.md`). Agents do NOT communicate directly with each other — the dispatcher handles all routing and chaining.

---

## Overview

The dispatcher is a **reactive multi-router** with skill-first routing:

1. **User sends a message** → dispatcher checks the **skill routing table** first
2. **Skill match found?** → run the skill in the main conversation context and respond to user
3. **No skill match?** → dispatcher picks the best **agent** by priority
4. **Agent executes** → returns output to the dispatcher
5. **Dispatcher reads the output** → decides if another agent should be chained
6. **Repeat** until done or max depth reached

Agents help the dispatcher by including **suggestions** in their output when they detect work for other agents.

---

## Skill-First Routing

Skills are checked **before** agents. They handle complex, multi-step workflows that were extracted from agents for better performance.

### How it works

- The dispatcher maintains a **skill routing table** (defined in `AGENTS.md`) with trigger phrases in multiple languages.
- If a user message matches a skill trigger, the dispatcher runs the skill in the main conversation context instead of invoking an agent file. The dispatcher does NOT also invoke the source agent.
- Skills run in the **main conversation context**, preserving multi-turn state. This is different from agents, which run as subprocesses.
- If no skill matches, the dispatcher falls through to the **agent routing table**.

### Skill-to-agent chaining

Skills can still produce output that triggers agent chaining:
- A skill may include `### Suggested next agent` in its output (e.g., `/onboarding` may suggest Connector to link newly created notes).
- The dispatcher reads this output and applies the same chaining rules as for agents (check registry, check call chain, max depth 3).
- Skills count as step 1 in the call chain when they produce agent suggestions.

### List of skills

See `.codex/references/agents.md` (Skills section) for the full table of skills, their source agents, and purposes.

---

## How Agents Signal the Dispatcher

When an agent detects work that another agent should handle, it includes a section at the end of its output:

```markdown
### Suggested next agent
- **Agent**: {name from agents-registry.md}
- **Reason**: {what needs to be done and why}
- **Context**: {relevant details the next agent would need — note titles, folder paths, specific issues}
```

Multiple suggestions are allowed — list them all. The dispatcher prioritizes and decides which (if any) to invoke.

### Examples

```markdown
### Suggested next agent
- **Agent**: architect
- **Reason**: No area exists for "Personal Finance" — 3 notes were placed in Inbox as fallback
- **Context**: Notes: "Monthly Budget March.md", "Savings Goals.md", "Expense Tracking.md". Suggest creating 02-Areas/Personal Finance/ with sub-folders and MOC.
```

```markdown
### Suggested next agent
- **Agent**: connector
- **Reason**: 5 recently filed notes about "Machine Learning" have no cross-links
- **Context**: Notes in 03-Resources/Technology/ML/. They reference shared concepts (gradient descent, neural networks) but have zero wikilinks between them.

### Suggested next agent
- **Agent**: architect
- **Reason**: MOC for Machine Learning is missing
- **Context**: There are now 8 notes under this topic but no MOC in MOC/ folder.
```

### Suggesting a New Agent

When an agent detects that the user needs functionality that no existing agent provides, it can suggest creating a new custom agent:

```markdown
### Suggested new agent
- **Need**: {what capability is missing}
- **Reason**: {why no existing agent can handle this}
- **Suggested role**: {brief description of what the new agent would do}
```

The dispatcher reads this and may invoke the **Architect** to start the custom agent creation flow. This is NOT automatic. The dispatcher should confirm with the user first:

> "The [agent] noticed you might benefit from a custom agent for [need]. Would you like me to create one?"

---

## Dispatcher Decision Logic

After each agent returns, the dispatcher:

1. **Reads the output** — looks for `### Suggested next agent` sections
2. **Consults `agents-registry.md`** — validates the suggested agent exists and is `active`
3. **Checks the call chain** — is this agent already in the chain? Is max depth reached?
4. **Checks for `### Suggested new agent`** -- if present, asks the user if they want the Architect to create a custom agent
5. **Decides**: invoke next agent OR return results to user

The dispatcher can also chain agents **without an explicit suggestion** if the output clearly matches another agent's capabilities (e.g., notes created → Sorter might be needed).

---

## Call Chain Tracking

Every user request has a **call chain** — the ordered list of agents invoked so far.

### Rules

1. **Start**: chain is empty `[]`
2. **After each agent returns**: append its name to the chain (the chain always lists agents already invoked, in order)
3. **Pass the chain**: when invoking the next agent, tell it the chain and its position — `"Call chain so far: [scribe, architect]. You are step 3 of max 3."`
4. **No duplicates**: never invoke the same agent twice in one chain
5. **No circular patterns**: if Agent A suggests Agent B and B is already in the chain, skip
6. **Max depth: 3**: no more than 3 agents per user request
7. **On overflow**: return results to user with a note about what was deferred

### What Happens at Max Depth

If the dispatcher would need a 4th agent, it:
- Returns the current results to the user
- Includes a summary of what was deferred: _"The Connector also detected 5 orphan notes that need linking — you can say 'connect the notes' to handle that."_

---

## Custom Agent Lifecycle

Custom agents are created by the Architect and stored in `.codex/agents/`. They participate fully in the orchestration system:

1. **Creation**: the Architect creates the agent file, adds a row to `agents-registry.md`, and updates `agents.md`
2. **Discovery**: the installed runtime exposes the new agent from `.codex/agents/`, and the dispatcher can route to it using the registry plus its frontmatter description
3. **Routing**: the dispatcher checks `agents-registry.md` for custom agents when no core agent matches
4. **Chaining**: custom agents can suggest (and be suggested by) any other agent, following the same protocol
5. **Maintenance**: the Librarian audits custom agents during vault health checks. For every row in agents-registry.md with status=active, the corresponding file must exist in `.codex/agents/`
6. **Deletion**: only the Architect can remove a custom agent (with user confirmation). The agent file is deleted, and the registry row is set to `disabled`

---

## What Agents Should NOT Do

- ❌ **Do NOT reference `Meta/agent-messages.md`** — the shared message board is deprecated
- ❌ **Do NOT edit other agents' prompt/config files** (e.g., `.codex/agents/*.md`) — normal vault notes/MOC edits are still allowed per your responsibilities; all coordination goes through the dispatcher
- ❌ **Do NOT block waiting for another agent** — finish your task and suggest next steps in your output
- ❌ **Do NOT call other agents** — only the dispatcher invokes agents

---

## Migration from Legacy System

If a vault still has the old `Meta/agent-messages.md` file:
- The **Librarian** will rename it to `Meta/agent-messages-DEPRECATED.md` during maintenance
- Agents should ignore this file entirely — all coordination now flows through the dispatcher

---

## Agent State (Post-it Protocol)

Every agent has a personal post-it file at `Meta/states/{agent-name}.md`. This provides continuity between executions.

### Rules

- **One file per agent** — named after the agent (e.g., `Meta/states/scribe.md`)
- **Always written** — every agent writes its post-it at the end of every execution, no exceptions
- **Overwrites previous** — each execution replaces the previous post-it (it is not a log)
- **Max 30 lines** — agents must keep the body under 30 lines to prevent bloat
- **Read at start** — agents read their post-it at the start of execution for context
- **Private** — the dispatcher does not read or write agent post-its. Only the owning agent touches its own file
- **Multi-step flows** — agents that run multi-step conversations (e.g., Architect onboarding) use the post-it to track their current phase and collected answers, so they can resume on re-invocation

### Format

```markdown
---
agent: {agent-name}
last-run: "YYYY-MM-DDTHH:MM:SS"
---

## Post-it

[Agent's notes — max 30 lines]
```

---

## Reference Files

- **Agent registry**: `.codex/references/agents-registry.md` — the single source of truth for all agents
- **Agent directory**: `.codex/references/agents.md` — detailed descriptions of each agent's responsibilities
