# Inter-Agent Messaging Protocol

This document defines how agents communicate with each other asynchronously through the vault's shared message board at `Meta/agent-messages.md`.

---

## Overview

Every agent has **two mandatory steps** that wrap every task:

1. **Before starting any task** — read `Meta/agent-messages.md`, check for messages addressed to you, and resolve any pending items first.
2. **During a task, when encountering uncertainty or problems** — leave a message for the appropriate agent in `Meta/agent-messages.md`.

This creates a lightweight coordination layer that lets agents help each other without requiring the user to manually coordinate between them.

---

## The Message Board File

### Location
`Meta/agent-messages.md`

### Format

```markdown
# Agent Message Board

<!-- Messages are listed newest-first. Resolved messages are marked with a checkmark and kept for 7 days, then archived by the Librarian. -->

---

## [pending] [YYYY-MM-DD] FROM: {{AgentName}} -> TO: {{AgentName}}
**Subject**: {{Brief subject line}}

**Context**: {{What I was doing when I encountered this}}

**Problem**: {{What I don't know or can't resolve}}

**My Proposed Solution**: {{What I think should be done — always include a suggestion}}

**Impact if unresolved**: {{What I did instead / what I left pending}}

---

## [resolved] [YYYY-MM-DD] FROM: {{AgentName}} -> TO: {{AgentName}}
**Subject**: {{Brief subject line}}

**Resolution**: {{What was decided / done}}

---
```

---

## Step-by-Step: How to Use the Message Board

### Step 1: Read Your Messages (Always First)

At the start of **every task**, before doing anything else:

1. Read `Meta/agent-messages.md`
2. Look for messages with `-> TO: {{YourAgentName}}` that are marked `[pending]`
3. For each pending message addressed to you:
   - Read the full message
   - Act on it (make the structural change, answer the question, create the folder, etc.)
   - Mark the message as resolved by changing `[pending]` to `[resolved]` and adding a **Resolution** line
4. Once all your pending messages are resolved, proceed with the user's task

If `Meta/agent-messages.md` doesn't exist yet, create it with the header and an empty state:

```markdown
# Agent Message Board

<!-- Messages are listed newest-first. Resolved messages are marked [resolved] and kept for 7 days, then archived by the Librarian. -->

*(No messages yet)*
```

### Step 2: Leave Messages When You Need Help

During your task, if you encounter a situation where:
- You don't know where something should go
- You're unsure about a structural decision
- You find a problem that another agent should fix
- You have a suggestion for improving how something is organized

**Append a message to `Meta/agent-messages.md`** addressed to the right agent.

Always include:
- **Your name** as sender
- **The recipient agent's name**
- **Context**: what you were doing
- **Problem**: what you're uncertain about
- **Your proposed solution**: never just report a problem — always suggest what you think should be done
- **What you did in the meantime**: what action you took (or didn't take) while waiting for a response

### Step 3: Continue Your Task

After leaving a message, don't block — continue with the rest of your task. Either:
- Apply your proposed solution provisionally (and note this in the message)
- Skip the uncertain item and note it in your report to the user
- Handle the simple case and flag the edge case for the appropriate agent

---

## Message Writing Rules

1. **Always propose a solution** — never just say "I don't know". Say "I don't know, but I think we should do X because Y."
2. **Be specific** — mention the exact note title, folder path, or tag involved
3. **One message per issue** — don't bundle unrelated problems in one message
4. **Stay professional** — messages are part of the vault's knowledge system
5. **Don't be noisy** — only leave messages for genuine uncertainties, not every minor decision
6. **Include enough context** — the recipient agent should be able to act without asking follow-up questions

---

## When to Leave a Message vs. When to Decide

**Leave a message** when:
- The decision affects the overall vault structure (new folder, new area, new tag category)
- The decision might conflict with work another agent is doing
- You've encountered the same uncertainty more than once
- The decision has long-term implications for how the vault is organized

**Decide on your own** when:
- It's a minor, local choice with no structural implications
- The vault conventions clearly cover this case
- You can easily reverse the decision if needed
- It would cause significant delay to wait for a response

---

## Agent Name Reference

Use these names in messages:

| Agent | Use in messages |
|-------|----------------|
| Architect | `FROM/TO: Architect` |
| Scribe | `FROM/TO: Scribe` |
| Sorter | `FROM/TO: Sorter` |
| Seeker | `FROM/TO: Seeker` |
| Connector | `FROM/TO: Connector` |
| Librarian | `FROM/TO: Librarian` |
| Transcriber | `FROM/TO: Transcriber` |
| Postman | `FROM/TO: Postman` |
| Food Coach | `FROM/TO: Food Coach` |
| Wellness Guide | `FROM/TO: Wellness Guide` |

---

## Example Messages

### Example 1: Sorter -> Architect (structural gap)

```markdown
## [pending] [2026-03-20] FROM: Sorter -> TO: Architect
**Subject**: No area for "Personal Finance" notes

**Context**: While triaging the inbox, I found 3 notes about personal budgeting, monthly expenses, and savings goals.

**Problem**: No folder exists in `02-Areas/` for personal finance. Existing areas are: Engineering, Marketing, Sales, HR. These notes don't belong to any of them.

**My Proposed Solution**: Create `02-Areas/Personal Finance/` with an index.md and a dedicated MOC. The 3 notes could live there. Alternatively, if finance is considered too personal for "areas of responsibility", a dedicated category could be created.

**Impact if unresolved**: I temporarily placed the 3 notes in `03-Resources/Finance/` as a provisional solution. If the Architect creates the dedicated area, they can be moved.
```

### Example 2: Resolution

```markdown
## [resolved] [2026-03-21] FROM: Sorter -> TO: Architect
**Subject**: No area for "Personal Finance" notes

**Resolution**: Created `02-Areas/Personal Finance/` with index.md and `MOC/Personal Finance.md`. Tag taxonomy updated with `#area/personal-finance`. Notes in `03-Resources/Finance/` can be moved by the Sorter in the next session.
```

### Example 3: Food Coach -> Wellness Guide (cross-domain)

```markdown
## [pending] [2026-03-20] FROM: Food Coach -> TO: Wellness Guide
**Subject**: Possible stress-eating pattern detected

**Context**: During a meal logging session, the user reported eating a large unplanned meal and explicitly connected it to work stress ("I was so stressed about the deadline").

**Problem**: This is the second time this week the user has reported stress-driven eating. This may indicate a pattern worth exploring from a psychological perspective.

**My Proposed Solution**: In your next session with the user, consider exploring the connection between work stress and eating patterns. ACT-based strategies for sitting with discomfort without turning to food might be helpful.

**Impact if unresolved**: I provided supportive, non-judgmental guidance and a concrete plan for tomorrow's meals. I did not attempt to address the emotional component — that's your domain.
```

---

## Message Retention Policy

- **[pending] messages**: stay until resolved
- **[resolved] messages**: kept for 7 days, then removed by the Librarian during weekly maintenance
- **Archived messages**: moved to `Meta/agent-message-archive/{{YYYY-MM}}.md` by the Librarian
