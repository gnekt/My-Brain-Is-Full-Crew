#!/usr/bin/env bash
# Tests for Codex CLI install/update flows in scripts/launchme.sh and scripts/updateme.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

test_codex_cli_scripts_define_explicit_platform_cases() {
  local result=0
  grep -q 'codex-cli)' "$ROOT/scripts/launchme.sh" \
    || { echo 'launchme.sh should define a codex-cli) case'; result=1; }
  grep -q 'codex-cli)' "$ROOT/scripts/updateme.sh" \
    || { echo 'updateme.sh should define a codex-cli) case'; result=1; }
  grep -q '\.codex/agents' "$ROOT/scripts/updateme.sh" \
    || { echo 'updateme.sh should detect .codex/agents installs'; result=1; }
  return $result
}

test_launchme_installs_codex_cli_layout() {
  local vault; vault="$(mktemp -d)"
  local log; log="$(mktemp)"

  if ! bash "$ROOT/scripts/launchme.sh" --platform codex-cli --target "$vault" >"$log" 2>&1; then
    cat "$log"
    rm -rf "$vault" "$log"
    return 1
  fi

  local result=0
  [[ -f "$vault/AGENTS.md" ]] || { echo 'AGENTS.md missing after codex-cli install'; result=1; }
  [[ -f "$vault/.codex/config.toml" ]] || { echo '.codex/config.toml missing after codex-cli install'; result=1; }
  [[ -d "$vault/.codex/agents" ]] || { echo '.codex/agents missing after codex-cli install'; result=1; }
  [[ -f "$vault/.codex/agents/transcriber.toml" || -f "$vault/.codex/agents/architect.toml" ]] \
    || { echo 'core codex agent TOML missing after install'; result=1; }
  [[ -f "$vault/.agents/skills/onboarding/SKILL.md" ]] || { echo '.agents/skills/onboarding/SKILL.md missing after install'; result=1; }

  if [[ -f "$vault/AGENTS.md" ]]; then
    grep -q 'Codex CLI' "$vault/AGENTS.md" \
      || { echo 'AGENTS.md should contain Codex CLI guidance'; result=1; }
  fi
  if [[ -f "$vault/.codex/config.toml" ]]; then
    grep -q '\[agents\]' "$vault/.codex/config.toml" \
      || { echo '.codex/config.toml should contain [agents]'; result=1; }
  fi

  rm -rf "$vault" "$log"
  return $result
}

test_updateme_auto_detects_and_refreshes_codex_cli_install() {
  local vault; vault="$(mktemp -d)"
  local install_log; install_log="$(mktemp)"
  local update_log; update_log="$(mktemp)"

  if ! bash "$ROOT/scripts/launchme.sh" --platform codex-cli --target "$vault" >"$install_log" 2>&1; then
    cat "$install_log"
    rm -rf "$vault" "$install_log" "$update_log"
    return 1
  fi

  printf 'stale dispatcher\n' > "$vault/AGENTS.md"
  printf 'stale config\n' > "$vault/.codex/config.toml"

  if ! printf 'c\n' | bash "$ROOT/scripts/updateme.sh" --target "$vault" >"$update_log" 2>&1; then
    cat "$update_log"
    rm -rf "$vault" "$install_log" "$update_log"
    return 1
  fi

  local result=0
  grep -q 'Detected platform: codex-cli' "$update_log" \
    || { echo 'updateme.sh should auto-detect codex-cli'; result=1; }
  grep -q 'Codex CLI' "$vault/AGENTS.md" \
    || { echo 'update should refresh AGENTS.md content'; result=1; }
  grep -q '\[agents\]' "$vault/.codex/config.toml" \
    || { echo 'update should refresh .codex/config.toml content'; result=1; }
  [[ -d "$vault/.codex/agents" ]] || { echo '.codex/agents should remain after update'; result=1; }
  [[ -d "$vault/.agents/skills" ]] || { echo '.agents/skills should remain after update'; result=1; }

  rm -rf "$vault" "$install_log" "$update_log"
  return $result
}
