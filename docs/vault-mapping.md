# Vault Mapping

The Crew adapts to your existing folder structure — you don't have to rename anything.

## How it works

During onboarding, the Architect scans your vault and asks about any ambiguous folders. It then creates `Meta/vault-map.md`, which maps logical roles to your actual folder names:

```yaml
---
inbox: 00-Inbox
projects: 01-Projects
areas: 02-Areas
resources: 03-Resources
archive: 04-Archive
people: 05-People
meetings: 06-Meetings
daily: 07-Daily
templates: Templates
meta: Meta
moc: MOC
---
```

Every agent and skill reads this file at runtime from the fixed path `Meta/vault-map.md` and resolves vault-role tokens to your actual paths before acting. Only the 11 tokens listed below are substituted — other `{{...}}` patterns (like `{{date}}`, `{{Name}}`) are template placeholders and are left unchanged.

## Customizing

Edit `Meta/vault-map.md` directly. For example, if your inbox is called `Inbox/`:

```yaml
inbox: Inbox
```

Changes take effect immediately — no restart needed.

## Available tokens

| Token | Default | Purpose |
|-------|---------|---------|
| `{{inbox}}` | `00-Inbox` | New notes land here first |
| `{{projects}}` | `01-Projects` | Active projects |
| `{{areas}}` | `02-Areas` | Life areas (Work, Health, etc.) |
| `{{resources}}` | `03-Resources` | Reference material |
| `{{archive}}` | `04-Archive` | Completed or historical notes |
| `{{people}}` | `05-People` | Person notes |
| `{{meetings}}` | `06-Meetings` | Meeting notes |
| `{{daily}}` | `07-Daily` | Daily notes |
| `{{templates}}` | `Templates` | Note templates |
| `{{meta}}` | `Meta` | Crew config files |
| `{{moc}}` | `MOC` | Maps of Content |

## If vault-map.md is missing

Each agent falls back to the defaults above and warns you once. Existing users are unaffected — the Crew works exactly as before until you run onboarding.
