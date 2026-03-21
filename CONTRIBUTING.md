# Contributing to My Brain Is Full - Crew

Thank you for your interest in making the Crew better. This project was born from personal need, and it grows through shared ones.

---

## Ways to contribute

### Improve an existing agent

Found that an agent behaves weirdly, gives poor results, or misses edge cases?

1. Open an issue describing the problem with a concrete example
2. Or submit a PR with the improvement

Agent files live in `agents/<agent-name>.md`. The plugin manifest is at `.claude-plugin/plugin.json`. All agents are written in English — they automatically respond in the user's language.

To test your changes locally:
```bash
claude --plugin-dir ./
```

### Propose a new crew member

Have an idea for an 11th agent? Open an issue with:

- **Name** — both a descriptive English name and a short codename
- **Role** — what problem does it solve?
- **Triggers** — when should it activate? (include phrases in multiple languages)
- **Tool access** — which tools does it need? (Read, Write, Edit, Bash, Glob, Grep)
- **Vault integration** — which folders does it read/write?
- **Inter-agent messages** — which other agents should it communicate with?
- **Why it matters** — what gap in the current crew does it fill?

### Add usage examples

Real-world examples of how you use the Crew help everyone. Add them to `docs/examples.md` or share them in an issue.

### Report a bug

Open an issue with:
- What you asked the agent to do
- What it actually did
- What you expected
- Your vault structure (roughly) if relevant

---

## Agent file structure

Each agent is a Claude Code **subagent** — a standalone `.md` file with YAML frontmatter:

```yaml
---
name: <agent-codename>
description: >
  One paragraph description used for auto-triggering.
  Include trigger phrases in multiple languages (English, Italian, French,
  Spanish, German, Portuguese) for maximum discoverability.
tools: Read, Write, Edit, Glob, Grep
model: sonnet
---

# <Display Name> — <Subtitle>

[Agent instructions in English]
```

### Frontmatter fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase, hyphens only (e.g., `food-coach`) |
| `description` | Yes | When Claude should auto-invoke this agent. Include multilingual triggers |
| `tools` | Yes | Comma-separated list of allowed tools |
| `disallowedTools` | No | Tools to explicitly deny (e.g., `Write, Edit` for read-only agents) |
| `model` | No | `sonnet`, `opus`, or `haiku` (default: inherits from parent) |

### Key rules for agent files

1. **Write in English** — All agent instructions are in English. Agents respond in the user's language automatically.
2. **Multilingual triggers** — The `description` field should include natural trigger phrases in at least English and Italian, ideally more languages.
3. **Read user profile** — Agents should read `Meta/user-profile.md` for personalization. Never hardcode personal data.
4. **Inter-agent messaging** — Every agent must include the messaging protocol section. See `references/inter-agent-messaging.md`.
5. **Conservative by default** — Agents never delete, always archive. They ask before making structural decisions.
6. **Minimal tools** — Only grant the tools the agent actually needs. Read-only agents should use `disallowedTools: Write, Edit`.

---

## Inter-agent messaging

Agents communicate through `Meta/agent-messages.md` in the user's vault. The protocol is documented in `references/inter-agent-messaging.md`. If your new or improved agent needs to communicate with existing ones, follow that protocol.

---

## Agent directory

| File | Agent name | Role | Tools |
|------|-----------|------|-------|
| `architect.md` | Architect | Vault Structure & Setup | Read, Write, Edit, Bash, Glob, Grep |
| `scribe.md` | Scribe | Text Capture | Read, Write, Edit, Glob, Grep |
| `sorter.md` | Sorter | Inbox Triage | Read, Write, Edit, Glob, Grep, Bash |
| `seeker.md` | Seeker | Search & Retrieval | Read, Glob, Grep |
| `connector.md` | Connector | Knowledge Graph | Read, Edit, Glob, Grep |
| `librarian.md` | Librarian | Vault Maintenance | Read, Write, Edit, Bash, Glob, Grep |
| `transcriber.md` | Transcriber | Audio & Transcription | Read, Write, Glob, Grep |
| `postman.md` | Postman | Email & Calendar | Read, Write, Edit, Glob, Grep |
| `food-coach.md` | Food Coach | Nutrition & Diet | Read, Write, Edit, Glob, Grep |
| `wellness-guide.md` | Wellness Guide | Mental Health | Read, Glob, Grep (read-only) |

---

## Philosophy

This project is built for people who are already overwhelmed. Contributions should make things **simpler**, not more complex.

When in doubt, ask: *"Does this make life easier for someone who's barely keeping it together?"*

If yes, it belongs here.

---

## Code of conduct

Be kind. This project touches on health, mental wellness, and personal struggle. Treat contributors and users with the same care you'd want when you're not at your best.
