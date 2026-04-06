# Changelog

All notable changes to My Brain Is Full - Crew are documented here.

---

## [Unreleased]

### Added
- `/daily-note` skill: create or open today's note with calendar events, inbox count, and pending tasks pulled in automatically.
- Pre-update and pre-reinstall backup mechanism: `updateme.sh` and `launchme.sh` now save a timestamped snapshot of `.claude/agents/`, `.claude/references/`, `.claude/skills/`, and `CLAUDE.md` to `.claude/backups/` before overwriting anything.
- Agent post-it size warning: `validate-frontmatter.sh` now warns when a `Meta/states/` file exceeds 50 lines.

### Changed
- `hooks/protect-system-files.sh`: core agent protection now uses `.core-manifest` as the authoritative list instead of a hard-coded name list. Newly added core agents are automatically protected without requiring a code change.
- `hooks/notify.sh`: sanitize `$TITLE` and `$MESSAGE` before interpolating into `osascript` to prevent AppleScript injection from crafted notification payloads.
- `scripts/updateme.sh`: custom-row extraction in `agents-registry.md` now uses `.core-manifest` to identify core agents, preventing edge cases where a custom agent name starts with a core agent name (e.g., `postman-lite`).
- `agents/seeker.md`: removed edit/update triggers (`"edit the note on"`, `"update the note"`, `"find and edit"`) from the agent description to align with its read-only toolset (`Read, Glob, Grep`). Added a note in the Modification Capabilities section directing users to the Scribe for write operations.
- `skills/onboarding/SKILL.md`: improved idempotency guard. When `Meta/user-profile.md` already exists, the user is now offered three explicit options: (a) update preferences only without recreating vault structure, (b) full re-initialization, or (c) cancel.
- `docs/DISCLAIMERS.md`: clarified that Food Coach and Wellness Guide are custom agent *examples*, not agents shipped with the core release.
- `docs/getting-started.md`: added troubleshooting note for Windows users explaining that `notify.sh` requires macOS or Linux, with a WSL2 workaround.
- `CLAUDE.md`: updated skill count from 13 to 14, added `/daily-note` routing entry.

---

## [1.0.1]

Initial public release.

- 8 core agents: Architect, Scribe, Sorter, Seeker, Connector, Librarian, Transcriber, Postman
- 13 skills: onboarding, create-agent, manage-agent, defrag, email-triage, meeting-prep, weekly-agenda, deadline-radar, transcribe, vault-audit, deep-clean, tag-garden, inbox-triage
- Hook system: notify, protect-system-files, validate-frontmatter
- Installer and updater scripts
- MCP integration for Gmail and Google Calendar
