# Orchestra

Named scripts that wrap common agent operations into single, permission-friendly commands.

## Why

Claude Code prompts the user for permission on every novel Bash command. When agents run inline pipelines (e.g., `hey box imbox --json | python3 -c "..."`) each unique pipeline triggers a prompt. Named scripts at known paths can be added to the permission allowlist once and run silently forever.

## Installation

The installer (`scripts/launchme.sh`) copies these to `Meta/scripts/` inside your vault. They derive their vault path from their own location, so no configuration is needed.

After installation, add these to your Claude Code settings (`~/.claude/settings.json`) under `permissions.allow`:

```json
"Bash(Meta/scripts/hey-imbox:*)",
"Bash(Meta/scripts/hey-feed:*)",
"Bash(Meta/scripts/hey-trail:*)",
"Bash(Meta/scripts/hey-later:*)",
"Bash(Meta/scripts/hey-thread:*)",
"Bash(Meta/scripts/hey-seen:*)",
"Bash(Meta/scripts/hey-check:*)",
"Bash(Meta/scripts/tracker-today:*)",
"Bash(Meta/scripts/tracker-recent:*)",
"Bash(Meta/scripts/tracker-search:*)",
"Bash(Meta/scripts/tracker-mailbox:*)",
"Bash(Meta/scripts/vault-stats:*)",
"Bash(Meta/scripts/vault-inbox:*)",
"Bash(Meta/scripts/contact-lookup:*)"
```

## Scripts

### Hey Mailbox Scripts

These wrap `hey` CLI commands into table-formatted output.

| Script | Usage | Description |
|--------|-------|-------------|
| `hey-imbox` | `hey-imbox [--json]` | List Imbox (screened-in, high priority) |
| `hey-feed` | `hey-feed [--json]` | List Feed (newsletters, notifications) |
| `hey-trail` | `hey-trail [--json]` | List Paper Trail (receipts, financial) |
| `hey-later` | `hey-later [--json]` | List Reply Later / Set Aside |
| `hey-thread` | `hey-thread <id>` | Read a specific thread by posting ID |
| `hey-seen` | `hey-seen <id>` | Mark a posting as seen |

### Tracker Scripts

These query the local `Meta/hey-tracker.jsonl` file. No API calls, instant results, full history.

The tracker is populated by a cron job running `hey-poll.sh` (see the Hey poller setup docs).

| Script | Usage | Description |
|--------|-------|-------------|
| `hey-check` | `hey-check [days] [--search query] [--all]` | General tracker query (default: last 2 days) |
| `tracker-today` | `tracker-today [--mailbox box] [--json]` | Today's entries only |
| `tracker-recent` | `tracker-recent [hours] [--mailbox box] [--json]` | Last N hours (default 24) |
| `tracker-search` | `tracker-search <query> [--mailbox box] [--json]` | Full-text search across all history |
| `tracker-mailbox` | `tracker-mailbox <box> [days] [--json]` | Filter by mailbox + time window |
| `contact-lookup` | `contact-lookup <name>` | All emails from/to a specific person |

### Vault Scripts

| Script | Usage | Description |
|--------|-------|-------------|
| `vault-stats` | `vault-stats` | Note counts by folder, recent activity |
| `vault-inbox` | `vault-inbox [--count]` | List inbox notes (or just count them) |

## Requirements

- **Hey scripts**: require `hey` CLI installed and authenticated
- **Tracker scripts**: require `Meta/hey-tracker.jsonl` to exist (populated by the Hey poller cron job)
- **Vault scripts**: work with any vault, no dependencies
- All scripts require Python 3 (available by default on macOS)

## Path Resolution

Scripts derive the vault root from their own location. They expect to be installed at `Meta/scripts/` inside the vault:

```
your-vault/
  Meta/
    scripts/        <-- scripts live here
      hey-imbox
      tracker-today
      ...
    hey-tracker.jsonl
  00-Inbox/
  01-Projects/
  ...
```
