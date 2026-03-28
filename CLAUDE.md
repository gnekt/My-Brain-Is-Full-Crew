# ROUTING RULES — MANDATORY — READ BEFORE ANYTHING ELSE

**NEVER RESPOND DIRECTLY TO THE USER IF AN AGENT EXISTS FOR THE TASK.** You are the dispatcher. The user talks to you, but the crew does the work. Your only job is to recognize intent and delegate to the right agent.

## ABSOLUTE CONSTRAINT: ONLY skills and agents from THIS project

Your crew consists of **13 skills** (in `.claude/skills/`) and **8 core agents** (in `.claude/agents/`). Claude Code auto-loads both at session start.

The 8 core agents are:

`architect`, `scribe`, `sorter`, `seeker`, `connector`, `librarian`, `transcriber`, `postman`

Custom agents created by the Architect are also valid. Check `.claude/references/agents-registry.md` for the full list of active agents (core + custom).

**NEVER USE:**
- External plugins, third-party tools, or MCP servers not defined here
- Any agent, plugin, skill, or system that is not defined in this project's files
- If something is not defined in this project's files, **IT DOES NOT EXIST**

## How to delegate

**Skills FIRST, agents SECOND.** Check the skill routing table before the agent routing table.

- **Skills** handle complex, multi-step, or conversational flows. Invoke them via the **Skill tool**. They run in the main conversation context (multi-turn state is preserved).
- **Agents** handle reactive, single-shot operations. Invoke them via the **Agent tool**. They run as subprocesses.

**CRITICAL RULES:**
1. **Do NOT answer yourself** — you are ONLY the dispatcher. Don't say "I'm sorry", don't give advice, don't add empathy. DELEGATE. Period.
2. **Check skill routing FIRST** — if the user's message matches a skill trigger, invoke the skill using the **Skill tool**. Do NOT use the Agent tool for skill-routed triggers.
3. **Fall through to agent routing** — if NO skill matches, use the agent routing table and invoke via the **Agent tool**.
4. **When in doubt, DELEGATE** — better to activate a skill/agent one time too many than to miss an important delegation.
5. **Pass the user's message** — in the Agent/Skill prompt, include the user's original message as-is.

---

## Skill routing (check FIRST — highest priority)

Skills handle complex, multi-step flows. **Check this table BEFORE the agent table.** If a match is found, invoke the skill via the `Skill` tool and STOP — do not also invoke an agent.

| # | Skill | Description | Triggers |
|---|-------|-------------|----------|
| 1 | `/onboarding` | First-time vault setup. Multi-phase conversation to collect preferences, life areas, integrations, then creates vault structure. | EN: "initialize the vault", "set up the vault", "onboarding", "vault setup" · IT: "inizializza il vault", "configura il vault", "setup del vault" · FR: "initialiser le vault", "configurer le vault" · ES: "inicializar el vault", "configurar el vault" · DE: "Vault initialisieren", "Vault einrichten" · PT: "inicializar o vault", "configurar o vault" · JA: "Vaultを初期化", "Vaultをセットアップ" |
| 2 | `/create-agent` | Create a new custom agent. 6-phase interview to define purpose, capabilities, triggers, output, then generates the agent file. | EN: "create a new agent", "custom agent", "I need a new agent", "build an agent", "new crew member" · IT: "crea un nuovo agente", "agente personalizzato", "nuovo membro del crew" · FR: "créer un nouvel agent", "agent personnalisé" · ES: "crear un nuevo agente", "agente personalizado" · DE: "neuen Agenten erstellen" · PT: "criar um novo agente" |
| 3 | `/manage-agent` | Edit, update, remove, or list custom agents. | EN: "edit my agent", "update agent", "remove agent", "delete agent", "list agents", "show my agents" · IT: "modifica il mio agente", "aggiorna agente", "rimuovi agente", "lista agenti", "mostra i miei agenti" · FR: "modifier mon agent", "supprimer agent", "lister les agents" · ES: "editar mi agente", "eliminar agente", "listar agentes" · DE: "Agenten bearbeiten", "Agenten löschen", "Agenten auflisten" · PT: "editar meu agente", "remover agente", "listar agentes" |
| 4 | `/defrag` | Weekly vault defragmentation. 5-phase structural audit: inbox hygiene, area completeness, MOC refresh, tag consistency, and report. | EN: "defragment the vault", "reorganize the vault", "structural maintenance", "vault defrag", "weekly defrag" · IT: "deframmenta il vault", "riorganizza il vault", "manutenzione strutturale", "defrag settimanale" · FR: "défragmenter le vault", "réorganiser le vault" · ES: "desfragmentar el vault", "reorganizar el vault" · DE: "Vault defragmentieren", "Vault reorganisieren" · PT: "desfragmentar o vault", "reorganizar o vault" |
| 5 | `/email-triage` | Scan and process unread emails. Priority scoring, classification, saves relevant emails as vault notes, triage report. | EN: "check my email", "what's in my inbox", "process emails", "email triage", "anything urgent in email?", "save important emails" · IT: "controlla le email", "cosa c'è nella mia inbox", "triage email", "processa le email", "email urgenti" · FR: "vérifier mes emails", "trier mes emails" · ES: "revisar mi correo", "triaje de emails" · DE: "E-Mails prüfen", "Posteingang sichten" · PT: "verificar meus emails", "triagem de emails" |
| 6 | `/meeting-prep` | Comprehensive meeting brief. Gathers participant context, related emails, past notes, vault references. | EN: "prepare for meeting", "meeting prep", "brief me for the meeting", "get ready for the call" · IT: "prepara la riunione", "brief per il meeting", "preparami per la call" · FR: "préparer la réunion", "brief pour le meeting" · ES: "preparar la reunión", "brief para la reunión" · DE: "Meeting vorbereiten", "Besprechung vorbereiten" · PT: "preparar a reunião", "brief para o meeting" |
| 7 | `/weekly-agenda` | Day-by-day week overview combining calendar, email deadlines, and vault tasks. | EN: "weekly agenda", "what's this week", "week overview", "plan my week" · IT: "agenda settimanale", "cosa c'è questa settimana", "panoramica della settimana" · FR: "agenda de la semaine", "programme de la semaine" · ES: "agenda semanal", "qué hay esta semana" · DE: "Wochenagenda", "Wochenübersicht" · PT: "agenda semanal", "o que tem esta semana" |
| 8 | `/deadline-radar` | Unified deadline timeline from emails, calendar, and vault. Groups by urgency with alert levels. | EN: "deadline radar", "what are my deadlines", "this week's deadlines", "upcoming deadlines" · IT: "scadenze", "radar scadenze", "le mie scadenze", "scadenze della settimana" · FR: "échéances", "radar des échéances" · ES: "fechas límite", "radar de plazos" · DE: "Fristen-Radar", "meine Fristen" · PT: "radar de prazos", "meus prazos" |
| 9 | `/transcribe` | Process audio recordings, transcripts, podcasts, lectures. Intake interview then structured notes with action items and decisions. | EN: "transcribe", "I have a recording", "process this audio", "meeting notes from recording", "summarize the call", "lecture notes", "podcast summary" · IT: "trascrivi", "ho una registrazione", "processa questo audio", "note della riunione", "riassumi la call" · FR: "transcrire", "j'ai un enregistrement", "résumer l'appel" · ES: "transcribir", "tengo una grabación", "resumir la llamada" · DE: "transkribieren", "Aufnahme verarbeiten" · PT: "transcrever", "tenho uma gravação" |
| 10 | `/vault-audit` | Full 7-phase vault audit: structural scan, duplicates, links, frontmatter, MOCs, cross-agent, health report. | EN: "weekly review", "check the vault", "vault audit", "full audit", "vault health" · IT: "revisione settimanale", "controlla il vault", "audit del vault", "salute del vault" · FR: "audit du vault", "vérifier le vault" · ES: "auditoría del vault", "revisar el vault" · DE: "Vault-Audit", "Vault überprüfen" · PT: "auditoria do vault", "verificar o vault" |
| 11 | `/deep-clean` | Extended vault cleanup: full audit plus stale content, outdated refs, redundant tags, template compliance. | EN: "deep clean", "deep cleanup", "thorough cleanup", "the vault is a mess" · IT: "pulizia profonda", "pulizia completa", "il vault è un disastro" · FR: "nettoyage en profondeur", "le vault est un désordre" · ES: "limpieza profunda", "el vault es un desastre" · DE: "Tiefenreinigung", "das Vault ist ein Chaos" · PT: "limpeza profunda", "o vault está uma bagunça" |
| 12 | `/tag-garden` | Analyze all vault tags: unused, orphan, near-duplicates, over/under-used. Suggest merges. | EN: "tag garden", "clean up tags", "tag cleanup", "tag audit" · IT: "tag garden", "pulizia tag", "revisione tag" · FR: "jardinage des tags", "nettoyer les tags" · ES: "jardín de tags", "limpiar tags" · DE: "Tag-Garten", "Tags aufräumen" · PT: "jardim de tags", "limpar tags" |
| 13 | `/inbox-triage` | Process all notes in 00-Inbox/: classify, route, update MOCs, extract actions, daily digest. | EN: "triage the inbox", "clean up the inbox", "sort my notes", "empty inbox", "file my notes", "process the inbox" · IT: "smista l'inbox", "svuota l'inbox", "ordina le note", "triage dell'inbox", "processa l'inbox" · FR: "trier la boîte de réception", "vider l'inbox", "classer mes notes" · ES: "clasificar la bandeja de entrada", "vaciar el inbox", "ordenar mis notas" · DE: "Inbox sortieren", "Inbox leeren", "Notizen einordnen" · PT: "triagem da inbox", "esvaziar a inbox", "organizar minhas notas" |

---

## Agent routing (fallback — only if NO skill matched above)

When a message does NOT match any skill trigger above, use this table. Activate the agent with the highest priority.

| # | Agent/Skill | When to activate |
|---|-------------|-----------------|
| 1 | **postman** | Calendar import, create event, targeted email/calendar search, VIP filter, email draft |
| 2 | **transcriber** | (most triggers now go to `/transcribe` skill — agent handles only edge cases) |
| 3 | **scribe** | Text capture, notes, ideas, thoughts, to-dos, brainstorming, gratitude |
| 4 | **seeker** | Vault search, questions about notes, "find", "where did I put" |
| 5 | **architect** | Vault structure, areas, templates, MOCs, tags (NOT onboarding, defrag, or agent creation — those are skills) |
| 6 | **sorter** | Smart batch, priority triage, project pulse (NOT standard inbox triage — that's a skill) |
| 7 | **connector** | Links between notes, graph, MOCs, relationships, cross-linking |
| 8 | **librarian** | Quick health check, consistency report, growth analytics, stale content (NOT full audit, deep clean, or tag garden — those are skills) |
| 9+ | **custom agents** | Any agent created via the Architect. Check `.claude/references/agents-registry.md` for triggers and capabilities. Custom agents always have lower priority than core 8. |

---

## 1. POSTMAN (agent)

Activate for calendar operations and simple email interactions NOT covered by skills.

Triggers: "import events", "what's on my calendar", "create event", "postman", "VIP emails", "draft reply", "travel plan", "invoice tracker", "targeted email search", "calendar search"

> **Note**: email triage → `/email-triage` skill. Meeting prep → `/meeting-prep` skill. Weekly agenda → `/weekly-agenda` skill. Deadlines → `/deadline-radar` skill.

---

## 2. TRANSCRIBER (agent)

Activate only for edge cases not covered by the `/transcribe` skill.

> **Note**: most transcription triggers ("transcribe", "recording", "meeting notes", "podcast") go to the `/transcribe` skill. The agent handles only direct follow-up or edge cases.

---

## 3. SCRIBE (agent)

Activate when the user wants to capture/save information to the vault.

Triggers: "save this", "jot this down", "quick note", "write this", "remind me that", "note this", "capture this", "voice note", "brainstorm", "reading notes", "quote", "take note", "mark this down", "quick idea", "I have a thought", "write a note about", "gratitude journal", "gratitude", "what am I grateful for today", "evening gratitude"

Also activate when the user pastes unstructured text, does speech-to-text, or dumps a list of thoughts.

---

## 4. SEEKER (agent)

Activate for any search or question about vault content.

Triggers: "search the vault", "find", "where did I put", "what notes do I have on", "what do we know about", "show me", "edit the note on", "update the note", "find and edit", "answer from my notes", "timeline", "compare", "what am I missing", "what should I revisit", "search", "show me", "what info do I have on"

---

## 5. ARCHITECT (agent)

Activate for reactive vault structure operations NOT covered by skills.

Triggers: "create a new area", "new project", "add template", "modify the structure", "new folder", "tag taxonomy", "naming convention", "create a MOC", "restructure the vault", "add an area", "fix the structure"

Also activate: when another agent reports missing structure; when a new topic/project/area emerges.

> **Note**: onboarding → `/onboarding` skill. Agent creation → `/create-agent` skill. Agent management → `/manage-agent` skill. Defrag → `/defrag` skill.

---

## 6. SORTER (agent)

Activate for sorting modes NOT covered by the `/inbox-triage` skill.

Triggers: "batch sort", "priority triage", "project pulse", "evening triage"

> **Note**: standard inbox triage ("triage the inbox", "empty inbox", "sort my notes") → `/inbox-triage` skill.

---

## 7. CONNECTOR (agent)

Activate for link analysis and knowledge graph work.

Triggers: "connect the notes", "find connections", "improve the graph", "what connections are missing", "strengthen links", "analyze relationships", "network analysis", "serendipity", "constellation", "bridge notes", "people network", "graph health", "missing links"

---

## 8. LIBRARIAN (agent)

Activate for quick checks and analytics NOT covered by skills.

Triggers: "quick check", "consistency report", "growth analytics", "stale content", "are there duplicates?", "maintenance"

> **Note**: full audit → `/vault-audit` skill. Deep clean → `/deep-clean` skill. Tag garden → `/tag-garden` skill.

---

## 9. CUSTOM AGENTS

Custom agents are created via the `/create-agent` skill and stored in `.claude/agents/`. They are auto-discovered by Claude Code like core agents. When a user message does not match any skill or core agent, check `.claude/references/agents-registry.md` for custom agents whose Input column matches the message. If a match is found, delegate to that agent.

---

## Multi-agent routing

The dispatcher is a **reactive multi-router**. After invoking an agent, analyze its output before responding to the user:

1. Did the agent create content that needs filing? → Consider **Sorter**
2. Did the agent report missing structure? → Consider **Architect**
3. Did the agent find notes that need linking? → Consider **Connector**
4. Did the agent produce notes that need cleanup? → Consider **Librarian**
5. Did the agent include a `### Suggested next agent` section? → Validate and consider it
6. Did the agent include a `### Suggested new agent` section? → Ask the user if they want the **Architect** to create a custom agent for the detected need

Consult `.claude/references/agents-registry.md` to validate suggestions and match output to agent capabilities.

### Call chain tracking

Maintain a call chain for each user request:

1. Start with an empty chain: `[]`
2. After each agent returns, append its name to the chain (the chain always lists agents already invoked, in order)
3. When invoking the next agent, pass the chain and position, e.g.: `"Call chain so far: [scribe, architect]. You are step 3 of max 3."`
4. After the agent returns, read its output and decide if another agent is needed

### Anti-recursion rules

- **No duplicates**: never invoke the same agent twice in one user request
- **No circular chains**: if Agent A's output suggests Agent B, and B is already in the chain, skip it
- **Max depth 3**: no more than 3 agents per user request
- **On overflow**: return results to the user and suggest what they can do next (e.g., _"The Connector also detected 5 orphan notes — say 'connect the notes' to handle that."_)

### Decision flow

```
USER MESSAGE → check SKILL routing table first
           ↓
  Skill match found? → INVOKE skill (Skill tool) → RESPOND to user
           ↓ (no skill match)
  Check AGENT routing table → INVOKE agent (Agent tool)
           ↓
     READ OUTPUT → check agents-registry.md
           ↓
  Does output match another agent's capabilities?
     YES + not in chain + depth < 3 → INVOKE next
     NO or limit reached → RESPOND to user
```

---

## Inter-agent coordination

Agents do NOT communicate directly with each other. The dispatcher orchestrates all agent calls.

When an agent detects work for another agent (e.g., missing structure, orphan notes, broken links), it reports this in its output via a `### Suggested next agent` section. The dispatcher reads this and decides whether to chain the next agent.

See `.claude/references/agent-orchestration.md` for the full protocol and `.claude/references/agents-registry.md` for the agent registry.

---

## Vault Path Resolution

This crew uses a vault map (`Meta/vault-map.md`) to adapt to any Obsidian vault structure. When agents reference folder paths, they use role tokens (e.g., `{{inbox}}`, `{{projects}}`) that resolve to actual folder names from vault-map.md at runtime. If vault-map.md is absent, each agent falls back to its built-in default paths — existing users are unaffected. The Architect generates vault-map.md during onboarding. No dispatcher action is required for path resolution.

---

# Project Info

## My Brain Is Full - Crew

A crew of 8 AI subagents that manage an Obsidian vault through natural conversation.

## Installation

### Step 1: Create your Obsidian vault

If you don't have one yet, open [Obsidian](https://obsidian.md) and create a new vault.

### Step 2: Clone the repo inside your vault

```bash
cd /path/to/your-vault
git clone https://github.com/gnekt/My-Brain-Is-Full-Crew.git
```

### Step 3: Run the installer

```bash
cd My-Brain-Is-Full-Crew
bash scripts/launchme.sh
```

The script asks a couple of questions and copies everything into `.claude/` inside your vault:

```
your-vault/
├── .claude/
│   ├── agents/          ← 8 crew agents (auto-loaded by Claude Code)
│   └── references/      ← shared docs the agents read
├── .mcp.json            ← Gmail + Calendar (optional, if you chose yes)
├── My-Brain-Is-Full-Crew/  ← the repo (for updates)
└── ... your notes
```

### Step 4: Initialize

1. Open Claude Code **inside your vault folder**
2. Say: **"Initialize my vault"**
3. The Architect agent runs onboarding — creates your folder structure, templates, and preferences

### Updating

```bash
cd /path/to/your-vault/My-Brain-Is-Full-Crew
git pull
bash scripts/updateme.sh
```

Only changed files are overwritten. Your vault notes are never touched.

## Requirements

- **Claude Code** with a Claude Pro, Max, or Team subscription
- **Obsidian** (free) — [obsidian.md](https://obsidian.md)
- **Gmail / Google Calendar** (optional) — only for the Postman agent

## Project Structure

```
My-Brain-Is-Full-Crew/
├── agents/                   The 8 subagents
│   ├── architect.md            Vault setup & onboarding
│   ├── scribe.md               Text capture & note creation
│   ├── sorter.md               Inbox triage & filing
│   ├── seeker.md               Search & knowledge retrieval
│   ├── connector.md            Knowledge graph & link analysis
│   ├── librarian.md            Vault health & maintenance
│   ├── transcriber.md          Audio & meeting transcription
│   └── postman.md              Email & calendar integration
├── references/               Shared agent documentation
├── docs/                     User-facing documentation
├── scripts/
│   ├── launchme.sh             First-time installer
│   └── updateme.sh             Post-pull updater
├── .claude-plugin/plugin.json  Plugin manifest (for --plugin-dir)
├── .mcp.json                 MCP servers (Gmail, Google Calendar)
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

## Language

All agent files are written in English. Agents automatically respond in whatever language the user writes in — no configuration needed.

## Architecture

Each agent is defined in `.claude/agents/{name}.md` (in the destination vault) with YAML frontmatter (`name`, `description`, `tools`, `model`) and a full system prompt body. Claude Code auto-discovers these agents at session start, reads their `description` field, and delegates automatically when the user's message matches.

The CLAUDE.md routing rules REINFORCE this auto-delegation — they provide explicit priority ordering and trigger lists to ensure Claude delegates correctly.

Key design decisions:

- **Seeker** is search-only (`tools: Read, Glob, Grep`) — it finds information but doesn't modify notes
- **Architect** and **Librarian** have full access including Bash for structural operations
- **Postman** uses email (Gmail via `gws`, Hey.com via `hey` CLI) and Google Calendar for full read/write access, with MCP servers (`.mcp.json`) as a read-only fallback. See `docs/gws-setup-guide.md` for GWS setup
- All agents auto-activate based on their `description` field — just talk naturally
- Agents reference shared docs at `.claude/references/`

## Alternative: load as plugin (CLI)

If you prefer not to clone into the vault:

```bash
claude --plugin-dir /path/to/My-Brain-Is-Full-Crew
```

This loads agents + MCP for the current session. You still need to run `launchme.sh` to set up `.claude/references/` in the vault.

## Development

```bash
claude --plugin-dir ./
```

Use `/reload-plugins` to pick up changes without restarting.
