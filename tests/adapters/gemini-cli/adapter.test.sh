#!/usr/bin/env bash
# Tests for adapters/gemini-cli/adapter.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT/adapters/lib.sh"
source "$ROOT/adapters/gemini-cli/adapter.sh"

test_gemini_translate_dispatcher_renames_to_gemini_md() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  echo "# Dispatcher content" > "$src/DISPATCHER.md"
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  local result=0
  [[ -f "$dst/GEMINI.md" ]] || { echo "GEMINI.md not created"; result=1; }
  [[ ! -f "$dst/CLAUDE.md" ]] || { echo "CLAUDE.md should not exist"; result=1; }
  [[ ! -f "$dst/AGENTS.md" ]] || { echo "AGENTS.md should not exist"; result=1; }
  [[ "$(cat "$dst/GEMINI.md")" == "$(cat "$src/DISPATCHER.md")" ]] || { echo "content mismatch"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_references_copies_md_files() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/references"
  echo "ref1" > "$src/references/one.md"
  echo "ref2" > "$src/references/two.md"
  adapter_translate_references "$src/references" "$dst"
  local result=0
  [[ -f "$dst/.gemini/references/one.md" ]] || { echo "one.md missing"; result=1; }
  [[ -f "$dst/.gemini/references/two.md" ]] || { echo "two.md missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_skills_copies_skill_md() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/foo" "$src/skills/bar"
  cat > "$src/skills/foo/SKILL.md" <<'HEREDOC'
---
name: foo
description: Foo skill
---
body
HEREDOC
  cat > "$src/skills/bar/SKILL.md" <<'HEREDOC'
---
name: bar
description: Bar skill
---
body
HEREDOC
  adapter_translate_skills "$src/skills" "$dst"
  local result=0
  [[ -f "$dst/.gemini/skills/foo/SKILL.md" ]] || { echo "foo missing"; result=1; }
  [[ -f "$dst/.gemini/skills/bar/SKILL.md" ]] || { echo "bar missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_skills_honors_exclude() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/foo"
  cat > "$src/skills/foo/SKILL.md" <<'HEREDOC'
---
name: foo
description: Foo
exclude: [gemini-cli]
---
HEREDOC
  adapter_translate_skills "$src/skills" "$dst"
  local result=0
  [[ ! -f "$dst/.gemini/skills/foo/SKILL.md" ]] || { echo "foo should be excluded"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_agents_basic() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/scribe.md" <<'HEREDOC'
---
name: scribe
description: Test scribe
model: mid
capabilities: [read, write, edit]
---

You are the Scribe.
HEREDOC
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.gemini/agents/scribe.md"
  local result=0
  [[ -f "$out" ]] || { echo "agent file missing"; result=1; }
  grep -q '^name: scribe' "$out" || { echo "name missing"; result=1; }
  grep -q '^model: gemini-2.5-flash' "$out" || { echo "model not mapped"; cat "$out"; result=1; }
  grep -q '^ *- read_file' "$out" || { echo "read_file tool missing"; cat "$out"; result=1; }
  grep -q '^ *- write_file' "$out" || { echo "write_file tool missing"; result=1; }
  grep -q '^ *- replace' "$out" || { echo "replace tool missing"; result=1; }
  grep -q '^ *- grep_search' "$out" || { echo "grep_search tool missing"; result=1; }
  grep -q '^You are the Scribe' "$out" || { echo "body missing"; result=1; }
  grep -q '^capabilities:' "$out" && { echo "capabilities should be dropped"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_agents_supports_crlf_frontmatter() {
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
    'capabilities: [read, write, edit]' \
    '---' \
    '' \
    'You are the Scribe.' > "$src/agents/scribe.md"
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.gemini/agents/scribe.md"
  local result=0
  grep -q '^name: scribe' "$out" || { echo "name missing"; result=1; }
  grep -q '^description: >' "$out" || { echo "description header missing"; result=1; }
  grep -q '^  Test scribe' "$out" || { echo "description continuation missing"; result=1; }
  grep -q '^model: gemini-2.5-flash' "$out" || { echo "model not mapped from CRLF frontmatter"; result=1; }
  grep -q '^ *- read_file' "$out" || { echo "tools not mapped from CRLF capabilities"; result=1; }
  grep -q '^You are the Scribe' "$out" || { echo "body missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_agents_bash_capability() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/architect.md" <<'HEREDOC'
---
name: architect
description: Test arch
model: high
capabilities: [read, write, edit, bash]
---

body
HEREDOC
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.gemini/agents/architect.md"
  local result=0
  grep -q '^ *- run_shell_command' "$out" || { echo "run_shell_command missing"; result=1; }
  grep -q '^model: gemini-2.5-pro' "$out" || { echo "model not mapped to pro"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_agents_dedupes_tools() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/seeker.md" <<'HEREDOC'
---
name: seeker
description: Search
model: mid
capabilities: [read]
---

body
HEREDOC
  adapter_translate_agents "$src/agents" "$dst"
  local out="$dst/.gemini/agents/seeker.md"
  local count; count="$(grep -c '^ *- read_file' "$out")"
  rm -rf "$src" "$dst"
  [[ "$count" == "1" ]] || { echo "expected 1 read_file, got $count"; return 1; }
}

test_gemini_translate_hooks_creates_files() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/hooks"
  cat > "$src/hooks/protect.hook.yaml" <<'HEREDOC'
name: protect
script: protect.sh
triggers:
  - event: before-tool-use
    match-tool: [edit, write]
HEREDOC
  echo '#!/usr/bin/env bash' > "$src/hooks/protect.sh"
  adapter_translate_hooks "$src/hooks" "$dst"
  local result=0
  [[ -f "$dst/.gemini/hooks/protect.sh" ]] || { echo "protect.sh not copied"; result=1; }
  [[ -f "$dst/.gemini/hooks/protect-wrapper.sh" ]] || { echo "wrapper not created"; result=1; }
  [[ -f "$dst/.gemini/_hooks.json" ]] || { echo "_hooks.json not created"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_hooks_json_has_entries() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/hooks"
  cat > "$src/hooks/protect.hook.yaml" <<'HEREDOC'
name: protect
script: protect.sh
triggers:
  - event: before-tool-use
    match-tool: [edit, write]
HEREDOC
  echo '#!/usr/bin/env bash' > "$src/hooks/protect.sh"
  adapter_translate_hooks "$src/hooks" "$dst"
  local json="$dst/.gemini/_hooks.json"
  local result=0
  jq -e '.hooks.BeforeTool' "$json" >/dev/null || { echo "BeforeTool event missing"; result=1; }
  jq -e '.hooks.BeforeTool[0].matcher' "$json" >/dev/null || { echo "matcher missing"; result=1; }
  local matcher; matcher="$(jq -r '.hooks.BeforeTool[0].matcher' "$json")"
  [[ "$matcher" == *"replace"* ]] || { echo "replace not in matcher: $matcher"; result=1; }
  [[ "$matcher" == *"write_file"* ]] || { echo "write_file not in matcher: $matcher"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_hooks_no_hooks_is_noop() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  adapter_translate_hooks "$src/hooks" "$dst"
  local result=0
  [[ ! -f "$dst/.gemini/_hooks.json" ]] || { echo "should not create hooks json when no hooks dir"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_mcp_remote() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp" "$dst/.gemini"
  cat > "$src/mcp/servers.yaml" <<'HEREDOC'
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
HEREDOC
  adapter_translate_mcp "$src/mcp" "$dst"
  local json="$dst/.gemini/_mcp.json"
  local result=0
  [[ -f "$json" ]] || { echo "_mcp.json missing"; result=1; }
  jq -e '.mcpServers.Gmail.url == "https://gmail.mcp.claude.com/mcp"' "$json" >/dev/null || { echo "url wrong"; cat "$json"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_translate_mcp_local() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp" "$dst/.gemini"
  cat > "$src/mcp/servers.yaml" <<'HEREDOC'
servers:
  - name: gmail
    type: local
    command: [npx, -y, "@anthropic-ai/gmail-mcp"]
    env: {}
HEREDOC
  adapter_translate_mcp "$src/mcp" "$dst"
  local json="$dst/.gemini/_mcp.json"
  local result=0
  jq -e '.mcpServers.gmail.command == "npx"' "$json" >/dev/null || { echo "command wrong"; cat "$json"; result=1; }
  jq -e '.mcpServers.gmail.args | length > 0' "$json" >/dev/null || { echo "args missing"; cat "$json"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_gemini_adapter_build_end_to_end() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"

  echo "# Dispatcher" > "$src/DISPATCHER.md"
  mkdir -p "$src/agents" "$src/hooks" "$src/skills/onboarding" "$src/references" "$src/mcp"
  cat > "$src/agents/scribe.md" <<'HEREDOC'
---
name: scribe
description: Test scribe
model: mid
capabilities: [read, write, edit]
---

body
HEREDOC
  cat > "$src/hooks/protect.hook.yaml" <<'HEREDOC'
name: protect
script: protect.sh
triggers:
  - event: before-tool-use
    match-tool: [edit]
HEREDOC
  echo "#!/usr/bin/env bash" > "$src/hooks/protect.sh"
  cat > "$src/skills/onboarding/SKILL.md" <<'HEREDOC'
---
name: onboarding
description: Onboarding skill
---
body
HEREDOC
  echo "reference content" > "$src/references/policy.md"
  cat > "$src/mcp/servers.yaml" <<'HEREDOC'
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
HEREDOC

  adapter_build "$src" "$dst"

  local result=0
  [[ -f "$dst/GEMINI.md" ]]                              || { echo "GEMINI.md missing"; result=1; }
  [[ -f "$dst/.gemini/agents/scribe.md" ]]               || { echo "agent missing"; result=1; }
  [[ -f "$dst/.gemini/skills/onboarding/SKILL.md" ]]     || { echo "skill missing"; result=1; }
  [[ -f "$dst/.gemini/references/policy.md" ]]           || { echo "reference missing"; result=1; }
  [[ -f "$dst/.gemini/hooks/protect.sh" ]]               || { echo "hook script missing"; result=1; }
  [[ -f "$dst/.gemini/hooks/protect-wrapper.sh" ]]       || { echo "wrapper missing"; result=1; }
  [[ -f "$dst/.gemini/settings.json" ]]                  || { echo "settings.json missing"; result=1; }
  jq -e '.hooks' "$dst/.gemini/settings.json" >/dev/null || { echo "hooks missing from settings.json"; result=1; }
  jq -e '.mcpServers' "$dst/.gemini/settings.json" >/dev/null || { echo "mcpServers missing from settings.json"; result=1; }
  [[ ! -f "$dst/.gemini/_hooks.json" ]] || { echo "_hooks.json should be cleaned up"; result=1; }
  [[ ! -f "$dst/.gemini/_mcp.json" ]] || { echo "_mcp.json should be cleaned up"; result=1; }

  rm -rf "$src" "$dst"
  return $result
}
