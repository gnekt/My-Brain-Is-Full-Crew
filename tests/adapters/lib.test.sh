#!/usr/bin/env bash
# Tests for adapters/lib.sh
# Source the lib under test
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/adapters/lib.sh"

# Test functions will be added in subsequent tasks.
# Each function must be named test_* to be auto-discovered by tests/run.sh.

test_parse_frontmatter_scalar() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
description: Text Capture
model: sonnet
---
body content
EOF
  local result; result="$(parse_frontmatter "$fixture" name)"
  rm "$fixture"
  [[ "$result" == "scribe" ]] || { echo "expected 'scribe', got '$result'"; return 1; }
}

test_parse_frontmatter_and_body_support_crlf() {
  local fixture; fixture="$(mktemp)"
  printf '%s\r\n' \
    '---' \
    'name: architect' \
    'model: high' \
    'capabilities: [read, write]' \
    '---' \
    'You are the Architect.' > "$fixture"
  local name model capabilities body
  name="$(parse_frontmatter "$fixture" name)"
  model="$(parse_frontmatter "$fixture" model)"
  capabilities="$(parse_capabilities "$fixture")"
  body="$(agent_body "$fixture")"
  rm "$fixture"
  local result=0
  [[ "$name" == "architect" ]] || { echo "expected name architect, got '$name'"; result=1; }
  [[ "$model" == "high" ]] || { echo "expected model high, got '$model'"; result=1; }
  [[ "$capabilities" == "read write" ]] || { echo "expected capabilities 'read write', got '$capabilities'"; result=1; }
  [[ "$body" == "You are the Architect." ]] || { echo "expected CRLF body, got '$body'"; result=1; }
  return $result
}

test_parse_frontmatter_list() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
capabilities: [read, write, edit]
---
EOF
  local result; result="$(parse_frontmatter "$fixture" capabilities)"
  rm "$fixture"
  [[ "$result" == "[read, write, edit]" ]] || { echo "expected '[read, write, edit]', got '$result'"; return 1; }
}

test_parse_frontmatter_missing_key() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
---
EOF
  local result; result="$(parse_frontmatter "$fixture" nonexistent)"
  rm "$fixture"
  [[ -z "$result" ]] || { echo "expected empty, got '$result'"; return 1; }
}

test_parse_capabilities_normal() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
capabilities: [read, write, edit]
---
EOF
  local result; result="$(parse_capabilities "$fixture")"
  rm "$fixture"
  [[ "$result" == "read write edit" ]] || { echo "expected 'read write edit', got '$result'"; return 1; }
}

test_parse_capabilities_single() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
capabilities: [read]
---
EOF
  local result; result="$(parse_capabilities "$fixture")"
  rm "$fixture"
  [[ "$result" == "read" ]] || { echo "expected 'read', got '$result'"; return 1; }
}

test_parse_capabilities_empty() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
capabilities: []
---
EOF
  local result; result="$(parse_capabilities "$fixture")"
  rm "$fixture"
  [[ -z "$result" ]] || { echo "expected empty, got '$result'"; return 1; }
}

test_should_include_no_exclude() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
---
EOF
  if should_include "$fixture" claude-code; then
    rm "$fixture"; return 0
  else
    rm "$fixture"; echo "expected 0, got 1"; return 1
  fi
}

test_should_include_empty_exclude() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
exclude: []
---
EOF
  if should_include "$fixture" claude-code; then
    rm "$fixture"; return 0
  else
    rm "$fixture"; echo "expected 0, got 1"; return 1
  fi
}

test_should_include_excluded() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
exclude: [opencode]
---
EOF
  if should_include "$fixture" opencode; then
    rm "$fixture"; echo "expected 1, got 0"; return 1
  else
    rm "$fixture"; return 0
  fi
}

test_should_include_excluded_other_fw() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
exclude: [opencode]
---
EOF
  if should_include "$fixture" claude-code; then
    rm "$fixture"; return 0
  else
    rm "$fixture"; echo "expected 0, got 1"; return 1
  fi
}

test_parse_hook_yaml_simple() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
name: notify
script: notify.sh
triggers:
  - event: on-notification
exclude: []
EOF
  local result; result="$(parse_hook_yaml "$fixture")"
  rm "$fixture"
  [[ "$result" == *"name=notify"* ]] || { echo "missing name=notify in: $result"; return 1; }
  [[ "$result" == *"script=notify.sh"* ]] || { echo "missing script="; return 1; }
  [[ "$result" == *"event=on-notification"* ]] || { echo "missing event="; return 1; }
}

test_parse_hook_yaml_with_match() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
name: protect-system-files
script: protect-system-files.sh
triggers:
  - event: before-tool-use
    match-tool: [edit, write]
EOF
  local result; result="$(parse_hook_yaml "$fixture")"
  rm "$fixture"
  [[ "$result" == *"event=before-tool-use"* ]] || { echo "missing event"; return 1; }
  [[ "$result" == *"match-tool=edit write"* ]] || { echo "missing match-tool: $result"; return 1; }
}

test_agent_body() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
---

You are the Scribe.
You write notes.
EOF
  local result; result="$(agent_body "$fixture")"
  rm "$fixture"
  [[ "$result" == *"You are the Scribe."* ]] || { echo "missing body line 1"; return 1; }
  [[ "$result" == *"You write notes."* ]] || { echo "missing body line 2"; return 1; }
  [[ "$result" != *"name: scribe"* ]] || { echo "frontmatter leaked into body"; return 1; }
}

test_enumerate_agents() {
  local dir; dir="$(mktemp -d)"
  touch "$dir/foo.md" "$dir/bar.md" "$dir/not-an-agent.txt"
  local count; count="$(enumerate_agents "$dir" | wc -l | xargs)"
  rm -rf "$dir"
  [[ "$count" == "2" ]] || { echo "expected 2, got $count"; return 1; }
}

test_enumerate_hooks() {
  local dir; dir="$(mktemp -d)"
  touch "$dir/foo.hook.yaml" "$dir/bar.hook.yaml" "$dir/foo.sh"
  local count; count="$(enumerate_hooks "$dir" | wc -l | xargs)"
  rm -rf "$dir"
  [[ "$count" == "2" ]] || { echo "expected 2, got $count"; return 1; }
}

test_rewrite_platform_paths_replaces_both() {
  local tmp; tmp="$(mktemp)"
  cat > "$tmp" <<'HEREDOC'
See .platform/references/agent-orchestration.md for details.
The dispatcher (DISPATCHER.md) handles routing.
Files live in .platform/agents/ directory.
HEREDOC
  rewrite_platform_paths "$tmp" "claude" "CLAUDE.md"
  local result=0
  grep -q '\.claude/references/agent-orchestration.md' "$tmp" || { echo ".platform/ not rewritten"; result=1; }
  grep -q 'CLAUDE.md' "$tmp" || { echo "DISPATCHER.md not rewritten"; result=1; }
  grep -q '\.claude/agents/' "$tmp" || { echo "second .platform/ not rewritten"; result=1; }
  grep -q '\.platform/' "$tmp" && { echo ".platform/ still present"; result=1; }
  grep -q 'DISPATCHER\.md' "$tmp" && { echo "DISPATCHER.md still present"; result=1; }
  rm -f "$tmp"
  return $result
}

test_rewrite_platform_paths_opencode() {
  local tmp; tmp="$(mktemp)"
  echo 'See .platform/references/agents.md and DISPATCHER.md' > "$tmp"
  rewrite_platform_paths "$tmp" "opencode" "AGENTS.md"
  local result=0
  grep -q '\.opencode/references/agents.md' "$tmp" || { echo "not rewritten to .opencode/"; result=1; }
  grep -q 'AGENTS.md' "$tmp" || { echo "not rewritten to AGENTS.md"; result=1; }
  rm -f "$tmp"
  return $result
}

test_rewrite_platform_paths_gemini() {
  local tmp; tmp="$(mktemp)"
  echo 'See .platform/agents/scribe.md and DISPATCHER.md' > "$tmp"
  rewrite_platform_paths "$tmp" "gemini" "GEMINI.md"
  local result=0
  grep -q '\.gemini/agents/scribe.md' "$tmp" || { echo "not rewritten to .gemini/"; result=1; }
  grep -q 'GEMINI.md' "$tmp" || { echo "not rewritten to GEMINI.md"; result=1; }
  rm -f "$tmp"
  return $result
}
