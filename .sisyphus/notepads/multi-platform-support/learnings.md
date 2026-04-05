Created the four platform variable maps under `platforms/` as bash-sourceable `.env` files with only the requested variables.

Verification pattern used successfully:
- `source platforms/claude.env && echo "$TOOL_READ"`
- `source platforms/gemini.env && echo "$TOOL_READ"`
- `source platforms/codex.env && echo "$TOOL_BASH"`
- `bash -n platforms/*.env`

All four files passed source and syntax checks.
