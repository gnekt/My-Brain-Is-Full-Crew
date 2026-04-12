#!/usr/bin/env bash
# =============================================================================
# tests/scripts/platform-parity.test.sh — Four-platform build parity suite
# =============================================================================
# Proves that Codex CLI changes did not regress Claude Code, Gemini CLI,
# OpenCode, or Codex CLI build artifacts.  Runs as part of tests/run.sh.
# =============================================================================
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ---------------------------------------------------------------------------
# test_platform_build_matrix_produces_expected_dispatchers_and_roots
#
# Builds all four platforms and asserts each produces the correct dispatcher,
# platform config directory, and at least one canonical agent file.
# ---------------------------------------------------------------------------
test_platform_build_matrix_produces_expected_dispatchers_and_roots() {
  local result=0

  # Platform → expected artifacts map
  # Format: "<dispatcher>|<agent_file>|<config_file>"
  declare -A EXPECTED
  EXPECTED["claude-code"]="dist/claude-code/CLAUDE.md|dist/claude-code/.claude/agents/architect.md|dist/claude-code/.mcp.json"
  EXPECTED["gemini-cli"]="dist/gemini-cli/GEMINI.md|dist/gemini-cli/.gemini/agents/architect.md|dist/gemini-cli/.gemini/settings.json"
  EXPECTED["opencode"]="dist/opencode/AGENTS.md|dist/opencode/.opencode/agents/architect.md|dist/opencode/opencode.json"
  EXPECTED["codex-cli"]="dist/codex-cli/AGENTS.md|dist/codex-cli/.codex/agents/architect.toml|dist/codex-cli/.codex/config.toml"

  for platform in claude-code gemini-cli opencode codex-cli; do
    if ! bash "$ROOT/scripts/build.sh" --platform "$platform" >/dev/null 2>&1; then
      echo "FAIL: build failed for platform: $platform"
      result=1
      continue
    fi

    IFS='|' read -r dispatcher agent_file config_file <<< "${EXPECTED[$platform]}"

    [[ -f "$ROOT/$dispatcher" ]] \
      || { echo "FAIL [$platform]: dispatcher missing: $dispatcher"; result=1; }
    [[ -f "$ROOT/$agent_file" ]] \
      || { echo "FAIL [$platform]: agent file missing: $agent_file"; result=1; }
    [[ -f "$ROOT/$config_file" ]] \
      || { echo "FAIL [$platform]: config file missing: $config_file"; result=1; }
  done

  # Additional Codex-specific: skills directory
  [[ -f "$ROOT/dist/codex-cli/.agents/skills/onboarding/SKILL.md" ]] \
    || { echo "FAIL [codex-cli]: .agents/skills/onboarding/SKILL.md missing"; result=1; }

  return $result
}

# ---------------------------------------------------------------------------
# test_claude_snapshot_regression_still_passes_after_codex_changes
#
# Runs the Claude Code snapshot regression test.  Fails immediately if the
# snapshot diff reports any drift — Codex changes must not touch Claude output.
# ---------------------------------------------------------------------------
test_claude_snapshot_regression_still_passes_after_codex_changes() {
  local log; log="$(mktemp)"
  if ! bash "$ROOT/tests/regression/run.sh" >"$log" 2>&1; then
    echo "FAIL: Claude snapshot regression reported drift:"
    cat "$log"
    rm -f "$log"
    return 1
  fi
  rm -f "$log"
  return 0
}

# ---------------------------------------------------------------------------
# test_codex_install_update_gate_remains_in_the_full_suite
#
# Asserts that the Codex CLI install/update test file still exists and
# defines both required test function names.  This gate ensures the parity
# suite does not accidentally exclude Codex install regression coverage.
# ---------------------------------------------------------------------------
test_codex_install_update_gate_remains_in_the_full_suite() {
  local install_test="$ROOT/tests/scripts/codex-cli-install.test.sh"
  local result=0

  [[ -f "$install_test" ]] \
    || { echo "FAIL: tests/scripts/codex-cli-install.test.sh does not exist"; return 1; }

  grep -q 'test_launchme_installs_codex_cli_layout' "$install_test" \
    || { echo "FAIL: test_launchme_installs_codex_cli_layout not found in codex-cli-install.test.sh"; result=1; }
  grep -q 'test_updateme_auto_detects_and_refreshes_codex_cli_install' "$install_test" \
    || { echo "FAIL: test_updateme_auto_detects_and_refreshes_codex_cli_install not found in codex-cli-install.test.sh"; result=1; }

  return $result
}
