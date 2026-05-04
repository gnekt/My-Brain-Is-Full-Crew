#!/usr/bin/env bash
# Tests for adapters/opencode/adapter.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT/adapters/lib.sh"
source "$ROOT/adapters/opencode/adapter.sh"

test_oc_translate_dispatcher_renames_to_agents_md() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  cat > "$src/DISPATCHER.md" <<'EOF'
# Dispatcher
See .platform/agents/ for agents. Consult DISPATCHER.md for rules.
EOF
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  local result=0
  [[ -f "$dst/AGENTS.md" ]]  || { echo "AGENTS.md not created"; result=1; }
  [[ ! -f "$dst/CLAUDE.md" ]] || { echo "CLAUDE.md should not exist"; result=1; }
  local content; content="$(cat "$dst/AGENTS.md")"
  [[ "$content" == *".opencode/agents/"* ]] || { echo ".opencode/agents/ not found: $content"; result=1; }
  [[ "$content" == *"AGENTS.md"* ]]         || { echo "AGENTS.md ref not rewritten: $content"; result=1; }
  [[ "$content" != *".claude/"* ]]           || { echo ".claude/ still present: $content"; result=1; }
  [[ "$content" != *"CLAUDE.md"* ]]          || { echo "CLAUDE.md still present: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_references_copies_md_files() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/references"
  echo "ref1" > "$src/references/one.md"
  echo "ref2" > "$src/references/two.md"
  adapter_translate_references "$src/references" "$dst"
  local result=0
  [[ -f "$dst/.opencode/references/one.md" ]] || { echo "one.md missing"; result=1; }
  [[ -f "$dst/.opencode/references/two.md" ]] || { echo "two.md missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_references_rewrites_paths() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/references"
  printf 'See .platform/agents/ and DISPATCHER.md for details.\n' > "$src/references/guide.md"
  adapter_translate_references "$src/references" "$dst"
  local content; content="$(cat "$dst/.opencode/references/guide.md")"
  local result=0
  [[ "$content" == *".opencode/agents/"* ]] || { echo ".opencode/agents/ not found: $content"; result=1; }
  [[ "$content" == *"AGENTS.md"* ]]          || { echo "AGENTS.md not found: $content"; result=1; }
  [[ "$content" != *".claude/"* ]]            || { echo ".claude/ still present: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_skills_copies_skill_md() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/foo" "$src/skills/bar"
  cat > "$src/skills/foo/SKILL.md" <<'SKILLEOF'
---
name: foo
description: Foo skill
---
body
SKILLEOF
  cat > "$src/skills/bar/SKILL.md" <<'SKILLEOF'
---
name: bar
description: Bar skill
---
body
SKILLEOF
  adapter_translate_skills "$src/skills" "$dst"
  local result=0
  [[ -f "$dst/.opencode/skills/foo/SKILL.md" ]] || { echo "foo missing"; result=1; }
  [[ -f "$dst/.opencode/skills/bar/SKILL.md" ]] || { echo "bar missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_skills_rewrites_paths() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/create-agent"
  cat > "$src/skills/create-agent/SKILL.md" <<'SKILLEOF'
---
name: create-agent
description: Create a new agent
---
Save to .platform/agents/ and update DISPATCHER.md.
SKILLEOF
  adapter_translate_skills "$src/skills" "$dst"
  local content; content="$(cat "$dst/.opencode/skills/create-agent/SKILL.md")"
  local result=0
  [[ "$content" == *".opencode/agents/"* ]] || { echo ".opencode/agents/ not found: $content"; result=1; }
  [[ "$content" == *"AGENTS.md"* ]]          || { echo "AGENTS.md not found: $content"; result=1; }
  [[ "$content" != *".claude/"* ]]            || { echo ".claude/ still present: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_skills_honors_exclude() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/foo"
  cat > "$src/skills/foo/SKILL.md" <<'SKILLEOF'
---
name: foo
description: Foo
exclude: [opencode]
---
SKILLEOF
  adapter_translate_skills "$src/skills" "$dst"
  local result=0
  [[ ! -f "$dst/.opencode/skills/foo/SKILL.md" ]] || { echo "foo should be excluded"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_agents_basic() {
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
  local out="$dst/.opencode/agents/scribe.md"
  local result=0
  [[ -f "$out" ]] || { echo "agent file missing"; result=1; }
  grep -q '^description: Test scribe' "$out" || { echo "description missing or wrong format"; cat "$out"; result=1; }
  grep -q '^mode: subagent' "$out" || { echo "mode missing"; result=1; }
  grep -q '^model: anthropic/claude-sonnet-4-5' "$out" || { echo "model not mapped"; result=1; }
  grep -q '^permission:' "$out" || { echo "permission block missing"; result=1; }
  grep -q '^  edit: allow' "$out" || { echo "edit permission missing"; result=1; }
  grep -q '^You are the Scribe' "$out" || { echo "body missing"; result=1; }
  grep -q '^name:' "$out" && { echo "name: should be dropped"; result=1; }
  grep -q '^capabilities:' "$out" && { echo "capabilities: should be dropped"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_agents_supports_crlf_frontmatter() {
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
  local out="$dst/.opencode/agents/scribe.md"
  local result=0
  grep -q '^description: >' "$out" || { echo "description header missing"; result=1; }
  grep -q '^  Test scribe' "$out" || { echo "description continuation missing"; result=1; }
  grep -q '^mode: subagent' "$out" || { echo "mode not parsed from CRLF frontmatter"; result=1; }
  grep -q '^model: anthropic/claude-sonnet-4-5' "$out" || { echo "model not mapped from CRLF frontmatter"; result=1; }
  grep -q '^  edit: allow' "$out" || { echo "permissions not mapped from CRLF capabilities"; result=1; }
  grep -q '^You are the Scribe' "$out" || { echo "body missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_agents_rewrites_body_paths() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/scribe.md" <<'EOF'
---
name: scribe
description: Test scribe
model: sonnet
capabilities: [read, write]
---

See .platform/references/agents.md and DISPATCHER.md for context.
EOF
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.opencode/agents/scribe.md"
  local result=0
  local content; content="$(cat "$out")"
  [[ "$content" == *".opencode/references/agents.md"* ]] || { echo ".opencode/references/ not found: $content"; result=1; }
  [[ "$content" == *"AGENTS.md"* ]]                       || { echo "AGENTS.md not found: $content"; result=1; }
  [[ "$content" != *".claude/"* ]]                        || { echo ".claude/ still present: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_agents_bash_capability() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/architect.md" <<'EOF'
---
name: architect
description: Test arch
model: high
capabilities: [read, write, edit, bash]
---

body
EOF
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.opencode/agents/architect.md"
  local result=0
  grep -q '^  edit: allow' "$out" || { echo "edit missing"; result=1; }
  grep -q '^  bash: allow' "$out" || { echo "bash missing"; result=1; }
  grep -q '^model: anthropic/claude-opus-4-5' "$out" || { echo "model not mapped"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_agents_read_only_emits_empty_permission() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/seeker.md" <<'EOF'
---
name: seeker
description: Search only
model: mid
capabilities: [read]
---

body
EOF
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.opencode/agents/seeker.md"
  local result=0
  grep -q '^permission: {}' "$out" || { echo "expected 'permission: {}'"; cat "$out"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_agents_dedupes_edit() {
  # write+edit both map to "edit: allow" — must appear once, not twice.
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/scribe.md" <<'EOF'
---
name: scribe
description: Dedupe test
model: mid
capabilities: [read, write, edit]
---

body
EOF
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.opencode/agents/scribe.md"
  local count; count="$(grep -c '^  edit: allow' "$out")"
  rm -rf "$src" "$dst"
  [[ "$count" == "1" ]] || { echo "expected 1 edit line, got $count"; return 1; }
}

test_oc_translate_hooks_copies_scripts() {
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
  [[ -f "$dst/.opencode/hooks/protect.sh" ]] || { echo "protect.sh not copied"; result=1; }
  [[ -f "$dst/.opencode/plugins/mbifc-hooks.js" ]] || { echo "mbifc-hooks.js not generated"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_hooks_registry_has_entries() {
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
  cat > "$src/hooks/notify.hook.yaml" <<'EOF'
name: notify
script: notify.sh
triggers:
  - event: on-notification
EOF
  touch "$src/hooks/protect.sh" "$src/hooks/notify.sh"
  adapter_translate_hooks "$src/hooks" "$dst"
  local plugin="$dst/.opencode/plugins/mbifc-hooks.js"
  local result=0
  grep -q '"name": "protect"' "$plugin" || { echo "protect not in registry"; result=1; }
  grep -q '"name": "notify"' "$plugin" || { echo "notify not in registry"; result=1; }
  grep -q '"event": "tool.execute.before"' "$plugin" || { echo "tool.execute.before event missing"; result=1; }
  grep -q '"event": "session.idle"' "$plugin" || { echo "session.idle event missing"; result=1; }
  grep -q '"matchTool":' "$plugin" || { echo "matchTool field missing"; result=1; }
  grep -q 'spawn("bash"' "$plugin" || { echo "bash-executor not inlined"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_hooks_no_hooks_dir_is_noop() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  # src has no hooks/ — should not error, should not create plugin file
  adapter_translate_hooks "$src/hooks" "$dst"
  local result=0
  [[ ! -f "$dst/.opencode/plugins/mbifc-hooks.js" ]] || { echo "plugin should not exist when no hooks"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_mcp_local() {
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
  local out="$dst/opencode.json"
  local result=0
  [[ -f "$out" ]] || { echo "opencode.json missing"; result=1; }
  jq -e '.mcp.gmail.type == "local"' "$out" >/dev/null || { echo "type wrong"; cat "$out"; result=1; }
  jq -e '.mcp.gmail.command | startswith("npx")' "$out" >/dev/null || { echo "command wrong"; cat "$out"; result=1; }
  jq -e '.mcp.gmail.environment == {}' "$out" >/dev/null || { echo "environment key missing"; cat "$out"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_translate_mcp_remote() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
EOF
  adapter_translate_mcp "$src/mcp" "$dst"
  local out="$dst/opencode.json"
  local result=0
  jq -e '.mcp.Gmail.type == "remote"' "$out" >/dev/null || { echo "type should be remote"; cat "$out"; result=1; }
  jq -e '.mcp.Gmail.url == "https://gmail.mcp.claude.com/mcp"' "$out" >/dev/null || { echo "url wrong"; cat "$out"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_oc_adapter_build_end_to_end() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"

  # Minimal source tree
  echo "# Dispatcher" > "$src/DISPATCHER.md"
  mkdir -p "$src/agents" "$src/hooks" "$src/skills/onboarding" "$src/references" "$src/mcp"
  cat > "$src/agents/scribe.md" <<'EOF'
---
name: scribe
description: Test scribe
model: mid
capabilities: [read, write, edit]
---

body
EOF
  cat > "$src/hooks/protect.hook.yaml" <<'EOF'
name: protect
script: protect.sh
triggers:
  - event: before-tool-use
    match-tool: [edit]
EOF
  echo "#!/usr/bin/env bash" > "$src/hooks/protect.sh"
  cat > "$src/skills/onboarding/SKILL.md" <<'EOF'
---
name: onboarding
description: Onboarding skill
---
body
EOF
  echo "reference content" > "$src/references/policy.md"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: gmail
    type: local
    command: [npx, -y, "@anthropic-ai/gmail-mcp"]
    env: {}
EOF

  adapter_build "$src" "$dst"

  local result=0
  [[ -f "$dst/AGENTS.md" ]]                                   || { echo "AGENTS.md missing"; result=1; }
  [[ -f "$dst/.opencode/agents/scribe.md" ]]                  || { echo "agent missing"; result=1; }
  [[ -f "$dst/.opencode/skills/onboarding/SKILL.md" ]]        || { echo "skill missing"; result=1; }
  [[ -f "$dst/.opencode/references/policy.md" ]]              || { echo "reference missing"; result=1; }
  [[ -f "$dst/.opencode/hooks/protect.sh" ]]                  || { echo "hook script missing"; result=1; }
  [[ -f "$dst/.opencode/plugins/mbifc-hooks.js" ]]            || { echo "plugin missing"; result=1; }
  [[ -f "$dst/opencode.json" ]]                               || { echo "opencode.json missing"; result=1; }

  rm -rf "$src" "$dst"
  return $result
}
