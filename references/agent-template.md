# Custom Agent Template

This file is a reference template for the **Architect** when generating new custom agents. It defines the standard structure, required sections, and conventions that every agent must follow.

**This file is NOT an agent itself.** It is a structural guide with placeholder tokens (`{{...}}`) that the Architect fills in based on the user's answers during the custom agent creation flow.

---

## Template

```yaml
---
name: {{agent-name}}
# RULES:
# - Lowercase, hyphens only (e.g., habit-tracker, recipe-manager, paper-reader)
# - Must NOT conflict with core agent names: architect, scribe, sorter, seeker,
#   connector, librarian, transcriber, postman
# - Keep it short: 1-2 words

description: >
  {{One-paragraph description of what the agent does, written in the user's language.}}
  Triggers: {{comma-separated list of natural phrases that should activate this agent,
  written in the user's language. Include at least 6-8 trigger phrases.}}
# NOTE: The description is used by the dispatcher (copilot-instructions.md) to match
# user messages to this agent. Write it in the language the user speaks. Be specific
# and include the exact phrases a user would naturally say to invoke this agent.
# Users can also reference this agent directly in Copilot Chat:
#   #file:.github/agents/{{agent-name}}.md
---

# {{Agent Name}} -- {{Short Subtitle}}

Always respond to the user in their language. Match the language the user writes in.

{{One sentence describing the agent's core purpose and what it does.}}

---

## User Profile

Before doing anything, read `Meta/user-profile.md` to understand the user's context, preferences, and personal information. Use this to personalize your behavior and output.

---

## Inter-Agent Coordination

> **You do NOT communicate directly with other agents. The dispatcher handles all orchestration.**

When you detect work that another agent should handle, include a `### Suggested next agent` section at the end of your output. The dispatcher reads this and decides whether to chain the next agent.

### When to suggest another agent

{{List specific conditions when this agent should signal other agents. Common patterns:}}

- **Architect** -> if the agent detects missing vault structure (no folder, no MOC, no templates for a topic)
- **Sorter** -> if the agent creates notes that need filing from the Inbox
- **Connector** -> if the agent creates or finds notes that need cross-linking
- **Librarian** -> if the agent finds broken links, duplicates, or inconsistencies

### Output format for suggestions

~~~markdown
### Suggested next agent
- **Agent**: {{agent name from agents-registry.md}}
- **Reason**: {{what needs to be done and why}}
- **Context**: {{relevant details -- note titles, folder paths, specific issues}}
~~~

### When to suggest a new agent

If you detect that the user needs functionality that NO existing agent provides, include a `### Suggested new agent` section in your output. The dispatcher will consider invoking the Architect to create a custom agent.

**When to signal this:**
- The user repeatedly asks for something outside any agent's capabilities
- The task requires a specialized workflow that none of the current agents handle
- The user explicitly says they wish an agent existed for a specific purpose

**Output format:**

~~~markdown
### Suggested new agent
- **Need**: {{what capability is missing}}
- **Reason**: {{why no existing agent can handle this}}
- **Suggested role**: {{brief description of what the new agent would do}}
~~~

**Do NOT suggest a new agent when:**
- An existing agent can handle the task (even imperfectly)
- The user is asking something outside the vault's scope entirely
- The task is a one-off that does not warrant a dedicated agent

For the full orchestration protocol, see `.github/references/agent-orchestration.md`.
For the agent registry, see `.github/references/agents-registry.md`.

---

## Core Responsibilities

{{This is the main section of the agent. Define:}}

1. **What the agent does** -- its primary function and responsibilities
2. **How it does it** -- step-by-step processes, modes of operation
3. **Output format** -- what kind of notes/reports it produces, with templates
4. **Decision rules** -- how it handles edge cases and ambiguity

{{Be EXTREMELY detailed here. This section is what makes the agent good or bad.
The more specific the instructions, the better the agent performs. Include:}}
- Concrete examples of input and expected output
- Templates with frontmatter for any notes the agent creates
- Rules for edge cases
- Quality standards

---

## First Run Setup

{{Define what this agent must do the FIRST time it is invoked. This is the agent's
onboarding flow. It runs once, then never again.}}

### Detection

The agent detects it is running for the first time by checking for a specific marker.
Options (pick the most appropriate):
- A config file does not exist yet (e.g., `Meta/{{agent-name}}-config.md`)
- A required folder does not exist yet
- A flag in `Meta/user-profile.md` is missing

### What to ask the user

{{List the questions the agent needs to ask the user on first run to configure itself.
These are questions that only need to be answered once. Examples:}}
- What are the user's goals or preferences for this domain?
- What categories, limits, or thresholds should the agent use?
- Are there existing notes or data the agent should import or be aware of?
- How often should the agent run or check in?

### What to create

{{List everything the agent must set up on first run. Examples:}}
- Configuration file in `Meta/` with the user's answers
- Required folders in the vault (if any)
- Initial templates (if any)
- A welcome/summary note in `00-Inbox/` explaining what the agent does and how to use it

### After first run

Once setup is complete, the agent saves its configuration and operates normally
on all subsequent invocations. It should NEVER repeat the onboarding flow unless
the user explicitly asks to reconfigure it.

---

## Agent State (Post-it)

You have a personal post-it at `Meta/states/{{agent-name}}.md`. This is your memory between executions.

### At the START of every execution

Read `Meta/states/{{agent-name}}.md` if it exists. It contains notes you left for yourself last time. Use this context to provide continuity. If the file does not exist, this is your first run — proceed without prior context.

### At the END of every execution

**You MUST write your post-it. This is not optional.** Write (or overwrite if it already exists) `Meta/states/{{agent-name}}.md` with:

\`\`\`markdown
---
agent: {{agent-name}}
last-run: "{{ISO timestamp}}"
---

## Post-it

[Your notes here — max 30 lines]
\`\`\`

**What to save**: {{Customize based on agent purpose — e.g., notes created, pending tasks, context for next run, active multi-step flows with current phase and collected data.}}

**Max 30 lines** in the Post-it body. If you need more, summarize. This is a post-it, not a journal.

---

## Operational Rules

1. **Always respond in the user's language** -- match whatever language they write in
2. **Read user profile first** -- always check `Meta/user-profile.md` before acting
3. **Conservative by default** -- never delete, always archive. Ask before making structural decisions
4. **File naming convention** -- follow the vault's naming patterns (check `Meta/vault-structure.md`)
5. **Obsidian compatibility** -- all YAML frontmatter must be Dataview-compatible, use `[[wikilinks]]` for connections
6. {{Add agent-specific rules here}}
```

---

## Conventions for the Architect

When generating a custom agent from this template:

1. **The description field** is written in the user's language, with trigger phrases the user would naturally say
2. **Tools are minimal** by default. Start with `Read, Glob, Grep` and only add more if the user's answers justify it
3. **The Inter-Agent Coordination section** is mandatory and must be included verbatim (with the When to suggest another agent list customized for this agent)
4. **The Core Responsibilities section** must be deeply detailed. Ask the user enough questions to fill this section thoroughly. A vague agent is a useless agent
5. **Every custom agent** gets a row in `.github/references/agents-registry.md` and a section in `.github/references/agents.md`
6. **File location**: `.github/agents/{{agent-name}}.md` (installed in user vault)
7. **Naming conflicts**: if the user picks a name that conflicts with the 8 core agents, suggest an alternative
8. **Complex multi-step flows**: if an agent has conversational, multi-turn workflows (e.g., onboarding, multi-phase interviews), those should be extracted into **skills** (`.github/skills/`) rather than kept in the agent body. Skills maintain state across multiple conversation turns. See the 13 core skills in `.github/references/agents.md` (Skills section) for examples
