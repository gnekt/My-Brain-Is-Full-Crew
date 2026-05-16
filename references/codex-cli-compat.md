---
exclude: [claude-code, gemini-cli, opencode]
---

# Codex CLI Compatibility Guide

Use this reference when source workflows mention platform-specific tools or recursion rules that do not map 1:1 to Codex CLI.

| Source concept | Codex CLI mapping | Notes |
|---|---|---|
| `AskUserQuestion` | Ask a direct plain-text question in chat and wait for the reply | Codex uses the root conversation for confirmations and follow-up questions. |
| `request_user_input` | Ask a direct plain-text question in chat and wait for the reply | Use the same root-thread confirmation flow as any other user interaction. |
| `Skill tool` | Follow the relevant skill instructions directly in the root context | Skills stay in the main chat; do not invent a separate Skill API. |
| `Agent tool` | Use `spawn_agent` only for bounded child tasks | The root context keeps orchestration and integration decisions and may continue through multiple bounded follow-up steps serially. |
| `max chain depth 3` | `agents.max_depth = 1` with root-only orchestration | This blocks deep child recursion, not root-side serial orchestration. The root can still continue obvious low-risk follow-up work one bounded child at a time. |
| `.mcp.json` | `.codex/config.toml` | Codex MCP and profile settings live in the TOML config. |

## Flattened Workflow Example

Source workflow wording:

1. Call `AskUserQuestion` for confirmation.
2. Use the `Skill tool` for the setup flow.
3. Use the `Agent tool` for a follow-up task.

Codex CLI wording:

1. Ask the user directly in chat and wait for the reply.
2. Keep the setup flow in the root context by following the skill instructions directly.
3. If a bounded side task remains, use `spawn_agent`, then let the root context continue through obvious low-risk follow-up work before returning to the user.

## Troubleshooting

- Child approvals surface in the child thread. Approve or deny there, then continue orchestration from the root context after the child returns.
- If a task would require deeper recursion, stop spawning children and flatten the next step into the root context or split the work into separate bounded child tasks.
- Offload-first does not mean forceful. The root should still stop for ambiguity, destructive edits, unsupported capabilities, or missing user preference decisions.
- Codex custom agents live in `.codex/agents/*.toml`.
- Repo-scoped Codex skills live in `.agents/skills/`.
- MCP servers, approval policy, sandbox mode, and profiles live in `.codex/config.toml`.
