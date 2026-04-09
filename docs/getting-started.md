# Getting Started with My Brain Is Full - Crew

A step-by-step guide for setting up your AI-powered vault. No technical background required.

---

## What you need before starting

### Required
- **Obsidian**: A free note-taking app. Download it at [obsidian.md](https://obsidian.md)
- **A supported AI platform**: **Claude Code**, **OpenCode**, **Gemini CLI**, or **Codex CLI**
- **An Obsidian vault**: This is just a folder on your computer where Obsidian stores your notes. If you don't have one yet, Obsidian will create one for you when you first open it.
- **Git**: A tool to download the project. On Mac, the terminal will prompt you to install it automatically the first time you use it. On Windows, download it from [git-scm.com](https://git-scm.com).

If you choose **Claude Code**, you need a Claude Pro, Max, or Team subscription.

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

## Step 2: Install your AI tool

Install the AI tool you want to use with the Crew:

- **Claude Code**: [claude.ai/code](https://claude.ai/code)
- **OpenCode**
- **Gemini CLI**
- **Codex CLI**

The installer supports all four platforms. Claude Code works with either the Desktop app (Cowork) or the CLI.

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

In the stock interactive flow, the installer will:
1. Ask which supported platform you want to install
2. Confirm your vault folder (or let you enter a different path)
3. If you choose OpenCode, Gemini CLI, or Codex CLI, prompt for model preferences for that platform
4. For Claude installs, optionally offer Gmail + Calendar MCP setup

If you want more control, `launchme.sh` also supports advanced flags such as:

```bash
# Install for a specific platform without prompts
bash scripts/launchme.sh --platform claude --yes

# Point the installer at a specific vault
bash scripts/launchme.sh --vault /path/to/vault

# Override model selections directly
bash scripts/launchme.sh --platform gemini --model-fast gemini-2.5-flash

# Load model overrides from a file
bash scripts/launchme.sh --platform opencode --overrides ./my-models.env
```

> **Platform note:** OpenCode and Codex CLI both use the root `AGENTS.md` dispatcher. With the stock installer, use only one of them per vault.

When it's done, your vault will contain a platform directory plus the matching dispatcher file. For a Claude Code install, it looks like this:

```
your-vault/
├── .claude/
│   ├── agents/          ← 8 lightweight crew agents
│   ├── skills/          ← 14 specialized skills for complex flows
│   └── references/      ← shared docs the agents read
├── CLAUDE.md            ← project instructions
├── .mcp.json            ← Gmail + Calendar (only if you said yes)
├── My-Brain-Is-Full-Crew/  ← the repo (for future updates)
└── ... your Obsidian notes
```

> **Something went wrong?** The most common issue is that `git` isn't installed. On Mac, the terminal will prompt you to install it automatically. On Windows, download it from [git-scm.com](https://git-scm.com). If you're stuck, just show this page to a tech-savvy friend. It takes 60 seconds.

Other platforms follow the same general structure with their own platform directory. Claude uses `CLAUDE.md`, Gemini uses `GEMINI.md`, and OpenCode/Codex each use `AGENTS.md` when installed individually.

---

## Step 4: Connect your vault

1. Open your chosen AI tool
2. Open it **inside your Obsidian vault folder**. This is important: the tool needs to be in your vault to read and write your notes.

If you're using a CLI tool, open your terminal in the vault folder before launching it.

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

From now on, you just talk to your AI tool. Here are some things to try on your first day:

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
Make sure your AI tool is open inside your vault folder (not a different directory). Verify the installed platform directory exists in your vault (for example, `.claude/agents/` and `.claude/skills/` for Claude Code). Try saying the trigger phrase differently. Agents and skills understand natural language in multiple languages.

### "Email/Calendar isn't working"
The Postman needs at least one email backend: GWS CLI (`gws`), Hey CLI (`hey`), or MCP connectors. For GWS, see `docs/gws-setup-guide.md`. For Hey, install from [github.com/basecamp/hey-cli](https://github.com/basecamp/hey-cli) and run `hey auth login`. For Claude Code installs, you can run the installer again (`bash scripts/launchme.sh`) and answer **yes** to the Gmail/Calendar question, or manually copy `.mcp.json` from the repo to your vault root.

### "My vault structure looks different from the docs"
The Architect customizes the structure based on your onboarding answers.

### "How do I update to a new version?"

```bash
cd /path/to/your-vault/My-Brain-Is-Full-Crew
git pull
bash scripts/updateme.sh
```

Only changed files are updated. Your vault notes are never touched.

### "The installer says OpenCode and Codex can't be used together"
That message is expected with the stock scripts. OpenCode and Codex CLI both manage the root `AGENTS.md` dispatcher, so the installer and updater allow only one of them per vault at a time. If you want to switch, remove the existing stock install first. If you want both in one vault, you need your own custom dispatcher setup.

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
- **[Mobile Access](mobile-access.md)**: Use the Crew from your phone
- **[Meet the Agents](agents/)**: Deep-dive into each agent's capabilities
- **[Contributing](../CONTRIBUTING.md)**: Help make the Crew better

---

*Remember: the best organizational system is the one you actually use. Start small. Talk to Claude. Let the Crew handle the rest.*
