#!/usr/bin/env python3
"""Generate templatized agent files for multi-platform support.

Reads agents/*.md, applies platform variable substitutions,
writes templates/agents/*.md.tmpl. Fenced code blocks are protected.
"""

import os
import re

SOURCE_DIR = "agents"
DEST_DIR = "templates/agents"

AGENTS = [
    "architect", "connector", "librarian", "postman",
    "scribe", "seeker", "sorter", "transcriber",
]

# ── Frontmatter maps ────────────────────────────────────────────────

FM_TOOL_MAP = {
    "Read": "{{TOOL_READ}}",
    "Write": "{{TOOL_WRITE}}",
    "Edit": "{{TOOL_EDIT}}",
    "Bash": "{{TOOL_BASH}}",
    "Glob": "{{TOOL_GLOB}}",
    "Grep": "{{TOOL_GREP}}",
}

FM_MODEL_MAP = {
    "sonnet": "{{MODEL_FAST}}",
    "opus": "{{MODEL_POWERFUL}}",
    "haiku": "{{MODEL_LIGHT}}",
}

# ── Body-text maps ──────────────────────────────────────────────────

# Backtick-quoted tool names:  `Read` → `{{TOOL_READ}}`
BACKTICK_TOOLS = {
    "Read": "{{TOOL_READ}}",
    "Write": "{{TOOL_WRITE}}",
    "Edit": "{{TOOL_EDIT}}",
    "Bash": "{{TOOL_BASH}}",
    "Glob": "{{TOOL_GLOB}}",
    "Grep": "{{TOOL_GREP}}",
    "Agent": "{{TOOL_AGENT}}",
    "Skill": "{{TOOL_SKILL}}",
    "AskUserQuestion": "{{TOOL_ASK}}",
}

# Non-backtick tool names that are unambiguous enough to replace as
# whole-word matches (\bName\b).  "Read/Write/Edit" are excluded
# because they clash with common English verbs.
BARE_TOOLS = {
    "Bash": "{{TOOL_BASH}}",
    "Grep": "{{TOOL_GREP}}",
    "Glob": "{{TOOL_GLOB}}",
    "AskUserQuestion": "{{TOOL_ASK}}",
}


# ── Helpers ─────────────────────────────────────────────────────────

def split_frontmatter(content):
    """Return (frontmatter_str, body_str) or (None, content)."""
    if content.startswith("---\n"):
        end = content.find("\n---\n", 4)
        if end != -1:
            return content[4:end], content[end + 5:]
    return None, content


def process_frontmatter(fm):
    lines = fm.split("\n")
    out = []
    for line in lines:
        if line.startswith("tools:"):
            for name, var in FM_TOOL_MAP.items():
                line = re.sub(r"\b" + re.escape(name) + r"\b", var, line)
        elif line.startswith("model:"):
            for name, var in FM_MODEL_MAP.items():
                line = re.sub(r"\b" + re.escape(name) + r"\b", var, line)
        out.append(line)
    return "\n".join(out)


def process_body_line(line):
    """Apply substitutions to one body line (guaranteed outside code fence)."""
    # 1. Path & platform references
    line = line.replace(".claude/", "{{PLATFORM_DIR}}/")
    line = re.sub(r"\bCLAUDE\.md\b", "{{DISPATCHER_FILE}}", line)
    line = line.replace("Claude Code", "{{PLATFORM_NAME}}")

    # 2. Backtick-quoted tool names
    for name, var in BACKTICK_TOOLS.items():
        line = line.replace(f"`{name}`", f"`{var}`")

    # 3. Bare (non-backtick) tool names — only safe ones
    for name, var in BARE_TOOLS.items():
        line = re.sub(r"\b" + re.escape(name) + r"\b", var, line)

    return line


def process_body(body):
    """Process body text while protecting fenced code blocks."""
    lines = body.split("\n")
    out = []
    in_fence = False

    for line in lines:
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            out.append(line)
            continue
        if in_fence:
            out.append(line)
            continue
        out.append(process_body_line(line))

    return "\n".join(out)


# ── Main ────────────────────────────────────────────────────────────

def process_file(agent):
    src = os.path.join(SOURCE_DIR, f"{agent}.md")
    dst = os.path.join(DEST_DIR, f"{agent}.md.tmpl")

    with open(src, encoding="utf-8") as f:
        content = f.read()

    fm, body = split_frontmatter(content)

    if fm is not None:
        output = f"---\n{process_frontmatter(fm)}\n---\n{process_body(body)}"
    else:
        output = process_body(content)

    with open(dst, "w", encoding="utf-8") as f:
        f.write(output)

    src_n = content.count("\n")
    dst_n = output.count("\n")
    ok = src_n == dst_n
    tag = "OK" if ok else f"MISMATCH ({src_n} → {dst_n})"
    print(f"  {agent}.md.tmpl — {tag} ({src_n + 1} lines)")
    return ok


def main():
    os.makedirs(DEST_DIR, exist_ok=True)
    print(f"Generating templates in {DEST_DIR}/\n")
    results = [process_file(a) for a in AGENTS]
    print(f"\n{len(AGENTS)} templates created.  All OK: {all(results)}")


if __name__ == "__main__":
    main()
