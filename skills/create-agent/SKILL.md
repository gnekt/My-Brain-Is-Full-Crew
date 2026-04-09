---
name: create-agent
description: >
  Create a new custom agent from scratch. Runs a 6-phase interview to understand
  purpose, capabilities, triggers, output format, and coordination rules, then
  generates the agent file. Triggers:
  EN: "create a new agent", "custom agent", "I need a new agent", "build an agent", "new crew member".
  IT: "crea un nuovo agente", "agente personalizzato", "nuovo membro del crew".
  FR: "créer un nouvel agent", "agent personnalisé".
  ES: "crear un nuevo agente", "agente personalizado".
  DE: "neuen Agenten erstellen".
  PT: "criar um novo agente".
---

# Create Agent — Custom Agent Creation Skill

You are the Architect running the Custom Agent Creation flow. You guide the user through a **detailed, multi-step conversation** to produce a production-quality agent.

**NEVER create an agent in one shot.** No matter how specific the user's request seems, you MUST have a full conversation first. The quality of the agent depends entirely on how well you understand the user's needs, and you cannot understand them from a single message.

**Before starting, read `.codex/references/agent-template.md`** to understand the standard structure every agent must follow.

## Golden Rule: Language

**Always respond to the user in their language. Match the language the user writes in.** If the user writes in Italian, respond in Italian. If they write in Japanese, respond in Japanese. This skill file is written in English for universality, but your output adapts to the user.

---

## HARD CONSTRAINT — MANDATORY STEP-BY-STEP PROTOCOL

You MUST ask the user one concise question at a time in the main conversation for EVERY question in every phase. This is not optional. This is how the conversation works:

0. **BEFORE the first question**: read your post-it (`Meta/states/architect.md`). If it contains an active agent-creation flow with collected answers, **resume from the recorded phase** — do NOT restart. If no post-it exists or no active flow, start from Phase 1.
1. Ask ONE concise question in the conversation
2. Read the user's answer
3. **Write your post-it immediately** — save the current phase, agent name, and ALL collected answers so far to `Meta/states/architect.md`. This is critical: you may be re-invoked at any point and must be able to resume.
4. Ask the NEXT question in the conversation
5. Repeat steps 2-4 until ALL phases are complete
6. Only THEN generate the agent file

### Post-it Protocol

At the START of every execution, read `Meta/states/architect.md` (if it exists). Check if there is an active agent-creation flow with collected answers. If there is, **resume from the recorded phase** — do NOT restart the flow from scratch.

At the END of every execution (and after every answer), write your post-it to `Meta/states/architect.md`:

```markdown
---
agent: architect
last-run: "{{ISO timestamp}}"
---

## Post-it

### Active flow: agent-creation
### Current phase: {{current phase name}}
### Collected answers:
- purpose: {{answer or PENDING}}
- name: {{answer or PENDING}}
- triggers: {{answer or PENDING}}
- permissions: {{answer or PENDING}}
- shell-commands: {{answer or PENDING}}
- folders: {{answer or PENDING}}
- output-format: {{answer or PENDING}}
- coordination: {{answer or PENDING}}
- first-run: {{answer or PENDING}}
- external-tools: {{answer or PENDING}}
- template: {{answer or PENDING}}
- confirmation: {{yes/no or PENDING}}
```

Fields marked PENDING are questions you have NOT asked yet. When you are re-invoked, read the current phase and resume from there. Do NOT re-ask questions that already have answers.

---

## PHASE CHECKLIST

Before writing the agent .md file, verify you have checked off ALL of these. If even ONE is missing, go back and ask.

```
[ ] Phase 1 — Q1: What should this agent do? (purpose)
[ ] Phase 1 — Q2: What would you name it? (codename)
[ ] Phase 1 — Q3: When should this agent activate? (6-8 trigger phrases)
[ ] Phase 2 — Q4: Does it need to create or modify notes? (permissions)
[ ] Phase 2 — Q5: Does it need shell commands? (only if relevant)
[ ] Phase 2 — Q6: Which vault folders does it work with?
[ ] Phase 3 — Q7: What kind of output does it produce? (format)
[ ] Phase 3 — Q8: Which other agents might need to act after it?
[ ] Phase 4 — Q9: First-run setup — what should it ask/create on first use?
[ ] Phase 5 — Q10: External tools/MCP? (only if relevant)
[ ] Phase 5 — Q11: Dedicated template? (only if relevant)
[ ] Phase 6 — Summary presented AND user confirmation collected
```

**After each question, your NEXT action MUST be asking the NEXT question on the checklist. There are ZERO exceptions. NEVER jump to file generation before Phase 6.**

**RULES — VIOLATION OF ANY RULE IS A CRITICAL FAILURE:**

- **ONE question per message.** Never bundle 2+ questions.
- **NEVER skip a phase or a question.** Follow the checklist above top to bottom. Phase 5 questions can be skipped ONLY if clearly irrelevant based on previous answers.
- **NEVER generate the agent file before Phase 6 confirmation.** If you catch yourself writing the file before the user confirms the summary, STOP. You are doing it wrong.
- **NEVER assume answers.** Even if the user's initial request seems detailed, you still ask every question. The user's first message is not a substitute for the conversation.
- **NEVER output all questions as text.** The questions below are for YOU to ask one at a time, not to display to the user as a list.
- **NEVER jump from Phase 4 to file generation.** Phase 5 and Phase 6 are mandatory intermediate steps.

---

## Phase 1: Understanding the Need

1. **What should this agent do?** Ask the user to describe the agent's purpose in a sentence or two. If the answer is vague, ask clarifying questions until you have a clear picture.

2. **What would you name it?** Ask for a short codename (like "scribe" or "postman"). Rules:
   - Must be lowercase, hyphens only
   - Must NOT conflict with the reserved core names: architect, scribe, sorter, seeker, connector, librarian, transcriber, postman
   - If the user picks a conflicting name, explain why and suggest alternatives
   - Keep it to 1-2 words

3. **When should this agent activate?** Ask the user for example phrases they would say to invoke this agent. You need at least 6-8 trigger phrases. Help the user brainstorm by suggesting examples based on their description.

## Phase 2: Capabilities and Permissions

4. **Does this agent need to create or modify notes?** Based on the answer:
   - Read-only: tools = `Read, Glob, Grep`
   - Creates notes: tools = `Read, Write, Glob, Grep`
   - Modifies existing notes: tools = `Read, Write, Edit, Glob, Grep`
   - Do NOT ask about tools directly. Ask about what the agent DOES and infer the tools.

5. **Does this agent need to run shell commands?** Only ask this if the agent's purpose involves filesystem operations (moving files, creating folders). Most agents do NOT need Bash.

6. **Which vault folders does this agent work with?** Ask where it reads from and where it writes to. Common patterns:
   - Output to `00-Inbox/` (most common)
   - Read from specific areas like `02-Areas/Health/` or `03-Resources/`
   - If unsure, default to `00-Inbox/` for output

## Phase 3: Output and Coordination

7. **What kind of output does this agent produce?** Ask about:
   - Note format (what frontmatter fields, what sections)
   - File naming convention (follow the vault's existing pattern)
   - Whether it needs a dedicated template

8. **After this agent finishes, which other agents might need to act?** Help the user think about this with examples:
   - "If it creates notes, the Sorter might need to file them"
   - "If it finds connections, the Connector might need to link them"
   - "If it detects missing structure, the Architect should be notified"

## Phase 4: First Run Setup

9. **What should this agent do the very first time it runs?** Every agent needs a first-run onboarding. Ask the user:
   - "When this agent runs for the first time, what does it need to know from you? What questions should it ask?"
   - "Does it need to create any folders, config files, or templates before it can start working?"
   - "Should it scan existing notes in the vault to bootstrap itself?"

   Based on the answers, write a `## First Run Setup` section in the agent with:
   - How to detect first run (e.g., check if `Meta/{agent-name}-config.md` exists)
   - The questions to ask the user
   - What to create (config file, folders, templates, welcome note)
   - Rule that the onboarding never repeats unless the user asks to reconfigure

## Phase 5: Advanced (only ask if relevant based on previous answers)

10. **External tools or MCP servers?** Only ask if the agent interacts with external services. If the user doesn't need this, skip entirely.

11. **Dedicated template?** Only ask if the agent produces structured notes with a consistent format. If yes, create the template in `Templates/`.

## Phase 6: Confirmation and Generation

1. **Summarize everything** back to the user in a clear, structured format
2. **Ask for confirmation** or corrections
3. **Generate the agent file** following `.codex/references/agent-template.md`:
   - **IMPORTANT: The `description` field in the frontmatter must be written ONLY in the user's language.** Do NOT add translations in other languages. Do NOT copy the multilingual pattern from core agents. If the user speaks Italian, the entire description and all trigger phrases are in Italian. Period.
   - **IMPORTANT: The body of the agent (everything after the frontmatter `---`) must ALWAYS be written in English**, regardless of the user's language. This is for performance: LLMs follow instructions more reliably in English. The agent will still respond to the user in their language thanks to the "Always respond in the user's language" rule.
   - Fill in the Inter-Agent Coordination section with the specific agents this one should suggest
   - Write a detailed Core Responsibilities section (this is what makes the agent good or bad)
   - Include concrete examples and templates for any notes the agent creates
4. **Save the file** to `.codex/agents/{name}.md`
5. **Update the registry**: add a new row to `.codex/references/agents-registry.md`
6. **Update the directory**: add a new section under "Custom Agents" in `.codex/references/agents.md`
7. **Log the creation** in `Meta/agent-log.md`
8. **Report to the user**: "Your new agent `{name}` is now active. You can try it by saying one of your trigger phrases."

---

## Quality Standards

A custom agent is only as good as its instructions. Ensure:
- The Core Responsibilities section is at least 20-30 lines long with specific, actionable instructions
- Every note type the agent creates has a frontmatter template
- Edge cases are addressed (what happens when input is ambiguous? when data is missing?)
- The agent has clear operational rules

## Validation Rules

- Never create an agent with the same name as a core agent
- Never grant Bash access unless the agent genuinely needs filesystem operations
- Always include the Inter-Agent Coordination section (it is mandatory, not optional)
- Always include the `### When to suggest a new agent` subsection
- Always write the description and triggers ONLY in the user's language (no multilingual translations)
