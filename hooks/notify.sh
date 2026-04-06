#!/usr/bin/env bash
# =============================================================================
# Hook: Desktop Notification (Notification event)
# =============================================================================
# Sends a macOS/Linux desktop notification when Claude Code needs attention.
# Useful during long agent chains that can take several minutes.
#
# macOS: uses osascript (built-in)
# Linux: uses notify-send (install with: sudo apt install libnotify-bin)
# =============================================================================

INPUT=$(cat)
TITLE=$(echo "$INPUT" | jq -r '.title // "Second Brain Crew"' 2>/dev/null)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude needs your attention"' 2>/dev/null)

# Sanitize: strip characters that could break AppleScript string interpolation
# or trigger shell metacharacter expansion in the osascript -e argument.
# Removes: double-quotes (AppleScript string terminator), backslashes (escape char),
# backticks and $() (shell command substitution).
TITLE=$(printf '%s' "$TITLE"   | tr -d '"\\`$')
MESSAGE=$(printf '%s' "$MESSAGE" | tr -d '"\\`$')

if [[ "$(uname)" == "Darwin" ]]; then
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null
elif command -v notify-send &>/dev/null; then
  notify-send "$TITLE" "$MESSAGE" 2>/dev/null
fi

exit 0
