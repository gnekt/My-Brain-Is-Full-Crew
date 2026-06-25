---
type: wiki/governance
title: Wiki MCP Server — Read-Only Mount
purpose: paste-ready mcp/servers.yaml block + the closed-world dispatcher amendment it requires
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

## Config — Add to `mcp/servers.yaml`

The Crew centralises MCP servers in `mcp/servers.yaml` at the repo root.
Append a new entry to the `servers:` list:

```yaml
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
    exclude: []
  - name: Google-Calendar
    type: http
    url: "https://gcal.mcp.claude.com/mcp"
    env: {}
    exclude: []
  - name: Wiki
    type: stdio
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem@<pinned>", "--readonly", "references/wiki"]
    env: {}
    exclude: []
```

The `args` path is `references/wiki` and is relative to the vault root — where
`mcp/servers.yaml` lives and where the server process is launched. The exact
YAML key shape (top-level `servers:` vs nested) follows the current
`mcp/servers.yaml` schema — adapt to whatever your installed platform version
parses.

---

## The Closed-World Dispatcher Constraint

The Crew dispatcher runs a **closed world** on MCP. The live `DISPATCHER.md`
states, under *ABSOLUTE CONSTRAINT: ONLY skills and agents from THIS project*:

> NEVER USE: External plugins, third-party tools, or MCP servers not defined
> here … If something is not defined in this project's files, IT DOES NOT
> EXIST.

So adding the `Wiki` server to `mcp/servers.yaml` alone is **not enough** — the
dispatcher would still refuse to touch it. Enabling the mount requires two
more coordinated edits:

1. **Amend `DISPATCHER.md` → *ABSOLUTE CONSTRAINT*** so the `Wiki` MCP server
   is named as an approved MCP server (alongside Gmail and Google-Calendar).
   Without this, the closed-world rule kills it.
2. **Add a one-line retrieval-fallback note** beside the Wiki-memory routing
   block in `DISPATCHER.md` (see `index.md` → *Dispatcher Routing*): the Wiki
   is also readable via the `Wiki` MCP server.

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
