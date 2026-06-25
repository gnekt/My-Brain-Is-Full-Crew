---
type: wiki/governance
title: Wiki MCP Server — Read-Only Mount
purpose: paste-ready .mcp.json block + the closed-world dispatcher amendment it requires
updated: 2026-06-25
---

# Wiki MCP Server — Read-Only Mount

Optional. The mount exposes the Wiki directory tree as an MCP resource so any
agent can read it via the `Wiki` MCP server. It is a **scoped retrieval
fallback** (large / sparse lookups), not a compiled-context replacement —
agents still consult `index.md` first and follow `[[wikilinks]]` on demand.

| Surface | Who | How |
|---------|-----|-----|
| **MCP mount** (this file) | Every agent, **read-only** | `@modelcontextprotocol/server-filesystem --readonly` |
| **Compiled writes** | `/wiki-ingest`, `/wiki-audit` only | Their own filesystem tools — **not** via MCP |

---

## The Key Rule

The filesystem server is mounted `--readonly`. That makes **every** MCP access
a read — for every agent, with no per-skill ACL needed. Writes go around MCP
via the two skills' own filesystem tools, which `index.md` → *Routing Rules*
already gates to them alone.

> **Never mount the Wiki filesystem server without `--readonly`.** Without it,
> any agent could write via MCP, bypassing the snapshot/patch/provenance
> discipline and breaking reversibility.

**Pin the server version** in production (e.g. `@modelcontextprotocol/server-filesystem@<pinned>`)
— `npx -y` resolves the latest tag each run, which is a supply-chain surface.

---

## Config — Flat Layout

The vault ships `.mcp.json` at the vault root with HTTP-type servers (Gmail,
Google Calendar). The filesystem server is a **stdio** server, so it uses
`command`/`args` instead of `url`. **Merge** the `Wiki` key in alongside the
existing entries — do not overwrite the file:

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

The path is `references/wiki` and is relative to the vault root — where
`.mcp.json` lives and where the server process is launched.

---

## The Closed-World Dispatcher Constraint

The Crew dispatcher runs a **closed world** on MCP. The live `CLAUDE.md`
states, under *ABSOLUTE CONSTRAINT: ONLY agents from THIS project*:

> NEVER USE: External plugins, third-party tools, skills, or MCP servers not
> defined here … If something is not defined in this project's files, IT DOES
> NOT EXIST.

So adding the Wiki server to `.mcp.json` alone is **not enough** — the
dispatcher would still refuse to touch it. Enabling the mount requires two
more coordinated edits:

1. **Amend `CLAUDE.md` → *ABSOLUTE CONSTRAINT*** so the `Wiki` MCP server is
   named as an approved MCP server (alongside Gmail and Google Calendar).
   Without this, the closed-world rule kills it.
2. **Add a one-line retrieval-fallback note** beside the Wiki-memory routing
   block in `CLAUDE.md` (see `index.md` → *Dispatcher Routing*): the Wiki is
   also readable via the `Wiki` MCP server.

If the host platform is not MCP-capable, or the closed-world amendment is not
desired, **skip this entirely** — every agent can already read the Wiki
directly via its filesystem tools under the per-agent budget. The MCP mount
is convenience and scoping, not a dependency.

---

## How Agents Should Use the Mount

The mount changes nothing about `index.md` → *Routing Rules*:

1. **First** — read `index.md`, follow only the relevant `[[wikilinks]]`.
2. **Only if** the corpus is large, the needed slice is scattered, or a
   programmatic file listing/read is easier than guessing paths — query the
   `Wiki` MCP server.
3. **Never** write via MCP, and never use the mount to bypass the context
   budget (a full-corpus dump through MCP is the same attention-dilution /
   cost problem as a full-corpus load).

The mount intentionally exposes the **entire** Wiki subtree read-only,
including `inbox/` (raw captures) and `.history/` (snapshots + lint diffs) —
both are legitimate read targets (an agent may consult a prior snapshot or a
raw capture for provenance); read-only exposure is harmless.
