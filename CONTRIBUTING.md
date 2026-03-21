# Contributing to Obsidian Vault Crew

First of all: thank you. This project exists because of a personal need, and it will grow because of shared ones.

---

## Ways to contribute

### Translate a skill into your language

This is probably the most impactful thing you can do.

Each skill lives in `skills/<agent-name>/SKILL.md`. The files are currently in Italian with English trigger descriptions. To add a language:

1. Fork the repo
2. Create `skills/<agent-name>/SKILL.<lang>.md` (e.g., `SKILL.es.md`, `SKILL.fr.md`, `SKILL.de.md`)
3. Translate the skill content — keep the structure, adapt the trigger phrases, idioms, and cultural references to your language
4. Open a PR with the title: `[lang] Add <language> translation for <agent-name>`

Don't worry about making it perfect. A rough translation that works for native speakers is infinitely more useful than no translation.

### Propose a new crew member

Have an idea for a new agent? Open an issue with:

- **Name** (and Italian equivalent, for consistency)
- **Role** — what problem does it solve?
- **Triggers** — when should it activate?
- **Vault integration** — which folders does it read/write?
- **Inter-agent messages** — which other agents should it communicate with?

### Improve an existing skill

Found that an agent behaves weirdly, gives poor results, or misses edge cases?

1. Open an issue describing the problem with a concrete example
2. Or directly submit a PR with the improvement

### Report a bug

Open an issue. Include:
- What you asked the agent to do
- What it actually did
- What you expected it to do
- Your vault structure (roughly) if relevant

---

## Skill file structure

Each skill follows this pattern:

```yaml
---
name: <agent-name>
description: >
  One paragraph description used for agent triggering.
  Include Italian (or relevant language) trigger phrases here.
metadata:
  version: "x.x.x"
  agent-role: "<Display Name>"
---

# <Agent Name> — <Subtitle>

[Agent instructions follow]
```

The `description` field is used by Claude to decide *when* to activate the agent. Make sure trigger phrases are natural and match how a real user would actually speak.

---

## Inter-agent messaging

Agents communicate through `Meta/agent-messages.md` in the vault. The protocol is documented in `references/inter-agent-messaging.md`. If your new agent needs to communicate with existing ones, follow that protocol.

---

## Philosophy to keep in mind

This project is built for people who are already overwhelmed. Contributions should make things **simpler**, not more complex. When in doubt, ask: *does this make life easier for someone who's barely keeping it together?*

If yes, it belongs here.

---

## Code of conduct

Be kind. This project touches on health, mental wellness, and personal struggle. Treat contributors and users with the same care you'd want when you're not at your best.
