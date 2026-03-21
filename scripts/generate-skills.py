#!/usr/bin/env python3
"""
Generate skills/ from agents/ — single source of truth stays in agents/*.md.

Each agent becomes a skill at skills/{name}/SKILL.md with:
  - tools:            → allowed-tools:
  - disallowedTools:  → (dropped if allowed-tools is set)
  - model:            → model:
  - description:      → description:
  + context: fork     → run in isolated subagent (like a real subagent)

Usage:  python3 scripts/generate-skills.py
"""

import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AGENTS_DIR = os.path.join(ROOT, "agents")
SKILLS_DIR = os.path.join(ROOT, "skills")


def parse_agent(path: str):
    """Return (frontmatter_dict, body_str) from an agent .md file."""
    with open(path, encoding="utf-8") as f:
        text = f.read()

    # Split on the two --- delimiters
    m = re.match(r"^---\n(.*?\n)---\n(.*)", text, re.DOTALL)
    if not m:
        return None, text

    raw_fm = m.group(1)
    body = m.group(2)

    # Simple YAML-ish parser for the flat fields we care about
    fm = {}
    current_key = None
    current_val = ""

    for line in raw_fm.split("\n"):
        # New key
        key_match = re.match(r"^(\w[\w-]*):\s*(.*)", line)
        if key_match:
            if current_key:
                fm[current_key] = current_val.strip()
            current_key = key_match.group(1)
            val = key_match.group(2)
            if val == ">":
                current_val = ""
            else:
                current_val = val
        elif current_key and line.startswith("  "):
            current_val += " " + line.strip()

    if current_key:
        fm[current_key] = current_val.strip()

    return fm, body


def build_skill_frontmatter(fm: dict) -> str:
    """Convert agent frontmatter to skill frontmatter."""
    lines = ["---"]

    name = fm.get("name", "unknown")
    lines.append(f"name: {name}")

    if "description" in fm:
        desc = fm["description"]
        lines.append("description: >")
        # Wrap description at ~90 chars, indent with exactly 2 spaces
        words = desc.split()
        line = ""
        for w in words:
            if line and len(line) + len(w) + 1 > 88:
                lines.append("  " + line)
                line = w
            else:
                line = line + " " + w if line else w
        if line:
            lines.append("  " + line)

    # Skills only support: name, description, argument-hint, compatibility,
    # disable-model-invocation, license, metadata, user-invocable.
    # No tool restrictions, model override, or fork context.

    lines.append("---")
    return "\n".join(lines)


def main():
    if not os.path.isdir(AGENTS_DIR):
        print(f"Error: {AGENTS_DIR} not found", file=sys.stderr)
        sys.exit(1)

    count = 0
    for fname in sorted(os.listdir(AGENTS_DIR)):
        if not fname.endswith(".md"):
            continue

        agent_path = os.path.join(AGENTS_DIR, fname)
        fm, body = parse_agent(agent_path)
        if fm is None:
            print(f"  ! Skipped {fname} (no frontmatter)")
            continue

        name = fm.get("name", fname.replace(".md", ""))
        skill_dir = os.path.join(SKILLS_DIR, name)
        os.makedirs(skill_dir, exist_ok=True)

        skill_content = build_skill_frontmatter(fm) + "\n" + body
        skill_path = os.path.join(skill_dir, "SKILL.md")

        with open(skill_path, "w", encoding="utf-8") as f:
            f.write(skill_content)

        print(f"  ✓ {name}/SKILL.md")
        count += 1

    print(f"\n  Generated {count} skills in skills/")


if __name__ == "__main__":
    main()
