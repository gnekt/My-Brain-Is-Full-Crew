#!/usr/bin/env bash
# Tests for adapters/codex-cli/adapter.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT/adapters/lib.sh"
source "$ROOT/adapters/codex-cli/adapter.sh"

# ---------------------------------------------------------------------------
# Helper: resolve python interpreter (python or python3)
# Verifies the command actually works (not a Windows Store redirect stub).
# ---------------------------------------------------------------------------
_python_cmd() {
  for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
      # Verify the candidate actually runs (Windows may have stub redirects)
      if "$candidate" -c "import sys; sys.exit(0)" >/dev/null 2>&1; then
        echo "$candidate"
        return 0
      fi
    fi
  done
  echo ""
}

# ---------------------------------------------------------------------------
# Dispatcher tests
# ---------------------------------------------------------------------------

test_cc_translate_dispatcher_renames_to_agents_md() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  cat > "$src/DISPATCHER.md" <<'EOF'
# Dispatcher
See .platform/agents/ for agents. Consult DISPATCHER.md for rules.
EOF
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  local result=0
  [[ -f "$dst/AGENTS.md" ]]   || { echo "AGENTS.md not created"; result=1; }
  [[ ! -f "$dst/CLAUDE.md" ]] || { echo "CLAUDE.md should not exist"; result=1; }
  local content; content="$(cat "$dst/AGENTS.md")"
  [[ "$content" == *".codex/agents/"* ]] || { echo ".codex/agents/ not found: $content"; result=1; }
  [[ "$content" == *"AGENTS.md"* ]]      || { echo "AGENTS.md ref not rewritten: $content"; result=1; }
  [[ "$content" != *".platform/"* ]]     || { echo ".platform/ still present: $content"; result=1; }
  [[ "$content" != *"DISPATCHER.md"* ]]  || { echo "DISPATCHER.md still present: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_dispatcher_missing_src_is_noop() {
  local dst; dst="$(mktemp -d)"
  # Should not error even when source file doesn't exist
  adapter_translate_dispatcher "/nonexistent/DISPATCHER.md" "$dst"
  local result=0
  [[ ! -f "$dst/AGENTS.md" ]] || { echo "AGENTS.md should not be created"; result=1; }
  rm -rf "$dst"
  return $result
}

# ---------------------------------------------------------------------------
# References tests
# ---------------------------------------------------------------------------

test_cc_translate_references_copies_to_codex_dir() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/references"
  echo "ref1" > "$src/references/one.md"
  echo "ref2" > "$src/references/two.md"
  adapter_translate_references "$src/references" "$dst"
  local result=0
  [[ -f "$dst/.codex/references/one.md" ]] || { echo "one.md missing"; result=1; }
  [[ -f "$dst/.codex/references/two.md" ]] || { echo "two.md missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_references_rewrites_paths() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/references"
  printf 'See .platform/agents/ and DISPATCHER.md for details.\n' > "$src/references/guide.md"
  adapter_translate_references "$src/references" "$dst"
  local content; content="$(cat "$dst/.codex/references/guide.md")"
  local result=0
  [[ "$content" == *".codex/agents/"* ]]  || { echo ".codex/agents/ not found: $content"; result=1; }
  [[ "$content" == *"AGENTS.md"* ]]       || { echo "AGENTS.md not found: $content"; result=1; }
  [[ "$content" != *".platform/"* ]]      || { echo ".platform/ still present: $content"; result=1; }
  [[ "$content" != *"DISPATCHER.md"* ]]   || { echo "DISPATCHER.md still present: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_references_honors_exclude() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/references"
  cat > "$src/references/hidden.md" <<'EOF'
---
exclude: [codex-cli]
---
secret
EOF
  adapter_translate_references "$src/references" "$dst"
  local result=0
  [[ ! -f "$dst/.codex/references/hidden.md" ]] || { echo "hidden.md should be excluded"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

# ---------------------------------------------------------------------------
# Skills tests
# ---------------------------------------------------------------------------

test_cc_translate_skills_copies_to_agents_skills_dir() {
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
  [[ -f "$dst/.agents/skills/foo/SKILL.md" ]] || { echo "foo missing"; result=1; }
  [[ -f "$dst/.agents/skills/bar/SKILL.md" ]] || { echo "bar missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_skills_rewrites_paths() {
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
  local content; content="$(cat "$dst/.agents/skills/create-agent/SKILL.md")"
  local result=0
  [[ "$content" == *".codex/agents/"* ]]  || { echo ".codex/agents/ not found: $content"; result=1; }
  [[ "$content" == *"AGENTS.md"* ]]       || { echo "AGENTS.md not found: $content"; result=1; }
  [[ "$content" != *".platform/"* ]]      || { echo ".platform/ still present: $content"; result=1; }
  [[ "$content" != *"DISPATCHER.md"* ]]   || { echo "DISPATCHER.md still present: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_skills_honors_exclude() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/secret"
  cat > "$src/skills/secret/SKILL.md" <<'SKILLEOF'
---
name: secret
description: Hidden skill
exclude: [codex-cli]
---
SKILLEOF
  adapter_translate_skills "$src/skills" "$dst"
  local result=0
  [[ ! -f "$dst/.agents/skills/secret/SKILL.md" ]] || { echo "secret should be excluded"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_skills_real_corpus_has_exact_skill_directories() {
  local dst; dst="$(mktemp -d)"
  adapter_translate_skills "$ROOT/skills" "$dst"

  local result=0
  local expected=(
    contact-sync
    create-agent
    deadline-radar
    deep-clean
    defrag
    email-triage
    inbox-triage
    manage-agent
    meeting-prep
    onboarding
    tag-garden
    transcribe
    vault-audit
    weekly-agenda
  )

  mapfile -t actual < <(find "$dst/.agents/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
  [[ "${#actual[@]}" -eq 14 ]] \
    || { echo "expected 14 generated skill directories, found ${#actual[@]}: ${actual[*]}"; result=1; }

  local idx
  for idx in "${!expected[@]}"; do
    [[ "${actual[$idx]:-missing}" == "${expected[$idx]}" ]] \
      || { echo "expected skill ${expected[$idx]} at index $idx, found ${actual[$idx]:-missing}"; result=1; }
    [[ -f "$dst/.agents/skills/${expected[$idx]}/SKILL.md" ]] \
      || { echo "missing SKILL.md for ${expected[$idx]}"; result=1; }
  done

  rm -rf "$dst"
  return $result
}

test_cc_translate_skills_rewrites_high_risk_real_skills_for_codex() {
  local dst; dst="$(mktemp -d)"
  adapter_translate_skills "$ROOT/skills" "$dst"

  local result=0
  local onboarding="$dst/.agents/skills/onboarding/SKILL.md"
  local create_agent="$dst/.agents/skills/create-agent/SKILL.md"
  local manage_agent="$dst/.agents/skills/manage-agent/SKILL.md"
  local transcribe="$dst/.agents/skills/transcribe/SKILL.md"

  local file content
  for file in "$onboarding" "$create_agent" "$manage_agent" "$transcribe"; do
    [[ -f "$file" ]] || { echo "missing generated high-risk skill: $file"; result=1; continue; }
    content="$(cat "$file")"
    [[ "$content" != *'AskUserQuestion'* ]] || { echo "AskUserQuestion leaked into $(basename "$(dirname "$file")")"; result=1; }
    [[ "$content" != *'request_user_input'* ]] || { echo "request_user_input leaked into $(basename "$(dirname "$file")")"; result=1; }
    [[ "$content" != *'.platform/'* ]] || { echo ".platform/ leaked into $(basename "$(dirname "$file")")"; result=1; }
  done

  grep -qi '\.codex/config\.toml' "$onboarding" \
    || { echo 'onboarding skill should reference .codex/config.toml'; result=1; }
  [[ "$(cat "$onboarding")" != *'.mcp.json'* ]] \
    || { echo 'onboarding skill should not mention .mcp.json'; result=1; }
  grep -q '\.codex/agents/{name}\.toml' "$create_agent" \
    || { echo 'create-agent skill should target .codex/agents/{name}.toml'; result=1; }
  grep -q '\.codex/agents/{name}\.toml' "$manage_agent" \
    || { echo 'manage-agent skill should target .codex/agents/{name}.toml'; result=1; }
  grep -qi 'ask one direct plain-text question' "$create_agent" \
    || { echo 'create-agent skill should use direct-chat question wording'; result=1; }
  grep -qi 'wait for the user.s reply before continuing' "$create_agent" \
    || { echo 'create-agent skill should tell Codex to wait for the user reply'; result=1; }
  grep -qi 'resume from the saved state file if the flow is already active' "$manage_agent" \
    || { echo 'manage-agent skill should mention saved-state resumption'; result=1; }
  grep -qi 'ask one direct plain-text question' "$transcribe" \
    || { echo 'transcribe skill should use direct-chat question wording'; result=1; }
  grep -qi 'wait for the user.s reply before continuing' "$transcribe" \
    || { echo 'transcribe skill should tell Codex to wait for the user reply'; result=1; }

  rm -rf "$dst"
  return $result
}


test_cc_real_dispatcher_marks_postman_migration_gated() {
  local dst; dst="$(mktemp -d)"
  adapter_translate_dispatcher "$ROOT/DISPATCHER.md" "$dst"

  local content; content="$(cat "$dst/AGENTS.md")"
  local result=0
  [[ "$content" == *'## Migration-Gated Units'* ]] \
    || { echo 'dispatcher should declare migration-gated units'; result=1; }
  [[ "$content" == *'`postman`'* && "$content" == *'`/email-triage`'* ]] \
    || { echo 'dispatcher should list postman and email-triage as gated'; result=1; }
  [[ "$content" == *'Migration-gated in Codex. Explain that external email/calendar integrations are not enabled yet.'* ]] \
    || { echo 'dispatcher should gate the postman fallback row'; result=1; }
  [[ "$content" != *'Calendar import, create event, targeted email/calendar search, VIP filter, email draft'* ]] \
    || { echo 'dispatcher should not keep the active postman routing copy'; result=1; }

  rm -rf "$dst"
  return $result
}

test_cc_real_registry_marks_postman_runtime_units_gated() {
  local dst; dst="$(mktemp -d)"
  adapter_translate_references "$ROOT/references" "$dst"

  local content; content="$(cat "$dst/.codex/references/agents-registry.md")"
  local result=0
  [[ "$content" == *'| postman | Email & Calendar Intelligence | Reserved for future Codex parity.'* ]] \
    || { echo 'registry should rewrite postman to migration-gated text'; result=1; }
  [[ "$content" == *'| `/email-triage` | postman '* && "$content" == *'| migration-gated |'* ]] \
    || { echo 'registry should mark email-triage as migration-gated'; result=1; }
  [[ "$content" == *'| `/meeting-prep` | postman '* && "$content" == *'meeting email/calendar enrichment is migration-gated'* ]] \
    || { echo 'registry should mark meeting-prep as migration-gated'; result=1; }
  [[ "$content" == *'**migration-gated**: Agent or skill is intentionally excluded from active Codex dispatch'* ]] \
    || { echo 'registry should document the migration-gated status value'; result=1; }

  rm -rf "$dst"
  return $result
}

test_cc_real_postman_runtime_files_have_codex_migration_gates() {
  local dst; dst="$(mktemp -d)"
  adapter_translate_agents_toml "$ROOT/agents" "$dst"
  adapter_translate_skills "$ROOT/skills" "$dst"

  local result=0
  local postman="$dst/.codex/agents/postman.toml"
  [[ -f "$postman" ]] || { echo 'missing generated postman.toml'; rm -rf "$dst"; return 1; }
  local content; content="$(cat "$postman")"
  [[ "$content" == *'Migration-gated placeholder for future email and calendar parity in Codex.'* ]] \
    || { echo 'postman description should be overridden for Codex'; result=1; }
  [[ "$content" == *'## Codex Migration Gate'* ]] \
    || { echo 'postman.toml should include a migration gate section'; result=1; }
  [[ "$content" != *'.mcp.json'* ]] \
    || { echo 'postman.toml should not mention .mcp.json'; result=1; }

  local skill
  for skill in email-triage meeting-prep weekly-agenda deadline-radar; do
    local skill_file="$dst/.agents/skills/$skill/SKILL.md"
    [[ -f "$skill_file" ]] || { echo "missing generated $skill skill"; result=1; continue; }
    content="$(cat "$skill_file")"
    [[ "$content" == *'## Codex Migration Gate'* ]] \
      || { echo "$skill should include a migration gate section"; result=1; }
    [[ "$content" != *'.mcp.json'* ]] \
      || { echo "$skill should not mention .mcp.json"; result=1; }
    [[ "$content" != *'AskUserQuestion'* ]] \
      || { echo "$skill should not leak AskUserQuestion into Codex runtime"; result=1; }
  done

  rm -rf "$dst"
  return $result
}

test_cc_translate_skills_preserves_optional_directories_and_rewrites_text_files() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/fixture/scripts" \
           "$src/skills/fixture/references" \
           "$src/skills/fixture/assets" \
           "$src/skills/fixture/agents"

  cat > "$src/skills/fixture/SKILL.md" <<'EOF'
---
name: fixture
description: Fixture skill
---
Use .platform/skills/fixture/, .platform/agents/example.md, and DISPATCHER.md.
EOF

  cat > "$src/skills/fixture/scripts/run.sh" <<'EOF'
#!/usr/bin/env bash
echo fixture
EOF

  cat > "$src/skills/fixture/references/guide.md" <<'EOF'
See .platform/references/guide.md and .platform/skills/fixture/.
EOF

  cat > "$src/skills/fixture/assets/template.md" <<'EOF'
Copy from .platform/agents/example.md and DISPATCHER.md.
EOF

  cat > "$src/skills/fixture/agents/openai.yaml" <<'EOF'
instruction: "Check .platform/references/guide.md before touching .platform/skills/fixture/"
EOF

  adapter_translate_skills "$src/skills" "$dst"

  local result=0
  [[ -f "$dst/.agents/skills/fixture/SKILL.md" ]] || { echo "fixture SKILL.md missing"; result=1; }
  [[ -f "$dst/.agents/skills/fixture/scripts/run.sh" ]] || { echo "fixture script missing"; result=1; }
  [[ -f "$dst/.agents/skills/fixture/references/guide.md" ]] || { echo "fixture reference missing"; result=1; }
  [[ -f "$dst/.agents/skills/fixture/assets/template.md" ]] || { echo "fixture asset missing"; result=1; }
  [[ -f "$dst/.agents/skills/fixture/agents/openai.yaml" ]] || { echo "fixture agents/openai.yaml missing"; result=1; }

  local content
  content="$(cat "$dst/.agents/skills/fixture/SKILL.md")"
  [[ "$content" == *'.agents/skills/fixture/'* ]] || { echo "fixture SKILL.md should rewrite .platform/skills/"; result=1; }
  [[ "$content" == *'.codex/agents/example.md'* ]] || { echo "fixture SKILL.md should rewrite .platform/agents/"; result=1; }
  [[ "$content" == *'AGENTS.md'* ]] || { echo "fixture SKILL.md should rewrite DISPATCHER.md"; result=1; }

  content="$(cat "$dst/.agents/skills/fixture/references/guide.md")"
  [[ "$content" == *'.codex/references/guide.md'* ]] || { echo "fixture reference should rewrite .platform/references/"; result=1; }
  [[ "$content" == *'.agents/skills/fixture/'* ]] || { echo "fixture reference should rewrite .platform/skills/"; result=1; }

  content="$(cat "$dst/.agents/skills/fixture/assets/template.md")"
  [[ "$content" == *'.codex/agents/example.md'* ]] || { echo "fixture asset should rewrite .platform/agents/"; result=1; }
  [[ "$content" == *'AGENTS.md'* ]] || { echo "fixture asset should rewrite DISPATCHER.md"; result=1; }

  content="$(cat "$dst/.agents/skills/fixture/agents/openai.yaml")"
  [[ "$content" == *'.codex/references/guide.md'* ]] || { echo "fixture openai.yaml should rewrite .platform/references/"; result=1; }
  [[ "$content" == *'.agents/skills/fixture/'* ]] || { echo "fixture openai.yaml should rewrite .platform/skills/"; result=1; }

  rm -rf "$src" "$dst"
  return $result
}

# ---------------------------------------------------------------------------
# Config translation tests
# ---------------------------------------------------------------------------

test_cc_translate_config_writes_codex_config_toml() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
    exclude: []
EOF
  adapter_translate_config "$src/mcp" "$dst"
  local result=0
  [[ -f "$dst/.codex/config.toml" ]] || { echo "config.toml missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_config_has_baseline_settings() {
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
  adapter_translate_config "$src/mcp" "$dst"
  local content; content="$(cat "$dst/.codex/config.toml")"
  local result=0
  [[ "$content" == *'approval_policy = "on-request"'* ]] || { echo "approval_policy missing"; result=1; }
  [[ "$content" == *'sandbox_mode = "workspace-write"'* ]] || { echo "sandbox_mode missing"; result=1; }
  [[ "$content" == *'max_depth = 1'* ]] || { echo "agents.max_depth missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_config_gmail_http_server() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
    exclude: []
EOF
  adapter_translate_config "$src/mcp" "$dst"
  local content; content="$(cat "$dst/.codex/config.toml")"
  local result=0
  [[ "$content" == *'[mcp_servers.Gmail]'* ]] || { echo "[mcp_servers.Gmail] missing: $content"; result=1; }
  [[ "$content" == *'url = "https://gmail.mcp.claude.com/mcp"'* ]] || { echo "url missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_config_google_calendar_uses_quoted_table() {
  # Server names with spaces must use quoted table names: [mcp_servers."Google Calendar"]
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: Google Calendar
    type: http
    url: "https://gcal.mcp.claude.com/mcp"
    env: {}
    exclude: []
EOF
  adapter_translate_config "$src/mcp" "$dst"
  local content; content="$(cat "$dst/.codex/config.toml")"
  local result=0
  [[ "$content" == *'[mcp_servers."Google Calendar"]'* ]] || { echo 'quoted table [mcp_servers."Google Calendar"] missing'; echo "$content"; result=1; }
  [[ "$content" == *'url = "https://gcal.mcp.claude.com/mcp"'* ]] || { echo "gcal url missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_config_both_servers_from_real_yaml() {
  # Use the actual mcp/servers.yaml from the repo
  local dst; dst="$(mktemp -d)"
  adapter_translate_config "$ROOT/mcp" "$dst"
  local content; content="$(cat "$dst/.codex/config.toml")"
  local result=0
  [[ "$content" == *'[mcp_servers.Gmail]'* ]] || { echo "[mcp_servers.Gmail] missing"; result=1; }
  [[ "$content" == *'[mcp_servers."Google Calendar"]'* ]] || { echo '[mcp_servers."Google Calendar"] missing'; result=1; }
  rm -rf "$dst"
  return $result
}

test_cc_translate_config_toml_is_parseable() {
  # Validate the generated config.toml passes the TOML smoke check
  local py; py="$(_python_cmd)"
  if [[ -z "$py" ]]; then
    echo "SKIP: python not found"
    return 0
  fi

  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
    exclude: []
  - name: Google Calendar
    type: http
    url: "https://gcal.mcp.claude.com/mcp"
    env: {}
    exclude: []
EOF
  adapter_translate_config "$src/mcp" "$dst"

  local result=0
  if ! "$py" "$ROOT/tests/support/toml_smoke_check.py" "$dst/.codex/config.toml"; then
    echo "TOML smoke check failed"
    result=1
  fi
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_config_has_network_access_and_profiles() {
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
  adapter_translate_config "$src/mcp" "$dst"
  local content; content="$(cat "$dst/.codex/config.toml")"
  local result=0
  [[ "$content" == *'sandbox_workspace_write.network_access = false'* ]] || { echo "network_access default missing"; result=1; }
  [[ "$content" == *'[profiles.quality]'* ]] || { echo "profiles.quality missing"; result=1; }
  [[ "$content" == *'model = "gpt-5.4"'* ]] || { echo "quality model missing"; result=1; }
  [[ "$content" == *'model_reasoning_effort = "high"'* ]] || { echo "quality reasoning effort missing"; result=1; }
  [[ "$content" == *'[profiles.balanced]'* ]] || { echo "profiles.balanced missing"; result=1; }
  [[ "$content" == *'model = "gpt-5.4-mini"'* ]] || { echo "balanced model missing"; result=1; }
  [[ "$content" == *'[profiles.budget]'* ]] || { echo "profiles.budget missing"; result=1; }
  [[ "$content" == *'model = "gpt-5.3-codex-spark"'* ]] || { echo "budget model missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_config_preserves_nonempty_env_values() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: Local Demo
    type: local
    command: ["npx", "-y", "@demo/server"]
    env: {"API_KEY":"abc123","SPACE VALUE":"hello world"}
EOF
  adapter_translate_config "$src/mcp" "$dst"
  local content; content="$(cat "$dst/.codex/config.toml")"
  local result=0
  [[ "$content" == *'[mcp_servers."Local Demo"]'* ]] || { echo 'Local Demo server table missing'; result=1; }
  [[ "$content" == *'command = ["npx", "-y", "@demo/server"]'* ]] || { echo 'command array missing'; result=1; }
  [[ "$content" == *'env = {'* ]] || { echo 'env inline table missing'; result=1; }
  [[ "$content" == *'"API_KEY" = "abc123"'* || "$content" == *'API_KEY = "abc123"'* ]] || { echo 'API_KEY env missing'; result=1; }
  [[ "$content" == *'"SPACE VALUE" = "hello world"'* ]] || { echo 'SPACE VALUE env missing'; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_rewrite_codex_paths_targets_each_platform_path() {
  local tmp; tmp="$(mktemp)"
  cat > "$tmp" <<'EOF'
See .platform/agents/alpha.md, .platform/references/guide.md, and .platform/skills/onboarding/SKILL.md.
Fallback: .platform/config.toml. Also consult DISPATCHER.md.
EOF
  rewrite_codex_paths "$tmp"
  local content; content="$(cat "$tmp")"
  local result=0
  [[ "$content" == *'.codex/agents/alpha.md'* ]] \
    || { echo ".platform/agents/ not rewritten correctly: $content"; result=1; }
  [[ "$content" == *'.codex/references/guide.md'* ]] \
    || { echo ".platform/references/ not rewritten correctly: $content"; result=1; }
  [[ "$content" == *'.agents/skills/onboarding/SKILL.md'* ]] \
    || { echo ".platform/skills/ not rewritten correctly: $content"; result=1; }
  [[ "$content" == *'.codex/config.toml'* ]] \
    || { echo "remaining .platform/ path not rewritten to .codex/: $content"; result=1; }
  [[ "$content" == *'AGENTS.md'* ]] \
    || { echo "DISPATCHER.md not rewritten to AGENTS.md: $content"; result=1; }
  [[ "$content" != *'.platform/'* ]] \
    || { echo ".platform/ still present after targeted rewrite: $content"; result=1; }
  [[ "$content" != *'DISPATCHER.md'* ]] \
    || { echo "DISPATCHER.md still present after targeted rewrite: $content"; result=1; }
  rm -f "$tmp"
  return $result
}

test_toml_smoke_check_rejects_invalid_backslash_in_quoted_key() {
  # Quoted table keys must reject invalid TOML backslash escape sequences.
  local py; py="$(_python_cmd)"
  if [[ -z "$py" ]]; then
    echo "SKIP: python not found"
    return 0
  fi

  local tmp; tmp="$(mktemp)"
  cat > "$tmp" <<'EOF'
[mcp_servers."foo\bar"]
url = "https://example.com"
EOF

  local result=0
  if "$py" "$ROOT/tests/support/toml_smoke_check.py" "$tmp" >/dev/null 2>&1; then
    echo "smoke check should reject invalid quoted key backslash escapes"
    result=1
  fi

  rm -f "$tmp"
  return $result
}

test_cc_translate_config_name_with_backslash_is_escaped_and_parseable() {
  # A server name containing \ must produce a valid TOML quoted key.
  local py; py="$(_python_cmd)"
  if [[ -z "$py" ]]; then
    echo "SKIP: python not found"
    return 0
  fi

  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: "foo\bar"
    type: http
    url: "https://example.com"
EOF

  adapter_translate_config "$src/mcp" "$dst"

  local content; content="$(cat "$dst/.codex/config.toml")"
  local result=0
  [[ "$content" == *'[mcp_servers."foo\\bar"]'* ]] \
    || { echo "escaped backslash key missing: $content"; result=1; }
  if ! "$py" "$ROOT/tests/support/toml_smoke_check.py" "$dst/.codex/config.toml"; then
    echo "smoke check failed for escaped backslash key"
    result=1
  fi

  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_config_local_server() {
  # Local (command-based) MCP server translates to TOML command array
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: local-tool
    type: local
    command: [npx, -y, "@anthropic-ai/mcp-tool"]
    env: {}
EOF
  adapter_translate_config "$src/mcp" "$dst"
  local content; content="$(cat "$dst/.codex/config.toml")"
  local result=0
  [[ "$content" == *'[mcp_servers.local-tool]'* ]] || { echo "[mcp_servers.local-tool] missing: $content"; result=1; }
  [[ "$content" == *'command = ['* ]] || { echo "command array missing"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_config_multiline_env_keys_do_not_override_server_type() {
  # Nested env mappings must not be mistaken for top-level server fields.
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: local-tool
    type: local
    command: [npx, -y, "@anthropic-ai/mcp-tool"]
    env:
      deployment_type: "prod"
EOF

  adapter_translate_config "$src/mcp" "$dst"

  local content; content="$(cat "$dst/.codex/config.toml")"
  local result=0
  [[ "$content" == *'command = ["npx", "-y", "@anthropic-ai/mcp-tool"]'* ]] \
    || { echo "command array missing or corrupted: $content"; result=1; }
  [[ "$content" != *'url = ""'* ]] \
    || { echo "env child key incorrectly overrode server type: $content"; result=1; }

  rm -rf "$src" "$dst"
  return $result
}

# ---------------------------------------------------------------------------
# End-to-end adapter_build test
# ---------------------------------------------------------------------------

test_cc_adapter_build_end_to_end() {
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"

  # Minimal source tree
  echo "# Dispatcher - check .platform/agents/ and DISPATCHER.md" > "$src/DISPATCHER.md"
  mkdir -p "$src/references" "$src/skills/onboarding" "$src/mcp"

  cat > "$src/references/policy.md" <<'EOF'
---
name: policy
---
Policy reference content.
EOF

  cat > "$src/skills/onboarding/SKILL.md" <<'SKILLEOF'
---
name: onboarding
description: Onboarding skill
---
Skill body - see .platform/agents/ for agents.
SKILLEOF

  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
    exclude: []
  - name: Google Calendar
    type: http
    url: "https://gcal.mcp.claude.com/mcp"
    env: {}
    exclude: []
EOF

  adapter_build "$src" "$dst"

  local result=0

  # Check dispatcher
  [[ -f "$dst/AGENTS.md" ]] || { echo "AGENTS.md missing"; result=1; }

  # Check references
  [[ -f "$dst/.codex/references/policy.md" ]] || { echo "policy.md reference missing"; result=1; }

  # Check skills in .agents/skills/ (Codex CLI uses .agents/ not .codex/)
  [[ -f "$dst/.agents/skills/onboarding/SKILL.md" ]] || { echo "onboarding SKILL.md missing"; result=1; }

  # Check config.toml exists and has expected tables
  [[ -f "$dst/.codex/config.toml" ]] || { echo "config.toml missing"; result=1; }
  local cfg; cfg="$(cat "$dst/.codex/config.toml" 2>/dev/null)"
  [[ "$cfg" == *'[mcp_servers.Gmail]'* ]] || { echo "[mcp_servers.Gmail] missing in config.toml"; result=1; }
  [[ "$cfg" == *'[mcp_servers."Google Calendar"]'* ]] || { echo '[mcp_servers."Google Calendar"] missing'; result=1; }

  # Verify path rewrites in dispatcher
  local disp; disp="$(cat "$dst/AGENTS.md")"
  [[ "$disp" == *".codex/agents/"* ]] || { echo ".codex/agents/ rewrite missing in AGENTS.md"; result=1; }
  [[ "$disp" != *".platform/"* ]]     || { echo ".platform/ still present in AGENTS.md"; result=1; }

  rm -rf "$src" "$dst"
  return $result
}

test_cc_adapter_build_overwrites_existing_dst() {
  # adapter_build should wipe and recreate the output dir
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"

  echo "# Dispatcher" > "$src/DISPATCHER.md"
  mkdir -p "$src/mcp"
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
EOF

  # Pre-populate dst with a stale file
  mkdir -p "$dst/.codex"
  echo "stale content" > "$dst/.codex/stale.toml"

  adapter_build "$src" "$dst"

  local result=0
  [[ ! -f "$dst/.codex/stale.toml" ]] || { echo "stale.toml should have been removed"; result=1; }
  [[ -f "$dst/AGENTS.md" ]]           || { echo "AGENTS.md missing after rebuild"; result=1; }

  rm -rf "$src" "$dst"
  return $result
}

# ---------------------------------------------------------------------------
# TOML agent translation unit tests
# ---------------------------------------------------------------------------

test_cc_translate_agent_toml_required_keys() {
  # A minimal agent with folded-block description should produce all required TOML keys
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/transcriber.md" <<'AGENTEOF'
---
name: transcriber
description: >
  Process audio recordings and voice
  memos into structured notes.
mode: subagent
capabilities: [read, write]
model: mid
---

# Transcriber

Handle audio files. See .platform/agents/ and DISPATCHER.md for routing.
AGENTEOF

  adapter_translate_agent_toml "$src/agents/transcriber.md" "$dst"

  local result=0
  local toml_file="$dst/.codex/agents/transcriber.toml"
  [[ -f "$toml_file" ]] || { echo "transcriber.toml not created at $toml_file"; result=1; return $result; }

  local content; content="$(cat "$toml_file")"
  # Required keys
  [[ "$content" == *'name = "transcriber"'* ]]           || { echo 'name key missing or wrong'; echo "$content"; result=1; }
  [[ "$content" == *'description = "'* ]]                || { echo 'description key missing'; echo "$content"; result=1; }
  [[ "$content" == *'developer_instructions'* ]]         || { echo 'developer_instructions key missing'; echo "$content"; result=1; }
  # Path rewrites applied
  [[ "$content" != *".platform/"* ]]                     || { echo '.platform/ still present (path rewrite failed)'; echo "$content"; result=1; }
  [[ "$content" != *"DISPATCHER.md"* ]]                  || { echo 'DISPATCHER.md still present (path rewrite failed)'; echo "$content"; result=1; }
  # Body content present
  [[ "$content" == *".codex/agents/"* ]]                 || { echo '.codex/agents/ not found in body'; echo "$content"; result=1; }
  [[ "$content" == *"AGENTS.md"* ]]                      || { echo 'AGENTS.md not found in body'; echo "$content"; result=1; }

  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_agent_toml_description_folded_block() {
  # Folded-block description (description: >) must be collapsed to single line
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/myagent.md" <<'AGENTEOF'
---
name: myagent
description: >
  First line of description that continues
  on the second line and the third line.
mode: subagent
capabilities: [read]
model: low
---

Body text here.
AGENTEOF

  adapter_translate_agent_toml "$src/agents/myagent.md" "$dst"

  local result=0
  local toml_file="$dst/.codex/agents/myagent.toml"
  [[ -f "$toml_file" ]] || { echo "myagent.toml not created"; result=1; return $result; }

  local content; content="$(cat "$toml_file")"
  # description must be a single quoted line (not multiline)
  local desc_line; desc_line="$(grep '^description = ' "$toml_file")"
  [[ -n "$desc_line" ]] || { echo 'description line missing'; result=1; }
  # The description value should contain words from all continuation lines
  [[ "$desc_line" == *"First line"* ]]    || { echo "First line missing from description"; echo "$desc_line"; result=1; }
  [[ "$desc_line" == *"second line"* ]]   || { echo "second line missing from description"; echo "$desc_line"; result=1; }
  [[ "$desc_line" == *"third line"* ]]    || { echo "third line missing from description"; echo "$desc_line"; result=1; }

  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_agent_toml_no_platform_paths_in_output() {
  # .platform/ and DISPATCHER.md must not appear in the generated TOML
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/sorter.md" <<'AGENTEOF'
---
name: sorter
description: Sort inbox items.
mode: subagent
capabilities: [read, write]
model: low
---

Read .platform/references/routing.md and consult DISPATCHER.md for rules.
AGENTEOF

  adapter_translate_agent_toml "$src/agents/sorter.md" "$dst"

  local result=0
  local toml_file="$dst/.codex/agents/sorter.toml"
  [[ -f "$toml_file" ]] || { echo "sorter.toml not created"; result=1; return $result; }

  local content; content="$(cat "$toml_file")"
  [[ "$content" != *".platform/"* ]]    || { echo '.platform/ found — path rewrite failed'; result=1; }
  [[ "$content" != *"DISPATCHER.md"* ]] || { echo 'DISPATCHER.md found — path rewrite failed'; result=1; }
  [[ "$content" == *".codex/"* ]]       || { echo '.codex/ not found — path rewrite not applied'; result=1; }
  [[ "$content" == *"AGENTS.md"* ]]     || { echo 'AGENTS.md not found — path rewrite not applied'; result=1; }

  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_agent_toml_multiline_literal_string_format() {
  # developer_instructions should use TOML multiline literal string (''')
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/simple.md" <<'AGENTEOF'
---
name: simple
description: A simple agent.
mode: subagent
capabilities: [read]
model: low
---

Do something simple.
AGENTEOF

  adapter_translate_agent_toml "$src/agents/simple.md" "$dst"

  local result=0
  local toml_file="$dst/.codex/agents/simple.toml"
  [[ -f "$toml_file" ]] || { echo "simple.toml not created"; result=1; return $result; }

  local content; content="$(cat "$toml_file")"
  # Must use multiline literal (''') or basic (""") string for developer_instructions
  [[ "$content" == *"developer_instructions = '''"* || "$content" == *'developer_instructions = """'* ]] \
    || { echo "developer_instructions is not a multiline string"; echo "$content"; result=1; }

  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_agent_toml_body_embedded_in_developer_instructions() {
  # The body (after frontmatter) must be embedded in developer_instructions
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/checker.md" <<'AGENTEOF'
---
name: checker
description: Check things.
mode: subagent
capabilities: [read]
model: low
---

## My Section

This is the agent body content that must appear in developer_instructions.
AGENTEOF

  adapter_translate_agent_toml "$src/agents/checker.md" "$dst"

  local result=0
  local toml_file="$dst/.codex/agents/checker.toml"
  [[ -f "$toml_file" ]] || { echo "checker.toml not created"; result=1; return $result; }

  local content; content="$(cat "$toml_file")"
  [[ "$content" == *"My Section"* ]]                           || { echo 'body section header missing'; result=1; }
  [[ "$content" == *"agent body content"* ]]                   || { echo 'body text missing'; result=1; }

  rm -rf "$src" "$dst"
  return $result
}

# ---------------------------------------------------------------------------
# End-to-end adapter_build test for TOML agent output
# ---------------------------------------------------------------------------

test_cc_adapter_build_generates_transcriber_toml() {
  # adapter_build should produce .codex/agents/transcriber.toml from source agents/
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"

  mkdir -p "$src/agents" "$src/mcp"
  cat > "$src/DISPATCHER.md" <<'EOF'
# Dispatcher — see .platform/agents/ and DISPATCHER.md
EOF

  cat > "$src/agents/transcriber.md" <<'AGENTEOF'
---
name: transcriber
description: >
  Process audio recordings, raw transcriptions, podcasts, lectures, interviews, and voice
  memos into structured Obsidian notes.
mode: subagent
capabilities: [read, write]
model: mid
---

# Transcriber

Handle .platform/references/ and see DISPATCHER.md for routing.
AGENTEOF

  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
EOF

  adapter_build "$src" "$dst"

  local result=0
  local toml_file="$dst/.codex/agents/transcriber.toml"
  [[ -f "$toml_file" ]] || { echo ".codex/agents/transcriber.toml not generated by adapter_build"; result=1; return $result; }

  local content; content="$(cat "$toml_file")"
  [[ "$content" == *'name = "transcriber"'* ]]   || { echo 'name key missing'; echo "$content"; result=1; }
  [[ "$content" == *'description = "'* ]]        || { echo 'description key missing'; echo "$content"; result=1; }
  [[ "$content" == *'developer_instructions'* ]] || { echo 'developer_instructions key missing'; echo "$content"; result=1; }
  [[ "$content" != *".platform/"* ]]             || { echo '.platform/ still present'; echo "$content"; result=1; }

  rm -rf "$src" "$dst"
  return $result
}

test_cc_translate_agent_toml_is_parseable_by_smoke_check() {
  # The generated agent TOML must pass the TOML smoke checker
  local py; py="$(_python_cmd)"
  if [[ -z "$py" ]]; then
    echo "SKIP: python not found"
    return 0
  fi

  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  # Use the real transcriber agent as the most demanding test case
  cp "$ROOT/agents/transcriber.md" "$src/agents/transcriber.md"

  adapter_translate_agent_toml "$src/agents/transcriber.md" "$dst"

  local result=0
  local toml_file="$dst/.codex/agents/transcriber.toml"
  [[ -f "$toml_file" ]] || { echo "transcriber.toml not generated"; result=1; return $result; }

  if ! "$py" "$ROOT/tests/support/toml_smoke_check.py" "$toml_file"; then
    echo "TOML smoke check failed for agent TOML"
    result=1
  fi

  rm -rf "$src" "$dst"
  return $result
}

test_cc_adapter_build_real_agent_corpus_has_exact_toml_files() {
  local dst; dst="$(mktemp -d)"
  adapter_build "$ROOT" "$dst"

  local result=0
  local expected=(
    architect.toml
    connector.toml
    librarian.toml
    postman.toml
    scribe.toml
    seeker.toml
    sorter.toml
    transcriber.toml
  )

  mapfile -t actual < <(find "$dst/.codex/agents" -maxdepth 1 -name '*.toml' -printf '%f\n' | sort)
  [[ "${#actual[@]}" -eq 8 ]] \
    || { echo "expected 8 generated agent TOML files, found ${#actual[@]}: ${actual[*]}"; result=1; }

  local idx
  for idx in "${!expected[@]}"; do
    [[ "${actual[$idx]:-missing}" == "${expected[$idx]}" ]] \
      || { echo "expected ${expected[$idx]} at index $idx, found ${actual[$idx]:-missing}"; result=1; }
  done

  rm -rf "$dst"
  return $result
}

test_cc_adapter_build_real_agent_corpus_has_required_fields_and_metadata() {
  local py; py="$(_python_cmd)"
  if [[ -z "$py" ]]; then
    echo "SKIP: python not found"
    return 0
  fi

  local dst; dst="$(mktemp -d)"
  adapter_build "$ROOT" "$dst"

  local result=0
  local files=(
    architect
    connector
    librarian
    postman
    scribe
    seeker
    sorter
    transcriber
  )

  local agent file content
  for agent in "${files[@]}"; do
    file="$dst/.codex/agents/$agent.toml"
    [[ -f "$file" ]] || { echo "missing generated file: $file"; result=1; continue; }
    content="$(cat "$file")"
    [[ "$content" == *'name = "'* ]] || { echo "name field missing in $agent.toml"; result=1; }
    [[ "$content" == *'description = "'* ]] || { echo "description field missing in $agent.toml"; result=1; }
    [[ "$content" == *'model = "'* ]] || { echo "model field missing in $agent.toml"; result=1; }
    [[ "$content" == *'model_reasoning_effort = "'* ]] || { echo "model_reasoning_effort missing in $agent.toml"; result=1; }
    [[ "$content" == *'sandbox_mode = "'* ]] || { echo "sandbox_mode missing in $agent.toml"; result=1; }
    [[ "$content" == *'developer_instructions = '* ]] || { echo "developer_instructions missing in $agent.toml"; result=1; }
    [[ "$content" != *'.platform/'* ]] || { echo ".platform/ leaked into $agent.toml"; result=1; }
    [[ "$content" != *'DISPATCHER.md'* ]] || { echo "DISPATCHER.md leaked into $agent.toml"; result=1; }
    if ! "$py" "$ROOT/tests/support/toml_smoke_check.py" "$file"; then
      echo "TOML smoke check failed for $agent.toml"
      result=1
    fi
  done

  grep -q '^sandbox_mode = "read-only"$' "$dst/.codex/agents/seeker.toml" \
    || { echo 'seeker.toml should be read-only'; result=1; }
  grep -q '^sandbox_mode = "workspace-write"$' "$dst/.codex/agents/postman.toml" \
    || { echo 'postman.toml should be workspace-write'; result=1; }
  grep -q '^sandbox_mode = "workspace-write"$' "$dst/.codex/agents/architect.toml" \
    || { echo 'architect.toml should be workspace-write'; result=1; }
  grep -q '^model = "gpt-5.4"$' "$dst/.codex/agents/architect.toml" \
    || { echo 'architect.toml should map to gpt-5.4'; result=1; }
  grep -q '^model_reasoning_effort = "high"$' "$dst/.codex/agents/architect.toml" \
    || { echo 'architect.toml should map to high reasoning effort'; result=1; }
  grep -q '^model = "gpt-5.4-mini"$' "$dst/.codex/agents/scribe.toml" \
    || { echo 'scribe.toml should map to gpt-5.4-mini'; result=1; }
  grep -q '^model_reasoning_effort = "medium"$' "$dst/.codex/agents/scribe.toml" \
    || { echo 'scribe.toml should map to medium reasoning effort'; result=1; }

  rm -rf "$dst"
  return $result
}

# ---------------------------------------------------------------------------
# Tool-compat rewrite tests (T-01-06)
# ---------------------------------------------------------------------------

test_cc_rewrite_tool_compat_removes_ask_user_question() {
  # AskUserQuestion (backtick and bare) must be rewritten to "ask the user"
  local tmp; tmp="$(mktemp)"
  cat > "$tmp" <<'EOF'
You MUST use the `AskUserQuestion` tool for every question.
Also call AskUserQuestion once per turn.
EOF
  rewrite_tool_compat "$tmp"
  local content; content="$(cat "$tmp")"
  local result=0
  [[ "$content" != *'AskUserQuestion'* ]] || { echo "AskUserQuestion still present: $content"; result=1; }
  [[ "$content" == *'ask the user'* ]]    || { echo "'ask the user' not found: $content"; result=1; }
  rm -f "$tmp"
  return $result
}

test_cc_rewrite_tool_compat_removes_request_user_input() {
  # request_user_input (backtick and bare) must be rewritten to "ask the user"
  local tmp; tmp="$(mktemp)"
  cat > "$tmp" <<'EOF'
Call `request_user_input` to get the answer.
Also request_user_input should not appear.
EOF
  rewrite_tool_compat "$tmp"
  local content; content="$(cat "$tmp")"
  local result=0
  [[ "$content" != *'request_user_input'* ]] || { echo "request_user_input still present: $content"; result=1; }
  [[ "$content" == *'ask the user'* ]]        || { echo "'ask the user' not found: $content"; result=1; }
  rm -f "$tmp"
  return $result
}

test_cc_rewrite_tool_compat_removes_skill_agent_tool_phrases() {
  # "Skill tool" and "Agent tool" must become "invoke the skill" / "invoke the agent"
  local tmp; tmp="$(mktemp)"
  cat > "$tmp" <<'EOF'
Use the Skill tool to invoke skills.
Use the Agent tool to delegate tasks.
EOF
  rewrite_tool_compat "$tmp"
  local content; content="$(cat "$tmp")"
  local result=0
  [[ "$content" != *'Skill tool'* ]]        || { echo "Skill tool still present: $content"; result=1; }
  [[ "$content" != *'Agent tool'* ]]        || { echo "Agent tool still present: $content"; result=1; }
  [[ "$content" == *'invoke the skill'* ]]  || { echo "'invoke the skill' not found: $content"; result=1; }
  [[ "$content" == *'invoke the agent'* ]]  || { echo "'invoke the agent' not found: $content"; result=1; }
  rm -f "$tmp"
  return $result
}

test_cc_rewrite_tool_compat_removes_read_glob_grep_bash_tool() {
  # "Read tool", "Glob tool", "Grep tool" → "read files"/"search files"
  # "Bash tool" → "shell"
  local tmp; tmp="$(mktemp)"
  cat > "$tmp" <<'EOF'
Use the Read tool for reading files.
Use the Glob tool to find files.
Use the Grep tool to search content.
Use the Bash tool to run commands.
EOF
  rewrite_tool_compat "$tmp"
  local content; content="$(cat "$tmp")"
  local result=0
  [[ "$content" != *'Read tool'* ]]  || { echo "Read tool still present: $content"; result=1; }
  [[ "$content" != *'Glob tool'* ]]  || { echo "Glob tool still present: $content"; result=1; }
  [[ "$content" != *'Grep tool'* ]]  || { echo "Grep tool still present: $content"; result=1; }
  [[ "$content" != *'Bash tool'* ]]  || { echo "Bash tool still present: $content"; result=1; }
  [[ "$content" == *'read files'* ]] || { echo "'read files' not found: $content"; result=1; }
  [[ "$content" == *'search files'* ]] || { echo "'search files' not found: $content"; result=1; }
  [[ "$content" == *'shell'* ]]      || { echo "'shell' not found: $content"; result=1; }
  rm -f "$tmp"
  return $result
}

test_cc_skill_output_contains_no_ask_user_question() {
  # Skills translated by adapter_translate_skills must not contain AskUserQuestion
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/create-agent"
  cat > "$src/skills/create-agent/SKILL.md" <<'SKILLEOF'
---
name: create-agent
description: Create a new agent
---

You MUST use the `AskUserQuestion` tool for EVERY question.
Call AskUserQuestion once per phase.
SKILLEOF
  adapter_translate_skills "$src/skills" "$dst"
  local content; content="$(cat "$dst/.agents/skills/create-agent/SKILL.md")"
  local result=0
  [[ "$content" != *'AskUserQuestion'* ]] || { echo "AskUserQuestion still present in skill output: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_skill_output_contains_no_request_user_input() {
  # Skills translated by adapter_translate_skills must not contain request_user_input
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/inbox"
  cat > "$src/skills/inbox/SKILL.md" <<'SKILLEOF'
---
name: inbox
description: Inbox skill
---

Call `request_user_input` to gather details.
SKILLEOF
  adapter_translate_skills "$src/skills" "$dst"
  local content; content="$(cat "$dst/.agents/skills/inbox/SKILL.md")"
  local result=0
  [[ "$content" != *'request_user_input'* ]] || { echo "request_user_input still present in skill output: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_skill_output_contains_no_tool_ish_phrases() {
  # Skills must have Read/Glob/Grep/Bash tool references rewritten
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/skills/searcher"
  cat > "$src/skills/searcher/SKILL.md" <<'SKILLEOF'
---
name: searcher
description: Search skill
---

Use the Read tool, Glob tool, Grep tool, and Bash tool.
SKILLEOF
  adapter_translate_skills "$src/skills" "$dst"
  local content; content="$(cat "$dst/.agents/skills/searcher/SKILL.md")"
  local result=0
  [[ "$content" != *'Read tool'* ]] || { echo "Read tool still present: $content"; result=1; }
  [[ "$content" != *'Glob tool'* ]] || { echo "Glob tool still present: $content"; result=1; }
  [[ "$content" != *'Grep tool'* ]] || { echo "Grep tool still present: $content"; result=1; }
  [[ "$content" != *'Bash tool'* ]] || { echo "Bash tool still present: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_agents_md_contains_no_skill_agent_tool() {
  # Generated AGENTS.md must not contain "Skill tool" or "Agent tool"
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  cat > "$src/DISPATCHER.md" <<'EOF'
# Dispatcher

Use the Skill tool to invoke skills. Use the Agent tool to delegate.
See .platform/agents/ for agents.
EOF
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  local content; content="$(cat "$dst/AGENTS.md")"
  local result=0
  [[ "$content" != *'Skill tool'* ]] || { echo "Skill tool still present in AGENTS.md: $content"; result=1; }
  [[ "$content" != *'Agent tool'* ]] || { echo "Agent tool still present in AGENTS.md: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_agent_toml_contains_no_ask_user_question() {
  # TOML agent developer_instructions must not contain AskUserQuestion
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/agents"
  cat > "$src/agents/wizard.md" <<'AGENTEOF'
---
name: wizard
description: A wizard agent.
mode: subagent
capabilities: [read]
model: low
---

You MUST use the `AskUserQuestion` tool.
Call AskUserQuestion for each step.
AGENTEOF
  adapter_translate_agent_toml "$src/agents/wizard.md" "$dst"
  local content; content="$(cat "$dst/.codex/agents/wizard.toml")"
  local result=0
  [[ "$content" != *'AskUserQuestion'* ]] || { echo "AskUserQuestion still present in agent TOML: $content"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_real_create_agent_skill_has_no_ask_user_question() {
  # The real skills/create-agent/SKILL.md (which has AskUserQuestion) must produce
  # zero occurrences of AskUserQuestion in the Codex output
  local dst; dst="$(mktemp -d)"
  adapter_translate_skills "$ROOT/skills" "$dst"
  local result=0
  local skill_out="$dst/.agents/skills/create-agent/SKILL.md"
  if [[ -f "$skill_out" ]]; then
    local content; content="$(cat "$skill_out")"
    [[ "$content" != *'AskUserQuestion'* ]] \
      || { echo "AskUserQuestion still present in real create-agent skill output"; result=1; }
    [[ "$content" != *'request_user_input'* ]] \
      || { echo "request_user_input still present in real create-agent skill output"; result=1; }
  fi
  rm -rf "$dst"
  return $result
}

# ---------------------------------------------------------------------------
# Codex dispatcher header (DISP-01 / T-01-08) tests — Task 2
# ---------------------------------------------------------------------------

test_cc_agents_md_has_codex_header_marker() {
  # Generated AGENTS.md must contain the unique Codex routing header marker
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  echo "# Dispatcher" > "$src/DISPATCHER.md"
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  local result=0
  grep -qF '<!-- CODEX-ROUTING-HEADER -->' "$dst/AGENTS.md" \
    || { echo "CODEX-ROUTING-HEADER marker missing from AGENTS.md"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_agents_md_header_contains_routing_notes() {
  # Codex header must include key routing guidance text
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  echo "# Dispatcher" > "$src/DISPATCHER.md"
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  local content; content="$(cat "$dst/AGENTS.md")"
  local result=0
  [[ "$content" == *'.codex/agents'* ]]     || { echo ".codex/agents mention missing from header"; result=1; }
  [[ "$content" == *'.agents/skills'* ]]    || { echo ".agents/skills mention missing from header"; result=1; }
  [[ "$content" == *'run shell commands'* || "$content" == *'spawn sub-agents'* ]] \
    || { echo "neutral tool language missing from header"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_agents_md_header_is_idempotent() {
  # Running adapter_translate_dispatcher twice should not duplicate the header
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  echo "# Dispatcher" > "$src/DISPATCHER.md"
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  local count; count="$(grep -c 'CODEX-ROUTING-HEADER' "$dst/AGENTS.md" || true)"
  local result=0
  [[ "$count" -eq 1 ]] || { echo "CODEX-ROUTING-HEADER appears $count times (expected 1)"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_agents_md_has_no_tool_names_after_full_build() {
  # End-to-end: after adapter_build, AGENTS.md has no unsupported tool names
  local src; src="$(mktemp -d)"
  local dst; dst="$(mktemp -d)"
  mkdir -p "$src/mcp"
  cat > "$src/DISPATCHER.md" <<'EOF'
# Dispatcher

Use the Skill tool to invoke skills.
Use the Agent tool to delegate.
Call `AskUserQuestion` for input.
Use request_user_input as fallback.
EOF
  cat > "$src/mcp/servers.yaml" <<'EOF'
servers:
  - name: Gmail
    type: http
    url: "https://gmail.mcp.claude.com/mcp"
    env: {}
EOF
  adapter_build "$src" "$dst"
  local content; content="$(cat "$dst/AGENTS.md")"
  local result=0
  [[ "$content" != *'AskUserQuestion'* ]]    || { echo "AskUserQuestion in AGENTS.md after build"; result=1; }
  [[ "$content" != *'request_user_input'* ]] || { echo "request_user_input in AGENTS.md after build"; result=1; }
  [[ "$content" != *'Skill tool'* ]]         || { echo "Skill tool in AGENTS.md after build"; result=1; }
  [[ "$content" != *'Agent tool'* ]]         || { echo "Agent tool in AGENTS.md after build"; result=1; }
  grep -qF '<!-- CODEX-ROUTING-HEADER -->' "$dst/AGENTS.md" \
    || { echo "CODEX-ROUTING-HEADER missing after full build"; result=1; }
  rm -rf "$src" "$dst"
  return $result
}

test_cc_adapter_build_real_dispatcher_references_codex_compat_contract() {
  local dst; dst="$(mktemp -d)"
  adapter_build "$ROOT" "$dst"

  local content; content="$(cat "$dst/AGENTS.md")"
  local result=0
  [[ "$content" == *'max_depth = 1'* ]] \
    || { echo 'AGENTS.md should mention max_depth = 1'; result=1; }
  [[ "$content" == *'.codex/references/codex-cli-compat.md'* ]] \
    || { echo 'AGENTS.md should point to .codex/references/codex-cli-compat.md'; result=1; }
  [[ "$content" != *'Skill tool'* ]] || { echo 'Skill tool leaked into real AGENTS.md output'; result=1; }
  [[ "$content" != *'Agent tool'* ]] || { echo 'Agent tool leaked into real AGENTS.md output'; result=1; }
  [[ "$content" != *'AskUserQuestion'* ]] || { echo 'AskUserQuestion leaked into real AGENTS.md output'; result=1; }
  [[ "$content" != *'request_user_input'* ]] || { echo 'request_user_input leaked into real AGENTS.md output'; result=1; }

  rm -rf "$dst"
  return $result
}

test_cc_adapter_build_normalizes_agent_orchestration_for_codex_depth() {
  local dst; dst="$(mktemp -d)"
  adapter_build "$ROOT" "$dst"

  local content; content="$(cat "$dst/.codex/references/agent-orchestration.md")"
  local result=0
  [[ "$content" == *'root context'* || "$content" == *'agents.max_depth = 1'* ]] \
    || { echo 'agent-orchestration.md should explain root-only Codex orchestration'; result=1; }
  [[ "$content" != *'max depth 3'* ]] \
    || { echo 'max depth 3 should not appear in Codex agent-orchestration output'; result=1; }
  [[ "$content" != *'step 3 of max 3'* ]] \
    || { echo 'step 3 of max 3 should not appear in Codex agent-orchestration output'; result=1; }

  rm -rf "$dst"
  return $result
}

test_cc_adapter_build_generates_codex_compat_reference() {
  local dst; dst="$(mktemp -d)"
  adapter_build "$ROOT" "$dst"

  local compat="$dst/.codex/references/codex-cli-compat.md"
  local result=0
  [[ -f "$compat" ]] || { echo 'codex-cli-compat.md should be generated'; result=1; }
  if [[ -f "$compat" ]]; then
    local content; content="$(cat "$compat")"
    [[ "$content" == *'AskUserQuestion'* ]] || { echo 'compat reference should document AskUserQuestion'; result=1; }
    [[ "$content" == *'request_user_input'* ]] || { echo 'compat reference should document request_user_input'; result=1; }
    [[ "$content" == *'spawn_agent'* ]] || { echo 'compat reference should mention spawn_agent'; result=1; }
    [[ "$content" == *'.codex/config.toml'* ]] || { echo 'compat reference should mention .codex/config.toml'; result=1; }
    [[ "$content" == *'.agents/skills/'* ]] || { echo 'compat reference should mention .agents/skills/'; result=1; }
  fi

  rm -rf "$dst"
  return $result
}

test_cc_normalize_codex_routing_contract_rewrites_depth_and_tool_tokens() {
  local tmp; tmp="$(mktemp)"
  cat > "$tmp" <<'EOF'
Use the Skill tool, Agent tool, and AskUserQuestion.
Call request_user_input if AskUserQuestion is unavailable.
You are step 3 of max 3. The dispatcher may recurse to max depth 3.
EOF

  normalize_codex_routing_contract "$tmp"

  local content; content="$(cat "$tmp")"
  local result=0
  [[ "$content" != *'Skill tool'* ]] || { echo 'Skill tool should be normalized'; result=1; }
  [[ "$content" != *'Agent tool'* ]] || { echo 'Agent tool should be normalized'; result=1; }
  [[ "$content" != *'AskUserQuestion'* ]] || { echo 'AskUserQuestion should be normalized'; result=1; }
  [[ "$content" != *'request_user_input'* ]] || { echo 'request_user_input should be normalized'; result=1; }
  [[ "$content" != *'step 3 of max 3'* ]] || { echo 'step 3 of max 3 should be normalized'; result=1; }
  [[ "$content" != *'max depth 3'* ]] || { echo 'max depth 3 should be normalized'; result=1; }
  [[ "$content" == *'max_depth = 1'* || "$content" == *'root context'* ]] \
    || { echo 'normalized output should mention the root-only Codex contract'; result=1; }

  rm -f "$tmp"
  return $result
}


test_cc_real_dispatcher_prunes_source_appendix_and_stale_runtime_strings() {
  local dst; dst="$(mktemp -d)"
  adapter_build "$ROOT" "$dst"

  local content; content="$(cat "$dst/AGENTS.md")"
  local result=0
  [[ "$content" != *'# Project Info'* ]] || { echo 'source appendix should not leak into Codex AGENTS.md'; result=1; }
  [[ "$content" != *'.mcp.json'* ]] || { echo '.mcp.json should not appear in Codex AGENTS.md'; result=1; }
  [[ "$content" != *'.codex/skills/'* ]] || { echo '.codex/skills/ should not appear in Codex AGENTS.md'; result=1; }
  [[ "$content" != *'.codex/agents/{name}.md'* ]] || { echo '.codex/agents/{name}.md should not appear in Codex AGENTS.md'; result=1; }

  rm -rf "$dst"
  return $result
}

test_cc_real_onboarding_skill_uses_codex_runtime_examples() {
  local dst; dst="$(mktemp -d)"
  adapter_build "$ROOT" "$dst"

  local skill="$dst/.agents/skills/onboarding/SKILL.md"
  local content; content="$(cat "$skill")"
  local result=0
  [[ "$content" == *'.codex/config.toml'* ]] || { echo 'onboarding should mention .codex/config.toml'; result=1; }
  [[ "$content" == *'[mcp_servers.Gmail]'* ]] || { echo 'onboarding should show TOML MCP example'; result=1; }
  [[ "$content" != *'mcpServers'* ]] || { echo 'onboarding should not show JSON mcpServers example'; result=1; }
  [[ "$content" != *'.mcp.json'* ]] || { echo 'onboarding should not mention .mcp.json'; result=1; }
  [[ "$content" != *'"$AGENT_SOURCE"/architect.md'* ]] || { echo 'onboarding should not copy .md agent files in Codex mode'; result=1; }
  [[ "$content" != *'.codex/agents/architect.md'* ]] || { echo 'onboarding should not reference .md agent runtime paths'; result=1; }
  [[ "$content" == *'architect.toml'* ]] || { echo 'onboarding should reference .toml agent files'; result=1; }

  rm -rf "$dst"
  return $result
}

test_cc_real_agent_template_is_toml_native() {
  local dst; dst="$(mktemp -d)"
  adapter_build "$ROOT" "$dst"

  local template="$dst/.codex/references/agent-template.md"
  local content; content="$(cat "$template")"
  local result=0
  [[ "$content" == *'```toml'* ]] || { echo 'agent-template should use a TOML example'; result=1; }
  [[ "$content" == *"developer_instructions = '''"* ]] || { echo 'agent-template should document developer_instructions'; result=1; }
  [[ "$content" == *'.codex/agents/{{agent-name}}.toml'* ]] || { echo 'agent-template should point to .toml output'; result=1; }
  [[ "$content" != *'```yaml'* ]] || { echo 'agent-template should not use YAML in Codex output'; result=1; }
  [[ "$content" != *'.platform/'* ]] || { echo 'agent-template should not leak .platform paths'; result=1; }

  rm -rf "$dst"
  return $result
}
