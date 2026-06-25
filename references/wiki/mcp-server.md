---
type: wiki/governance
title: Wiki MCP Server — Read-Only Mount Spec
purpose: single source of truth for mounting the Wiki as an MCP resource (scoped retrieval, not compiled-context replacement)
updated: 2026-06-25 01:45
sources:
  - "[[.overnight/PLAN.md]] §3.6 (Phase 5 — MCP Server Configuration)"
  - "[[.overnight/PLAN.md]] §2 (compiled-wiki-first, retrieval-when-needed)"
status: active
---

# Wiki MCP Server — Read-Only Mount

This document is the **single source of truth** for exposing the LLM Wiki as an
MCP resource. It carries the exact paste-ready server config for both layouts
and the rules that keep the mount safe. PLAN §3.6 calls this **Optional,
Read-Heavy by Default**.

It resolves the source proposal's self-contradiction (the source declared RAG
obsolete, then prescribed MCP mounting for scale) the same way the rest of the
Wiki does: MCP-mounted reads are a **scoped retrieval mechanism** — they sit
alongside search, embeddings, and `Meta/agent-messages.md`, they do **not**
replace compiled context. Agents still consult `index.md` first and follow
`[[wikilinks]]` on demand (`context-injection.md`); the MCP mount is the
fallback read surface for large / stale / sparse lookups.

| Surface | Who | How |
|---------|-----|-----|
| **MCP mount** (this file) | Every agent, **read-only** | `@modelcontextprotocol/server-filesystem --readonly` |
| **Compiled writes** | `/wiki-ingest`, `/wiki-audit` only | Their own filesystem tools — **not** via MCP |

---

## The Key Rule — Read-Only for Everyone, Writes Go Around MCP

The filesystem server is mounted `--readonly`. That makes **every** MCP access
a read — for every agent, with no per-skill ACL needed. PLAN §3.6's "write
access is restricted to the ingest and audit skills" is therefore enforced by
construction: **MCP cannot write at all.** The two writer skills write via
their normal agent filesystem tools (the same tools every Crew skill uses),
which `index.md` → *Routing Rules* already gates to them alone.

So: do **not** look for a "write-enable this skill on the MCP server" knob —
there is none, and there should not be one. The mount is the read surface;
writes are a separate, already-gated path. This is the cleanest way to honour
"only the two skills write" without inventing an ACL layer the source never
specified.

> The single hardest rule of this file: **never mount the Wiki filesystem
> server without `--readonly`.** Without it, any agent could write via MCP,
> bypassing the snapshot/patch/provenance discipline and breaking
> reversibility.

---

## Config — Canonical Layout (Codex CLI, TOML)

PLAN §3.6 verbatim. Add to the host's Codex MCP config (commonly
`~/.codex/config.toml`, or the project-local equivalent your Codex version
reads):

```toml
[mcp.servers.wiki]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "--readonly", ".codex/references/wiki"]
```

> **Path & key notes.** The final arg is the Wiki root relative to wherever
> the server process is launched (your repo / session root). The table key
> (`mcp.servers.wiki` vs `mcp_servers.wiki`) is version-dependent in Codex —
> use whichever your Codex CLI version parses, and keep the name `wiki`.

## Config — Flat Layout (Claude Code, `.mcp.json`)

The vault `My-Brain-Is-Full-Crew` already ships `.mcp.json` at the vault root
with HTTP-type servers (Gmail, Google Calendar). The filesystem server is a
**stdio** server, so it uses `command`/`args` instead of `url`. **Merge** the
`Wiki` key in alongside the existing entries — do not overwrite the file:

```json
{
  "mcpServers": {
    "Gmail": {
      "type": "http",
      "url": "https://gmail.mcp.claude.com/mcp"
    },
    "Google Calendar": {
      "type": "http",
      "url": "https://gcal.mcp.claude.com/mcp"
    },
    "Wiki": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "--readonly", "references/wiki"]
    }
  }
}
```

The path is `references/wiki` (no `.codex/` prefix on the flat layout) and is
relative to the vault root — where `.mcp.json` lives and where the server
process is launched.

---

## The Closed-World Dispatcher Constraint (must-read before enabling)

The Crew dispatcher runs a **closed world** on MCP. The live `CLAUDE.md`
states, under *ABSOLUTE CONSTRAINT: ONLY agents from THIS project*:

> NEVER USE: External plugins, third-party tools, skills, or MCP servers not
> defined here … If something is not defined in this project's files, IT DOES
> NOT EXIST.

So adding the Wiki server to `.mcp.json` alone is **not enough** — the
dispatcher would still refuse to touch it. Enabling the mount therefore
requires three coordinated edits:

1. **`.mcp.json`** — add the `Wiki` entry above (flat) / the TOML block
   (canonical).
2. **Dispatcher allowlist** — amend the *ABSOLUTE CONSTRAINT* section so the
   Wiki MCP server is named as an approved MCP server (alongside Gmail and
   Google Calendar). Without this, the closed-world rule kills it.
3. **Dispatcher routing** — add a one-line note next to the Wiki-memory
   routing block in `dispatcher-routing.md` (and the pasted block in
   `CLAUDE.md` / `AGENTS.md`) saying the Wiki is also readable via the `Wiki`
   MCP server as a scoped retrieval fallback. This keeps the dispatcher prose
   consistent with the mount existing.

> PLAN §3.6 marks MCP **Optional**. If the host platform is not MCP-capable,
> or the closed-world amendment is not desired, **skip this phase entirely** —
> every agent can already read the Wiki directly via its filesystem tools
> under its context budget (`context-injection.md`). The MCP mount is
> convenience and scoping, not a dependency.

---

## How Agents Should Use the Mount

The mount is a **retrieval fallback**, not the primary access path. It changes
nothing about `context-injection.md`:

1. **First** — read `index.md`, follow only the relevant `[[wikilinks]]`.
2. **Only if** the corpus is large, the needed slice is scattered, or a
   programmatic file listing/read is easier than guessing paths — query the
   `Wiki` MCP server (it exposes the directory tree and file contents of
   `references/wiki/`).
3. **Never** write via MCP, and never use the mount to bypass the context
   budget (a full-corpus dump through MCP is the same attention-dilution /
   cost problem as a full-corpus load — see `context-injection.md`).

The mount intentionally exposes the **entire** Wiki subtree read-only,
including `inbox/` (raw captures) and `.history/` (snapshots + lint diffs).
Both are legitimate read targets (an agent may consult a prior snapshot or a
raw capture for provenance); read-only exposure is harmless.

---

## Security & Supply-Chain Notes

- **`--readonly` is mandatory** — see *The Key Rule*. Dropping it is the one
  change that breaks the whole write-discipline.
- **Pin the server version** in any production install. `npx -y` resolves the
  latest tag each run, which is convenient but a supply-chain surface. Prefer
  `@modelcontextprotocol/server-filesystem@<pinned-version>` in `args` for a
  fixed, reviewable dependency.
- **Plaintext personal data** — the Wiki is compiled memory about the user's
  projects, people, and preferences. The mount keeps it on the local
  filesystem (the filesystem MCP server does not transmit data off-device),
  consistent with the Crew's existing data stance. Do not point the server at
  anything outside the Wiki root.
- **Scope the path** — the final arg must be the Wiki root and only the Wiki
  root. Mounting the whole vault would expose every note to the MCP read API
  for no benefit; the Wiki root is the curated, compiled surface.

---

## Wiring — How to Apply

### On the canonical layout (Codex CLI)
1. Add the TOML block to the Codex MCP config.
2. Add a one-line entry to the dispatcher's MCP allowlist naming `wiki`.

### On the flat layout (Claude Code, vault `My-Brain-Is-Full-Crew`)
1. Merge the `Wiki` key into the existing `.mcp.json` (do not overwrite the
   Gmail/Calendar entries).
2. Amend `CLAUDE.md` → *ABSOLUTE CONSTRAINT* to name `Wiki` as an approved
   MCP server (this is the closed-world amendment the live dispatcher
   requires).
3. Add a one-line retrieval-fallback note beside the Wiki-memory routing
   block (see `dispatcher-routing.md`).

### In the agent directory (`references/agents.md` on the flat layout)
No per-agent change is required — the mount is available to all agents
read-only and governed by the per-agent context budget already recorded in
`context-injection.md`.

---

## What NOT to do

- Do **not** mount without `--readonly`. This is non-negotiable; it is the
  only thing keeping writes gated to the two skills.
- Do **not** treat the MCP mount as the primary Wiki access path. Agents read
  `index.md` first; the mount is a scoped retrieval fallback
  (`context-injection.md`).
- Do **not** point the server outside the Wiki root, and do **not** mount the
  whole vault.
- Do **not** assume `.mcp.json` alone enables the server — the dispatcher's
  closed-world constraint (`CLAUDE.md` → *ABSOLUTE CONSTRAINT*) must be
  amended too, or the server is invisible to the Crew.
- Do **not** add a "write" capability to the mount for "convenience". If a
  skill needs to write, it writes via its filesystem tools through
  `/wiki-ingest` / `/wiki-audit`, never via MCP.

---

## Consistency & Maintenance

- **This file** owns the Wiki MCP server config and the read-only rule — edit
  the server block here, not in scattered configs.
- **`context-injection.md`** names "MCP reads" as a retrieval fallback; this
  file is the source of truth for what that read surface is and how it is
  configured. The two agree: the mount never replaces compiled context.
- **`dispatcher-routing.md`** owns dispatcher-level routing; the closed-world
  amendment (naming `Wiki` as an approved MCP server) is the dispatcher-side
  companion to this file's config block.
- **`index.md`** *Related Skills & Governance* points here so there is one
  entry point, no orphan.
- When `/wiki-audit` (Phase 4) runs, it can flag any agent attempting a write
  through the MCP surface (there should be none — `--readonly` blocks it), as
  a guard that the mount has not been reconfigured unsafely.
