# Inter-Agent Messaging Protocol

This document defines how agents communicate with each other asynchronously through the vault's shared message board at `Meta/agent-messages.md`.

---

## Overview

Every agent has **two mandatory steps** that wrap every task:

1. **Before starting any task** → read `Meta/agent-messages.md`, check for messages addressed to you, and resolve any pending items first.
2. **During a task, when encountering uncertainty or problems** → leave a message for the appropriate agent in `Meta/agent-messages.md`.

This creates a lightweight coordination layer that lets agents help each other without requiring the user to manually coordinate between them.

---

## The Message Board File

The file `Meta/agent-messages.md` lives in the vault and is structured as a series of messages, each with a clear header. Agents read it at the start of their session and append to it when they have something to communicate.

### File Location
`Meta/agent-messages.md`

### File Format

```markdown
# Agent Message Board

<!-- Messages are listed newest-first. Resolved messages are marked ✅ and kept for 7 days, then cleaned up by the Bibliotecario. -->

---

## ⏳ [YYYY-MM-DD] FROM: {{AgentName}} → TO: {{AgentName}}
**Subject**: {{Brief subject line}}

**Context**: {{What I was doing when I encountered this}}

**Problem**: {{What I don't know or can't resolve}}

**My Proposed Solution**: {{What I think should be done — always include a suggestion}}

**Impact if unresolved**: {{What I did instead / what I left pending}}

---

## ✅ [YYYY-MM-DD] FROM: {{AgentName}} → TO: {{AgentName}} — RESOLVED
**Subject**: {{Brief subject line}}

**Resolution**: {{What was decided / done}}

---
```

---

## Step-by-Step: How to Use the Message Board

### Step 1: Read Your Messages (Always First)

At the start of **every task**, before doing anything else:

1. Read `Meta/agent-messages.md`
2. Look for messages with `→ TO: {{YourAgentName}}` that are marked `⏳` (pending)
3. For each pending message addressed to you:
   - Read the full message
   - Act on it (make the structural change, answer the question, create the folder, etc.)
   - Mark the message as resolved by changing `⏳` to `✅` and adding a **Resolution** line
4. Once all your pending messages are resolved, proceed with the user's task

If `Meta/agent-messages.md` doesn't exist yet, create it with the header and an empty state:

```markdown
# Agent Message Board

<!-- Messages are listed newest-first. Resolved messages are marked ✅ and kept for 7 days, then cleaned up by the Bibliotecario. -->

*(No messages yet)*
```

### Step 2: Leave Messages When You Need Help

During your task, if you encounter a situation where:
- You don't know where something should go
- You're unsure about a structural decision
- You find a problem that another agent should fix
- You have a suggestion for improving how something is organized

**→ Append a message to `Meta/agent-messages.md`** addressed to the right agent.

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

## Example Messages

### Example 1: Smistatore → Architetto (structural gap)

```markdown
## ⏳ [2026-03-20] FROM: Smistatore → TO: Architetto
**Subject**: Nessuna area per note di "Finanza Personale"

**Context**: Stavo smistando la inbox e ho trovato 3 note su budget personale, spese mensili e obiettivi di risparmio.

**Problem**: Non esiste nessuna cartella in `02-Areas/` dedicata alla finanza personale. Le aree esistenti sono: Engineering, Marketing, Sales, HR. Queste note non appartengono a nessuna di esse.

**My Proposed Solution**: Creare `02-Areas/Finanza Personale/` con un index.md e un MOC dedicato. Le 3 note potrebbero vivere lì. In alternativa, se la finanza è considerata troppo personale per le "aree di responsabilità", si potrebbe creare una categoria apposita.

**Impact if unresolved**: Ho temporaneamente lasciato le 3 note in `03-Resources/Finance/` come soluzione provvisoria. Se l'Architetto crea l'area dedicata, basterà spostarle.
```

### Example 2: Architetto → Smistatore (risoluzione)

```markdown
## ✅ [2026-03-21] FROM: Smistatore → TO: Architetto — RESOLVED
**Subject**: Nessuna area per note di "Finanza Personale"

**Resolution**: Creata `02-Areas/Finanza Personale/` con index.md e `MOC/Finanza Personale.md`. Tag taxonomy aggiornata con `#area/finanza-personale`. Le note in `03-Resources/Finance/` possono essere spostate lì dallo Smistatore nella prossima sessione.
```

### Example 3: Connettore → Bibliotecario (problema qualità)

```markdown
## ⏳ [2026-03-20] FROM: Connettore → TO: Bibliotecario
**Subject**: 12 note in `01-Projects/Alpha/` senza frontmatter `project` field

**Context**: Stavo analizzando le connessioni nel progetto Alpha e ho scoperto che 12 note non hanno il campo `project:` nel frontmatter, il che le rende invisibili alle query Dataview sul progetto.

**My Proposed Solution**: Aggiungere `project: "Alpha"` al frontmatter di tutte e 12 le note. Il titolo è abbastanza specifico che il rischio di errore è basso.

**Impact if unresolved**: Le query Dataview sul progetto Alpha restituiscono risultati incompleti. Ho continuato l'analisi ma ho escluso queste note dal report.
```

---

## Message Retention Policy

- **⏳ Pending messages**: stay until resolved
- **✅ Resolved messages**: kept for 7 days, then removed by the Bibliotecario during weekly maintenance
- **Old resolved messages**: archived to `Meta/agent-message-archive/{{YYYY-MM}}.md` by the Bibliotecario
