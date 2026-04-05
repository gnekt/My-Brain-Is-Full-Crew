Created the four platform variable maps under `platforms/` as bash-sourceable `.env` files with only the requested variables.

Verification pattern used successfully:
- `source platforms/claude.env && echo "$TOOL_READ"`
- `source platforms/gemini.env && echo "$TOOL_READ"`
- `source platforms/codex.env && echo "$TOOL_BASH"`
- `bash -n platforms/*.env`

All four files passed source and syntax checks.

## Task 3: Agent Templates

Created 8 templatized agent files in `templates/agents/*.md.tmpl`.

### Substitution patterns applied:
- **Frontmatter tools**: Direct `\b` word-boundary regex on the `tools:` line
- **Frontmatter model**: Same approach on the `model:` line
- **Body `.claude/`**: Simple string replace — all instances are path prefixes
- **Body tool names**: Two-tier approach:
  - Backtick-quoted tool names (`` `Read` `` etc.) — string replace, though none actually existed in body text
  - Bare tool names: only `Bash`, `Grep`, `Glob`, `AskUserQuestion` are safe to replace as `\bName\b` whole-word matches. `Read`/`Write`/`Edit` excluded (clash with English verbs). `Agent`/`Skill` excluded (clash with concept nouns in body text).
- **Code block protection**: Track fenced block state (``` toggle); skip all lines inside fences

### Key observations:
- No backtick-quoted tool names exist in any agent body text — all tool refs are unquoted
- `CLAUDE.md` and `Claude Code` do NOT appear in any of the 8 agent files (only in CLAUDE.md dispatcher)
- `.claude/` appears in all 8 files (references to `.claude/references/`) — consistently 2-3 per file
- MCP tool names (`gmail_*`, `gcal_*`, `gws`, `hey`) only in postman.md — correctly preserved
- Agent name references (Architect, Seeker, Librarian etc.) appear throughout — correctly preserved
- Line counts match exactly between source and template for all 8 files
- `scripts/templatize_agents.py` included in commit for reproducibility

## Task 7: validate.sh

- `yq` (go-yq v4) installed via pacman. Syntax: `yq eval '.' -` for stdin YAML, `yq eval -p toml '.' file` for TOML.
- YAML frontmatter extraction pattern: `awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print}'` — cleaner than sed for multi-line extraction.
- `{{VAR}}` in YAML values (e.g., `description: {{UNRESOLVED_VAR}}`) causes yq parse errors because `{` initiates YAML flow mapping. This means Check 2 (YAML validity) catches unresolved-var fixtures even when Check 1 skips them.
- Shellcheck v0.11.0 available via pacman; passed clean on first attempt by using quoted variables, `head -n 1` (not `head -1`), and here-strings (`<<<`) for piping to yq.
- Bash `BASH_REMATCH` loop for extracting multiple `{{VAR}}` matches per line: advance with `remaining="${remaining#*"$match"}"` using shortest-prefix glob removal.

## Task 8: build.sh

### Build architecture
- `expand_file()` uses awk to tag lines as F (fenced) or E (expandable), then pipes through sed only for E lines
- `build_sed_script()` parses env KEY=VALUE pairs into a sed script file with `s/{{KEY}}/VALUE/g` lines
- For Gemini: `convert_tools_to_yaml_list()` extracts frontmatter with awk, uses `yq eval '.tools = (.tools | split(", "))'` to convert comma-separated tools to YAML list, then reassembles with body

### validate.sh adjustments needed
- Templates contain runtime placeholders like `{{N}}`, `{{YYYY}}`, `{{A}}`, `{{B}}` outside code fences — these are NOT build variables
- Templates contain build variables like `{{PLATFORM_DIR}}` inside code fences (agent-template.md, onboarding SKILL.md.tmpl) — correctly protected from expansion
- Original validate.sh regex `[A-Z_]+` was too broad — caught both build vars and runtime placeholders
- Fix: (1) awk to skip code-fenced lines, (2) regex `[A-Z][A-Z_]*_[A-Z_]*` requiring at least one underscore — all build vars have underscores, runtime placeholders don't

### Key patterns
- All build variables contain underscores: TOOL_READ, MODEL_FAST, PLATFORM_DIR, DISPATCHER_FILE, PLATFORM_NAME
- Content placeholders use single letters (N, A, B, X, Y) or short words (YYYY, MM) without underscores
- `.gitignore` had `scripts/build.sh` entry (placeholder from T1) — removed to allow tracking
- `yq` on full markdown file errors; must extract frontmatter first with awk for yq operations

## Task 9: Codex TOML generation

- Reused the T8 expansion flow for Codex: expand agent templates to temporary markdown first, then convert only `build/codex/agents/*.toml`; skills, references, and `AGENTS.md` stay markdown.
- Added shared `extract_frontmatter()` / `extract_body_after_frontmatter()` helpers so Gemini tool conversion and Codex TOML conversion use the same awk extraction pattern.
- TOML single-line fields (`name`, `description`, `model`) need explicit escaping for `\`, `"`, tabs, CR, and newline folding.
- `developer_instructions` uses TOML multiline basic strings (`"""..."""`), so backslashes must be doubled and literal `"""` must be rewritten as `""\\\"` to keep the generated TOML parseable.
- `./scripts/validate.sh build/codex/` passes, but still warns `agents/ has 0 files (expected 8)` because its structure warning only counts `agents/*.md`; TOML syntax validation still succeeds.
