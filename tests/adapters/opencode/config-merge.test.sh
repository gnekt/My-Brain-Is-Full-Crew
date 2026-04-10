#!/usr/bin/env bash
# Tests for adapters/opencode/config-merge.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT/adapters/lib.sh"
source "$ROOT/adapters/opencode/config-merge.sh"

test_oc_merge_fresh_install() {
  local built; built="$(mktemp)"
  local existing; existing="$(mktemp)"
  local output; output="$(mktemp)"
  rm "$existing"
  cat > "$built" <<'HEREDOC'
{
  "mcp": {
    "Gmail": {
      "type": "remote",
      "url": "https://gmail.mcp.claude.com/mcp"
    }
  }
}
HEREDOC
  oc_config_merge "$built" "$existing" "$output"
  local result=0
  [[ -f "$output" ]] || { echo "output not created"; result=1; }
  jq -e '.mcp.Gmail.url' "$output" >/dev/null || { echo "Gmail not in output"; result=1; }
  rm -f "$built" "$output"
  return $result
}

test_oc_merge_preserves_user_keys() {
  local built; built="$(mktemp)"
  local existing; existing="$(mktemp)"
  local output; output="$(mktemp)"
  cat > "$built" <<'HEREDOC'
{
  "mcp": {
    "Gmail": {
      "type": "remote",
      "url": "https://gmail.mcp.claude.com/mcp"
    }
  }
}
HEREDOC
  cat > "$existing" <<'HEREDOC'
{
  "model": "anthropic/claude-sonnet-4-5",
  "small_model": "anthropic/claude-haiku-4-5",
  "mcp": {
    "MyCustomServer": {
      "type": "local",
      "command": "my-server"
    }
  }
}
HEREDOC
  oc_config_merge "$built" "$existing" "$output"
  local result=0
  jq -e '.mcp.Gmail.url' "$output" >/dev/null || { echo "Gmail missing"; result=1; }
  jq -e '.model == "anthropic/claude-sonnet-4-5"' "$output" >/dev/null || { echo "model key lost"; result=1; }
  jq -e '.small_model == "anthropic/claude-haiku-4-5"' "$output" >/dev/null || { echo "small_model key lost"; result=1; }
  jq -e '.mcp.MyCustomServer.command == "my-server"' "$output" >/dev/null || { echo "user MCP server lost"; result=1; }
  rm -f "$built" "$existing" "$output"
  return $result
}

test_oc_merge_our_mcp_overwrites_same_name() {
  local built; built="$(mktemp)"
  local existing; existing="$(mktemp)"
  local output; output="$(mktemp)"
  cat > "$built" <<'HEREDOC'
{
  "mcp": {
    "Gmail": {
      "type": "remote",
      "url": "https://gmail.mcp.claude.com/mcp"
    }
  }
}
HEREDOC
  cat > "$existing" <<'HEREDOC'
{
  "mcp": {
    "Gmail": {
      "type": "remote",
      "url": "https://old-url.example.com"
    }
  }
}
HEREDOC
  oc_config_merge "$built" "$existing" "$output"
  local result=0
  local url; url="$(jq -r '.mcp.Gmail.url' "$output")"
  [[ "$url" == "https://gmail.mcp.claude.com/mcp" ]] || { echo "our url should win: got $url"; result=1; }
  rm -f "$built" "$existing" "$output"
  return $result
}

test_oc_merge_detects_indentation() {
  local built; built="$(mktemp)"
  local existing; existing="$(mktemp)"
  local output; output="$(mktemp)"
  cat > "$built" <<'HEREDOC'
{
  "mcp": {
    "Gmail": {
      "type": "remote",
      "url": "https://gmail.mcp.claude.com/mcp"
    }
  }
}
HEREDOC
  cat > "$existing" <<'HEREDOC'
{
    "model": "anthropic/claude-sonnet-4-5",
    "mcp": {}
}
HEREDOC
  oc_config_merge "$built" "$existing" "$output"
  local result=0
  grep -q '^    "model"' "$output" || { echo "expected 4-space indent"; cat "$output"; result=1; }
  rm -f "$built" "$existing" "$output"
  return $result
}

test_oc_merge_malformed_existing_falls_back() {
  local built; built="$(mktemp)"
  local existing; existing="$(mktemp)"
  local output; output="$(mktemp)"
  cat > "$built" <<'HEREDOC'
{
  "mcp": {
    "Gmail": {
      "type": "remote",
      "url": "https://gmail.mcp.claude.com/mcp"
    }
  }
}
HEREDOC
  echo "this is not json" > "$existing"
  oc_config_merge "$built" "$existing" "$output" 2>/dev/null
  local result=0
  jq -e '.mcp.Gmail.url' "$output" >/dev/null || { echo "fallback failed"; result=1; }
  rm -f "$built" "$existing" "$output"
  return $result
}

test_oc_merge_no_mcp_in_existing() {
  local built; built="$(mktemp)"
  local existing; existing="$(mktemp)"
  local output; output="$(mktemp)"
  cat > "$built" <<'HEREDOC'
{
  "mcp": {
    "Gmail": {
      "type": "remote",
      "url": "https://gmail.mcp.claude.com/mcp"
    }
  }
}
HEREDOC
  cat > "$existing" <<'HEREDOC'
{
  "model": "anthropic/claude-sonnet-4-5"
}
HEREDOC
  oc_config_merge "$built" "$existing" "$output"
  local result=0
  jq -e '.model == "anthropic/claude-sonnet-4-5"' "$output" >/dev/null || { echo "model key lost"; result=1; }
  jq -e '.mcp.Gmail.url' "$output" >/dev/null || { echo "Gmail not added"; result=1; }
  rm -f "$built" "$existing" "$output"
  return $result
}
