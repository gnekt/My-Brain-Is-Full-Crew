---
name: contact-sync
description: >
  Sync a person to Apple Contacts. Searches by name/email, creates if missing,
  updates if info is incomplete. Designed to be called by the dispatcher after
  email interactions (drafting replies, processing emails) or on demand. Triggers:
  EN: "sync contact", "add to contacts", "save contact", "update contact", "is this person in my contacts".
  IT: "sincronizza contatto", "aggiungi ai contatti", "salva contatto", "aggiorna contatto".
  FR: "synchroniser le contact", "ajouter aux contacts", "sauvegarder le contact".
  ES: "sincronizar contacto", "agregar a contactos", "guardar contacto".
  DE: "Kontakt synchronisieren", "zu Kontakten hinzufuegen", "Kontakt speichern".
  PT: "sincronizar contato", "adicionar aos contatos", "salvar contato".
---

# Contact Sync

**Always respond to the user in their language. Match the language the user writes in.**

Sync a person's details to Apple Contacts. Search first, create if missing, update if information is incomplete.

---

## Prerequisites

This skill requires the `apple-contacts` MCP server. If the MCP tools (`mcp__apple-contacts__*`) are not available, inform the user and stop.

---

## When This Skill Runs

This skill is invoked in two ways:

1. **On demand** — the user explicitly asks to sync, add, or check a contact
2. **Chained by the dispatcher** — after email workflows (email triage, draft reply, meeting prep) when a person's details are available and should be synced to Apple Contacts

When chained, the dispatcher passes the person's details in the prompt. When invoked on demand, ask the user for the name and any details they have.

---

## Procedure

### Step 1: Collect Details

Gather as much as possible about the person:
- **Full name** (required — first and last)
- **Email address**
- **Phone number**
- **Organization / company**
- **Job title**

If invoked on demand and the user provides only a name, proceed with just the name. If chained from an email workflow, extract all available details from the email content (headers, signature, body).

### Step 2: Search Apple Contacts

Use `mcp__apple-contacts__search_contacts` with the person's name.

- If **no results**: proceed to Step 3 (Create).
- If **one result**: use `mcp__apple-contacts__get_contact` to retrieve full details. Proceed to Step 4 (Compare & Update).
- If **multiple results**: present the matches to the user and ask which one to update, or whether to create a new contact.

Also try searching by email address if the name search returns no results — the contact may exist under a different name.

### Step 3: Create New Contact

Use `mcp__apple-contacts__create_contact` with all available fields:
- `first_name` (required)
- `last_name` (required)
- `email` (if available)
- `phone` (if available)
- `organization` (if available)
- `job_title` (if available)
- `note` (if context is available — e.g., "Met via email re: Project X, April 2026")

Report what was created.

### Step 4: Compare & Update

Compare the existing contact's details against the new information:

1. **Email**: if the new email is not already on the contact, add it via `mcp__apple-contacts__update_contact`
2. **Phone**: if a new phone number is available and not already on the contact, add it
3. **Organization**: if the contact has no organization but we have one, update
4. **Job title**: if the contact has no job title but we have one, update
5. **If everything matches**: report that the contact is already up to date — no changes needed

**Important**: `update_contact` adds emails and phones (does not replace existing ones). For name, organization, and job title, it overwrites. Only update these if the contact's current value is empty or clearly outdated.

Report what was updated (or that nothing changed).

---

## Output Format

Keep output concise. Examples:

**Created:**
```
Contact created: Jane Smith (jane@example.com) — Acme Corp, Product Manager
```

**Updated:**
```
Contact updated: Jane Smith — added email jane.new@example.com
```

**Already current:**
```
Contact already up to date: Jane Smith (jane@example.com)
```

**Not found + created:**
```
No existing contact found for "Jane Smith". Created: Jane Smith (jane@example.com) — Acme Corp
```

---

## Integration with Email Workflows

When the dispatcher chains this skill after an email interaction, it should pass details like:

```
Contact sync: name="Jane Smith", email="jane@example.com", organization="Acme Corp", job_title="Product Manager", context="Email reply re: Q2 planning, 2026-04-06"
```

The skill processes this without asking the user for additional input.

---

## Error Handling

- **MCP not available**: "Apple Contacts MCP is not connected. Contact sync skipped."
- **Name only, no other details**: create the contact with just the name. Better to have a name-only contact than nothing.
- **Ambiguous match**: ask the user rather than guessing.
- **MCP call fails**: report the error and suggest the user add the contact manually.

---

## Inter-Agent Coordination

> **You do NOT communicate directly with other agents. The dispatcher handles all orchestration.**

### When to suggest another agent

- **Scribe** -> if the contact should also have a People note in the vault (`05-People/`), suggest the Scribe create one
- **Connector** -> if the new contact is mentioned in existing vault notes, suggest linking

### Output format for suggestions

```markdown
### Suggested next agent
- **Agent**: scribe
- **Reason**: New contact Jane Smith created in Apple Contacts — may also need a People note in the vault
- **Context**: Jane Smith, jane@example.com, Product Manager at Acme Corp. Context: Q2 planning email thread.
```
