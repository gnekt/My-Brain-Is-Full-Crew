# Contributing to Obsidian Vault Crew

Thank you for your interest in making the Vault Crew better. This project was born from personal need, and it grows through shared ones.

---

## Ways to contribute

### Improve an existing agent

Found that an agent behaves weirdly, gives poor results, or misses edge cases?

1. Open an issue describing the problem with a concrete example
2. Or submit a PR with the improvement

Agent skill files live in `skills/<agent-name>/SKILL.md`. The plugin manifest is at `.claude-plugin/plugin.json`. All skills are written in English — agents automatically respond in the user's language.

To test your changes locally:
```bash
claude --plugin-dir ./
```

### Propose a new crew member

Have an idea for an 11th agent? Open an issue with:

- **Name** — both a descriptive English name and a short codename
- **Role** — what problem does it solve?
- **Triggers** — when should it activate? (include phrases in multiple languages)
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

## Skill file structure

Each skill file follows this format:

```yaml
---
name: <agent-codename>
description: >
  One paragraph description used for agent triggering.
  Include trigger phrases in multiple languages (English, Italian, French,
  Spanish, German, Portuguese) for maximum discoverability.
metadata:
  version: "x.x.x"
  agent-role: "<Display Name>"
---

# <Display Name> — <Subtitle>

[Agent instructions in English]
```

### Key rules for skill files

1. **Write in English** — All skill instructions are in English. Agents respond in the user's language automatically.
2. **Multilingual triggers** — The `description` field should include natural trigger phrases in at least English and Italian, ideally more languages.
3. **Read user profile** — Agents should read `Meta/user-profile.md` for personalization. Never hardcode personal data.
4. **Inter-agent messaging** — Every agent must include the messaging protocol section. See `references/inter-agent-messaging.md`.
5. **Conservative by default** — Agents never delete, always archive. They ask before making structural decisions.

---

## Inter-agent messaging

Agents communicate through `Meta/agent-messages.md` in the user's vault. The protocol is documented in `references/inter-agent-messaging.md`. If your new or improved agent needs to communicate with existing ones, follow that protocol.

---

## Agent names

| Skill folder | Agent name | Role |
|-------------|-----------|------|
| `architect` | Architect | Vault Structure & Setup |
| `scribe` | Scribe | Text Capture |
| `sorter` | Sorter | Inbox Triage |
| `seeker` | Seeker | Search & Retrieval |
| `connector` | Connector | Knowledge Graph |
| `librarian` | Librarian | Vault Maintenance |
| `transcriber` | Transcriber | Audio & Transcription |
| `postman` | Postman | Email & Calendar |
| `food-coach` | Food Coach | Nutrition & Diet |
| `wellness-guide` | Wellness Guide | Mental Health |

---

## Philosophy

This project is built for people who are already overwhelmed. Contributions should make things **simpler**, not more complex.

When in doubt, ask: *"Does this make life easier for someone who's barely keeping it together?"*

If yes, it belongs here.

---

## Code of conduct

Be kind. This project touches on health, mental wellness, and personal struggle. Treat contributors and users with the same care you'd want when you're not at your best.
