#!/usr/bin/env bash
# Tests for adapters/claude-code/adapter.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT/adapters/lib.sh"
source "$ROOT/adapters/claude-code/adapter.sh"

test_finalize_writes_plugin_json() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/.claude-plugin"
  echo '{"name": "test"}' > "$src/.claude-plugin/plugin.json"
  adapter_finalize "$src" "$dst"
  local result=0
  [[ -f "$dst/.claude-plugin/plugin.json" ]] || { echo "plugin.json missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_translate_mcp_basic() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: gmail
    type: local
    command: [npx, -y, "@anthropic-ai/gmail-mcp"]
    env: {}
EOF
  adapter_translate_mcp "$src/mcp" "$dst"
  local out="$dst/.mcp.json"
  local result=0
  [[ -f "$out" ]] || { echo ".mcp.json missing"; result=1; }
  jq -e '.mcpServers.gmail.command == "npx"' "$out" >/dev/null || { echo "command field wrong"; cat "$out"; result=1; }
  jq -e '.mcpServers.gmail.args == ["-y", "@anthropic-ai/gmail-mcp"]' "$out" >/dev/null || { echo "args field wrong"; cat "$out"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_translate_hooks_creates_files() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/hooks"
  cat > "$src/hooks/protect.hook.yaml" <<'EOF'
name: protect
script: protect.sh
triggers:
  - event: before-tool-use
    match-tool: [edit, write]
EOF
  cat > "$src/hooks/protect.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  adapter_translate_hooks "$src/hooks" "$dst"
  local result=0
  [[ -f "$dst/.claude/hooks/protect.sh" ]] || { echo "protect.sh missing"; result=1; }
  [[ -f "$dst/.claude/hooks/protect-wrapper.sh" ]] || { echo "wrapper missing"; result=1; }
  [[ -f "$dst/.claude/settings.json" ]] || { echo "settings.json missing"; result=1; }
  grep -q "PreToolUse" "$dst/.claude/settings.json" || { echo "PreToolUse not in settings"; result=1; }
  grep -q "Edit|Write" "$dst/.claude/settings.json" || { echo "matcher missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_translate_agents_basic() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/scribe.md" <<'EOF'
---
name: scribe
description: Test scribe
model: mid
mode: subagent
capabilities: [read, write, edit]
---

You are the Scribe.
EOF
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.claude/agents/scribe.md"
  local result=0
  [[ -f "$out" ]] || { echo "agent file missing"; result=1; }
  grep -q "^name: scribe" "$out" || { echo "name missing"; result=1; }
  grep -q "^tools: Read, Glob, Grep, Write, Edit" "$out" || { echo "tools incorrect: $(grep '^tools:' "$out")"; result=1; }
  grep -q "^You are the Scribe" "$out" || { echo "body missing"; result=1; }
  grep -q "capabilities:" "$out" && { echo "capabilities should be removed"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_translate_agents_supports_crlf_frontmatter() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  printf '%s\r\n' \
    '---' \
    'name: scribe' \
    'description: >' \
    '  Test scribe' \
    '  across line endings' \
    'model: mid' \
    'mode: subagent' \
    'capabilities: [read, write, edit]' \
    '---' \
    '' \
    'You are the Scribe.' > "$src/agents/scribe.md"
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.claude/agents/scribe.md"
  local result=0
  grep -q '^name: scribe' "$out" || { echo "name missing"; result=1; }
  grep -q '^description: >' "$out" || { echo "description header missing"; result=1; }
  grep -q '^  Test scribe' "$out" || { echo "description continuation missing"; result=1; }
  grep -q '^model: sonnet' "$out" || { echo "model not mapped from CRLF frontmatter"; result=1; }
  grep -q '^tools: Read, Glob, Grep, Write, Edit' "$out" || { echo "tools not mapped from CRLF capabilities"; result=1; }
  grep -q '^You are the Scribe' "$out" || { echo "body missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_translate_agents_bash_capability() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/architect.md" <<'EOF'
---
name: architect
description: Test
model: high
capabilities: [read, write, edit, bash]
---

body
EOF
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.claude/agents/architect.md"
  grep -q "^tools: Read, Glob, Grep, Write, Edit, Bash" "$out" || { echo "tools incorrect: $(grep '^tools:' "$out")"; rm -rf "$src" "$dst"; return 1; }
  rm -rf "$src" "$dst"
  return 0
}

test_translate_skills_copies_skill_md() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/foo" "$src/skills/bar"
  cat > "$src/skills/foo/SKILL.md" <<'EOF'
---
name: foo
description: Foo skill
---
body
EOF
  cat > "$src/skills/bar/SKILL.md" <<'EOF'
---
name: bar
description: Bar skill
---
body
EOF
  adapter_translate_skills "$src/skills" "$dst"
  local result=0
  [[ -f "$dst/.claude/skills/foo/SKILL.md" ]] || { echo "foo missing"; result=1; }
  [[ -f "$dst/.claude/skills/bar/SKILL.md" ]] || { echo "bar missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_translate_skills_excludes() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/foo"
  cat > "$src/skills/foo/SKILL.md" <<'EOF'
---
name: foo
description: Foo
exclude: [claude-code]
---
EOF
  adapter_translate_skills "$src/skills" "$dst"
  local result=0
  [[ ! -f "$dst/.claude/skills/foo/SKILL.md" ]] || { echo "foo should be excluded"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_translate_references_copies_md_files() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/references"
  echo "ref1" > "$src/references/one.md"
  echo "ref2" > "$src/references/two.md"
  adapter_translate_references "$src/references" "$dst"
  local result=0
  [[ -f "$dst/.claude/references/one.md" ]] || { echo "one.md missing"; result=1; }
  [[ -f "$dst/.claude/references/two.md" ]] || { echo "two.md missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_translate_dispatcher_renames_to_claude_md() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  cat > "$src/DISPATCHER.md" <<'EOF'
# Dispatcher
Some content
EOF
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  local result=0
  [[ -f "$dst/CLAUDE.md" ]] || { echo "CLAUDE.md not created"; result=1; }
  [[ "$(cat "$dst/CLAUDE.md")" == "$(cat "$src/DISPATCHER.md")" ]] || { echo "content mismatch"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_model_to_native_maps_tiers() {
  local result=0
  [[ "$(cc_model_to_native "low")" == "haiku" ]] || { echo "low→haiku failed"; result=1; }
  [[ "$(cc_model_to_native "mid")" == "sonnet" ]] || { echo "mid→sonnet failed"; result=1; }
  [[ "$(cc_model_to_native "high")" == "opus" ]] || { echo "high→opus failed"; result=1; }
  [[ "$(cc_model_to_native "anthropic/custom")" == "anthropic/custom" ]] || { echo "passthrough failed"; result=1; }
  return $result
}
