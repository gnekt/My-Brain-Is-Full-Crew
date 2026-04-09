# Getting Started with My Brain Is Full - Crew

A step-by-step guide for setting up your AI-powered vault. No technical background required.

---

## What you need before starting

### Required
- **Obsidian**: A free note-taking app. Download it at [obsidian.md](https://obsidian.md)
- **Codex**: the CLI workspace host that runs the Crew inside your vault.
- **An Obsidian vault**: This is just a folder on your computer where Obsidian stores your notes. If you don't have one yet, Obsidian will create one for you when you first open it.
- **Git**: A tool to download the project. On Mac, the terminal will prompt you to install it automatically the first time you use it. On Windows, download it from [git-scm.com](https://git-scm.com).

### Optional (future migration only)
- **Gmail / Hey.com / Google Calendar preferences**: You can record these during onboarding for a later Postman migration phase, but external integrations are not active in the current Codex runtime

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

## Step 2: Install Codex

1. Install Codex in the environment where you already use it for local workspace work
2. Make sure Codex can open and work inside local folders on your machine
3. The Crew currently targets **Codex CLI workspace mode**

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

The script will ask for the target vault path and then install the local Codex runtime into that vault.

When it's done, your vault will look like this:

```
your-vault/
├── .codex/
│   ├── agents/          ← 7 active agents + 1 migration-gated Postman role
│   ├── skills/          ← 9 active skills + 4 migration-gated Postman skills
│   └── references/      ← shared docs the agents read
├── AGENTS.md            ← project instructions
├── My-Brain-Is-Full-Crew/  ← the repo (for future updates)
└── ... your Obsidian notes
```

> **Something went wrong?** The most common issue is that `git` isn't installed. On Mac, the terminal will prompt you to install it automatically. On Windows, download it from [git-scm.com](https://git-scm.com). If you're stuck, just show this page to a tech-savvy friend. It takes 60 seconds.

---

## Step 4: Connect your vault

1. Open Codex
2. Open it **inside your Obsidian vault folder**. This is important: Codex needs to be in your vault to read and write your notes.

If you're using the CLI:
```bash
cd /path/to/your-vault
codex
```

If you use another Codex launcher, make sure the working directory is your vault root.

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
- Do you want all 7 active agents, or just some?
- What areas of your life do you want to manage?

### About future integrations (optional)
- Do you want to record email preferences for a future Postman migration phase?
- Do you want to record calendar preferences for a future Postman migration phase?

After the conversation, the Architect creates your entire vault structure, saves your profile, and leaves you a personalized welcome note.

### Agent memory (Post-it)

Every agent has a small "post-it" file in `Meta/states/` where it jots down notes for its next run. This means agents remember what they did last time: the Sorter knows which files it already triaged, the Scribe remembers what you were brainstorming about, the Architect knows which onboarding step you were on if the conversation was interrupted.

You don't need to manage these files — agents handle them automatically. Each post-it is limited to 30 lines, so they never grow out of control.

---

## Step 6: Start using it

From now on, you just talk to Codex. Here are some things to try on your first day:

### Capture some thoughts
> "Save this: I had an idea about reorganizing the team standup. Maybe we should do async updates on Mondays and only meet on Wednesdays"

The **Scribe** will turn this into a clean note in your inbox.

### Dump several things at once
> "Quick notes: need to call the dentist, also Marco mentioned a book called Thinking Fast and Slow, and I should review the Q3 budget before Friday"

The **Scribe** detects multiple items and creates separate notes for each.

### Ask about future integrations
> "Do we already support email triage in Codex?"

The dispatcher will explain that Postman workflows are migration-gated for now.

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
> "What needs my attention today?" to see what the active vault agents already know
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
Make sure Codex is open inside your vault folder (not a different directory). Verify agent files exist at `.codex/agents/` and skill files at `.codex/skills/` in your vault. Try saying the trigger phrase differently. Agents and skills understand natural language in multiple languages.

### "Email/Calendar isn't working"
That is expected in the current Codex migration runtime. Postman workflows are intentionally migration-gated. You can still record your future integration preferences during onboarding, but live email/calendar automation is not active yet.

### "My vault structure looks different from the docs"
The Architect customizes the structure based on your onboarding answers.

### "How do I update to a new version?"

```bash
cd /path/to/your-vault/My-Brain-Is-Full-Crew
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

*Remember: the best organizational system is the one you actually use. Start small. Talk to Codex in your vault. Let the Crew handle the rest.*
