# PR: CVTO-GAI Refactor — Dispatcher + Sorter + Postman

## What this PR adds

A prompt engineering refactor of 3 agents using the **CVTO-GAI framework** 
(Context / Vision / Tasks / Outputs / Guardrails / Arbitration / Iteration).

This addresses the 3 structural weaknesses identified in the architecture:

1. **No programmatic dispatcher** → replaced by DISPATCH supervisor agent
2. **No output schemas** → added to Sorter and Postman
3. **No failure handling on MCP** → added to Postman (G1 guardrails)

---

## Files changed

```
.claude/agents/dispatch.md    ← NEW — Supervisor Agent & Router
.claude/agents/sorter.md      ← REFACTORED — CVTO-GAI structure
.claude/agents/postman.md     ← REFACTORED — CVTO-GAI structure
```

---

## What changed and why

### DISPATCH (new)
The original architecture relies on Claude Code's native intent-matching 
to route requests to the right agent. This works for clear requests 
but fails on ambiguous ones — wrong agent gets activated, task misfires.

DISPATCH adds an explicit **Arbitration block** — a routing table with 
confidence levels, conflict resolution rules, and multi-agent sequencing. 
Every request passes through DISPATCH first. Nothing bypasses it.

Key additions:
- Structured JSON routing payload per agent call
- Confidence levels: HIGH / MEDIUM / LOW with different routing behaviors
- Multi-agent sequencing — never activates 2 agents simultaneously
- Routing log in `Meta/agent-messages.md` with timestamps
- Startup state check — reads in-progress tasks before accepting new ones

### SORTER (refactored)
The original Sorter had the right job definition but no structured 
reasoning sequence. Without explicit confidence thresholds, a uncertain 
Sorter will guess — and misfiling your entire daily inbox is a bad day.

Key additions:
- 5-step triage sequence with per-note classification
- Confidence thresholds: LOW confidence = never move, always flag
- `Meta/sorter-review.md` for uncertain notes — human decision required
- YAML frontmatter tagging on filed notes
- Mid-session reports every 20 notes
- Explicit conflict handling with Connector agent locks

### POSTMAN (refactored)
The original Postman had no MCP failure handling. If Gmail goes down, 
the agent either crashes silently or retries in a loop. Neither is good.

Key additions:
- MCP connection check as Step 1 — always before processing
- Explicit failure modes: Gmail down / Calendar down / both down
- Sensitive data guardrail — passwords/financial data summarized, not copied
- Meeting prep note template — consistent structure across all meetings
- Duplicate detection — never overwrites existing meeting notes

---

## What's NOT changed

- Agent roles and domains — unchanged
- `Meta/agent-messages.md` coordination pattern — preserved and extended
- "Never delete, always archive" philosophy — enforced in all G1 guardrails
- The other 5 agents (Architect, Scribe, Seeker, Connector, Librarian, 
  Transcriber) — untouched in this PR, refactor available if useful

---

## About CVTO-GAI

CVTO-GAI is an open-source prompt engineering framework for complex AI agents.
Repo: https://github.com/zayonne/cvto-gai

The 7 blocks:
- **C**ontext — where the agent operates
- **V**ision — who the agent is and how it behaves  
- **T**asks — what it does and in what cognitive sequence
- **O**utputs — what it produces and with what confidence level
- **G**uardrails — what it never does (tiered G1/G2/G3)
- **A**rbitration — how it decides when options conflict
- **I**teration — how it handles feedback and tracks state

Happy to refactor the remaining 5 agents if this direction works for you.

— robdata
