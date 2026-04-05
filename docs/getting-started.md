# Getting Started with My Brain Is Full - Crew

A step-by-step guide for setting up your AI-powered vault. No technical background required.

---

## What you need before starting

### Required
- **Obsidian**: A free note-taking app. Download it at [obsidian.md](https://obsidian.md)
- **GitHub Copilot**: GitHub's AI coding assistant. You need a Copilot Pro, Business, or Enterprise subscription.
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

## Step 2: Install GitHub Copilot in VS Code

1. Download [VS Code](https://code.visualstudio.com/) if you don't have it
2. Install the [GitHub Copilot extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)
3. Install the [GitHub Copilot Chat extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
4. Sign in with your GitHub account (you need a **Copilot Pro**, **Business**, or **Enterprise** subscription)

---

## Step 3: Install the Crew

Open your terminal and navigate to your Obsidian vault folder:

```bash
cd /path/to/your-vault
```

> **Not sure how to open the terminal?** On Mac, press `Command + Space`, type "Terminal", and press Enter. On Windows, press `Windows + R`, type "cmd", and press Enter.

Clone the repo inside your vault:

```bash
git clone https://github.com/Mikehutu/Second-brain-crew.git
```

Run the installer:

```bash
cd Second-brain-crew
bash scripts/launchme.sh
```

The script will ask two quick questions:
1. **Is this your vault folder?** Confirm or enter the correct path
2. **Do you use Gmail, Hey.com, or Google Calendar?** Choose yes to set up the Postman integration

When it's done, your vault will look like this:

```
your-vault/
├── .github/
│   ├── copilot-instructions.md  ← dispatcher instructions (auto-loaded by Copilot)
│   ├── agents/                  ← 8 crew agent instruction files
│   ├── skills/                  ← 13 specialized skill instruction files
│   └── references/              ← shared docs the agents read
├── .vscode/settings.json        ← VS Code Copilot settings
├── .mcp.json                    ← Gmail + Calendar (only if you said yes)
├── Second-brain-crew/           ← the repo (for future updates)
└── ... your Obsidian notes
```

> **Something went wrong?** The most common issue is that `git` isn't installed. On Mac, the terminal will prompt you to install it automatically. On Windows, download it from [git-scm.com](https://git-scm.com). If you're stuck, just show this page to a tech-savvy friend. It takes 60 seconds.

---

## Step 4: Connect your vault

1. Open VS Code
2. Open your Obsidian vault folder: **File → Open Folder** and select your vault. This is important: Copilot needs to be in your vault to read the crew instructions and write your notes.

```bash
# Or from the terminal:
cd /path/to/your-vault
code .
```

---

## Step 5: Initialize your vault

This is the fun part. Open GitHub Copilot Chat (`Ctrl+Shift+I` / `Cmd+Shift+I`) and type:

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

From now on, you just talk to GitHub Copilot. Here are some things to try on your first day:

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
Make sure VS Code is open inside your vault folder (not a different directory). Verify agent files exist at `.github/agents/` and skill files at `.github/skills/` in your vault. Verify that `.github/copilot-instructions.md` exists. Try saying the trigger phrase differently. Agents and skills understand natural language in multiple languages.

### "Email/Calendar isn't working"
The Postman needs at least one email backend: GWS CLI (`gws`), Hey CLI (`hey`), or MCP connectors. For GWS, see `docs/gws-setup-guide.md`. For Hey, install from [github.com/basecamp/hey-cli](https://github.com/basecamp/hey-cli) and run `hey auth login`. For MCP, run the installer again (`bash scripts/launchme.sh`) and answer **yes** to the Gmail/Calendar question, or manually copy `.mcp.json` from the repo to your vault root.

### "My vault structure looks different from the docs"
The Architect customizes the structure based on your onboarding answers.

### "How do I update to a new version?"

```bash
cd /path/to/your-vault/Second-brain-crew
git pull
bash scripts/updateme.sh
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
- **[Mobile Access](mobile-access.md)**: Use the Crew from your phone
- **[Meet the Agents](agents/)**: Deep-dive into each agent's capabilities
- **[Contributing](../CONTRIBUTING.md)**: Help make the Crew better

---

*Remember: the best organizational system is the one you actually use. Start small. Talk to GitHub Copilot. Let the Crew handle the rest.*
