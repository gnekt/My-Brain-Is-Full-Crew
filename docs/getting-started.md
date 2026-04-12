# Getting Started with My Brain Is Full - Crew

A step-by-step guide for setting up your AI-powered vault. No technical background required.

---

## What you need before starting

### Required
- **Obsidian**: A free note-taking app. Download it at [obsidian.md](https://obsidian.md)
- **An agent platform**: one of [Claude Code](https://claude.ai/code) (Pro/Max/Team), [Gemini CLI](https://github.com/google-gemini/gemini-cli), [OpenCode](https://opencode.ai), or [Codex CLI](https://openai.com/codex) (`npm i -g @openai/codex`).

  > **Windows + Codex CLI:** Codex CLI's Windows support is experimental. If you plan to use Codex CLI on Windows, run it inside WSL (Windows Subsystem for Linux) for the best experience.
- **An Obsidian vault**: This is just a folder on your computer where Obsidian stores your notes. If you don't have one yet, Obsidian will create one for you when you first open it.
- **Git**: A tool to download the project. On Mac, the terminal will prompt you to install it automatically the first time you use it. On Windows, download it from [git-scm.com](https://git-scm.com).

### Optional (but recommended)
- **Gmail account**: If you want the Postman agent to process your Gmail inbox (via GWS CLI or MCP)
- **Hey.com account**: If you use Hey for email (via Hey CLI) — works alongside or instead of Gmail
- **Google Calendar**: If you want calendar integration

---

## Step 1: Install Obsidian

1. Go to [obsidian.md](https://obsidian.md) and download the app for your system (Mac, Windows, or Linux)
2. Open Obsidian
3. If this is your first time, click **"Create new vault"**
4. Give it a name (e.g., "My Brain", "Second Brain", "Knowledge Base", whatever feels right)
5. Choose where to save it on your computer
6. Remember this location. You'll need it in Step 3

### Install recommended plugins

Inside Obsidian:
1. Go to **Settings** (gear icon, bottom left)
2. Click **Community plugins**
3. Click **Browse**
4. Search for and install these plugins:

**Essential (install these first):**
| Plugin | What it does |
|--------|-------------|
| **Templater** | Makes templates work with dynamic content (dates, etc.) |
| **Dataview** | Lets you query your notes like a database |
| **Calendar** | Visual calendar in the sidebar |
| **Tasks** | Better task management with due dates and queries |

**Recommended (install when ready):**
| Plugin | What it does |
|--------|-------------|
| **QuickAdd** | Rapid note capture |
| **Folder Notes** | Index notes for folders |
| **Tag Wrangler** | Manage and rename tags in bulk |
| **Periodic Notes** | Weekly and monthly review notes |
| **Omnisearch** | Better search across your vault |

Don't worry if this feels like a lot. The Architect agent will remind you about missing plugins during setup.

---

## Step 2: Install an agent platform

Install one of the following:

| Platform | Install | Subscription |
|----------|---------|-------------|
| **Claude Code** | [claude.ai/code](https://claude.ai/code) | Claude Pro, Max, or Team |
| **Gemini CLI** | [github.com/google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) | Google account |
| **OpenCode** | [opencode.ai](https://opencode.ai) | Varies by provider |
| **Codex CLI** | `npm i -g @openai/codex` | OpenAI account |

Claude Code works as both CLI and Desktop app (Cowork). The Crew works on all four supported platforms.

---

## Step 3: Install the Crew

Open your terminal and navigate to your Obsidian vault folder:

```bash
cd /path/to/your-vault
```

> **Not sure how to open the terminal?** On Mac, press `Command + Space`, type "Terminal", and press Enter. On Windows, press `Windows + R`, type "cmd", and press Enter.

Clone the repo inside your vault:

```bash
git clone https://github.com/gnekt/My-Brain-Is-Full-Crew.git
```

Run the installer:

```bash
cd My-Brain-Is-Full-Crew
bash scripts/launchme.sh
```

The script will ask a couple of questions:
1. **Which platform?** Select your agent platform (Claude Code, Gemini CLI, OpenCode, or Codex CLI)
2. **Is this your vault folder?** Confirm or enter the correct path

When it's done, your vault will look like this (paths vary by platform):

```
your-vault/
├── .<platform>/         ← .claude/, .gemini/, .opencode/
│   ├── agents/          ← 8 lightweight crew agents
│   ├── skills/          ← 14 specialized skills for complex flows
│   ├── hooks/           ← file protection and validation
│   └── references/      ← shared docs the agents read
├── CLAUDE.md / GEMINI.md / AGENTS.md  ← dispatcher (varies by platform)
├── My-Brain-Is-Full-Crew/  ← the repo (for future updates)
└── ... your Obsidian notes
```

**Codex CLI** uses a split layout instead of a single platform directory:

```
your-vault/
├── .codex/
│   ├── agents/          ← 8 core agents (.toml format)
│   ├── references/      ← shared docs
│   └── config.toml      ← MCP servers + profiles + sandbox policy
├── .agents/
│   └── skills/          ← 14 specialized skills
├── AGENTS.md            ← dispatcher
├── My-Brain-Is-Full-Crew/  ← the repo (for future updates)
└── ... your Obsidian notes
```

> **Something went wrong?** The most common issue is that `git` isn't installed. On Mac, the terminal will prompt you to install it automatically. On Windows, download it from [git-scm.com](https://git-scm.com). If you're stuck, just show this page to a tech-savvy friend. It takes 60 seconds.

---

## Step 4: Connect your vault

1. Open your agent platform (Claude Code, Gemini CLI, OpenCode, or Codex CLI)
2. Open it **inside your Obsidian vault folder**. This is important: the platform needs to be in your vault to read and write your notes.

If you're using a CLI tool:
```bash
cd /path/to/your-vault
claude          # or: gemini, opencode, codex
```

For Codex CLI, you can also use the `-C` flag to point directly at your vault:
```bash
codex -C /path/to/your-vault
```

If you're using Claude Code Desktop (Cowork), open the vault folder as your working directory.

---

## Step 5: Initialize your vault

This is the fun part. Just type:

> **"Initialize my vault"**

The `/onboarding` skill will kick in and the **Architect** will start a friendly conversation with you. It will ask:

### About you
- What should I call you?
- What's your preferred language?
- What do you do? (student, professional, creative, researcher...)
- What brought you here? (overwhelm, organization, health, productivity...)

### About your vault
- Are you new to Obsidian, or migrating from an existing vault?
- Do you want all 8 agents, or just some?
- What areas of your life do you want to manage?

### About integrations (optional)
- Do you want email triage? (requires Gmail via GWS/MCP, or Hey.com via Hey CLI)
- Do you want calendar integration? (requires Google Calendar via GWS/MCP)

After the conversation, the Architect creates your entire vault structure, saves your profile, and leaves you a personalized welcome note.

### Agent memory (Post-it)

Every agent has a small "post-it" file in `Meta/states/` where it jots down notes for its next run. This means agents remember what they did last time: the Sorter knows which files it already triaged, the Scribe remembers what you were brainstorming about, the Architect knows which onboarding step you were on if the conversation was interrupted.

You don't need to manage these files — agents handle them automatically. Each post-it is limited to 30 lines, so they never grow out of control.

---

## Step 6: Start using it

From now on, you just talk to your agent. Here are some things to try on your first day:

### Capture some thoughts
> "Save this: I had an idea about reorganizing the team standup. Maybe we should do async updates on Mondays and only meet on Wednesdays"

The **Scribe** will turn this into a clean note in your inbox.

### Dump several things at once
> "Quick notes: need to call the dentist, also Marco mentioned a book called Thinking Fast and Slow, and I should review the Q3 budget before Friday"

The **Scribe** detects multiple items and creates separate notes for each.

### Check your email
> "Check my email for anything important"

The `/email-triage` skill scans your inbox (Gmail or Hey.com), saves actionable emails, and gives you a summary.

### File everything
> "Triage my inbox"

The `/inbox-triage` skill processes all notes in your inbox and files them to the right places.

### Search your brain
> "What do I know about the Henderson project?"

The **Seeker** searches your vault and synthesizes an answer with source citations.

---

## Step 7: Build daily habits

The Crew works best with simple daily routines:

### Morning (2 minutes)
> "Check my calendar for today" to see what's ahead
> "Any messages from the crew?" to check if agents flagged anything

### Throughout the day
> Just dump thoughts as they come. The Scribe handles the rest.

### Evening (5 minutes)
> "Triage my inbox" to let the Sorter file everything

### Weekly (10 minutes)
> "Weekly review" to run the `/vault-audit` skill for a full vault health check

---

## Troubleshooting

### "The agent doesn't seem to activate"
Make sure your agent platform is open inside your vault folder (not a different directory). Verify agent files exist in the platform's agents directory (e.g., `.claude/agents/`). Try saying the trigger phrase differently. Agents and skills understand natural language in multiple languages.

### "Email/Calendar isn't working"
The Postman needs at least one email backend: GWS CLI (`gws`), Hey CLI (`hey`), or MCP connectors. For GWS, see `docs/gws-setup-guide.md`. For Hey, install from [github.com/basecamp/hey-cli](https://github.com/basecamp/hey-cli) and run `hey auth login`.

For MCP connectors:
- **Claude Code / OpenCode**: run the installer again (`bash scripts/launchme.sh`) and answer **yes** to the Gmail/Calendar question, or manually add the servers to your `.mcp.json` at the vault root.
- **Codex CLI**: MCP servers are configured in `.codex/config.toml` (not `.mcp.json`). Run `bash scripts/launchme.sh --platform codex-cli` and the installer writes them automatically. See [docs/codex-cli.md](codex-cli.md) for the full MCP setup details.

### "My vault structure looks different from the docs"
The Architect customizes the structure based on your onboarding answers.

### "How do I update to a new version?"

```bash
cd /path/to/your-vault/My-Brain-Is-Full-Crew
git pull
bash scripts/updateme.sh
```

For Codex CLI specifically:
```bash
bash scripts/updateme.sh --platform codex-cli
```

Only changed files are updated. Your vault notes are never touched.

### "An agent did something weird"
Open an issue on GitHub with:
1. What you asked
2. What happened
3. What you expected

### "I want to change my profile"
> "Update my profile" and the Architect will help you modify your settings

---

## Next steps

- **[Examples](examples.md)**: See real-world usage scenarios
- **[Codex CLI Guide](codex-cli.md)**: Install/update guide, architecture differences, runtime smoke matrix, and troubleshooting for Codex CLI
- **[Migrate to Codex CLI](codex-migration.md)**: Step-by-step migration from Claude Code, Gemini CLI, or OpenCode
- **[Mobile Access](mobile-access.md)**: Use the Crew from your phone
- **[Meet the Agents](agents/)**: Deep-dive into each agent's capabilities
- **[Contributing](../CONTRIBUTING.md)**: Help make the Crew better

---

*Remember: the best organizational system is the one you actually use. Start small. Talk to your agent. Let the Crew handle the rest.*
