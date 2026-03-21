# Getting Started with My Brain Is Full - Crew

A step-by-step guide for setting up your AI-powered vault — no technical background required.

---

## What you need before starting

### Required
- **Obsidian** — A free note-taking app. Download it at [obsidian.md](https://obsidian.md)
- **Claude Code** — Anthropic's coding assistant with Cowork mode. You need a Claude Pro or Team subscription.
- **An Obsidian vault** — This is just a folder on your computer where Obsidian stores your notes. If you don't have one yet, Obsidian will create one for you when you first open it.

### Optional (but recommended)
- **Gmail account** — If you want the Postman agent to process your emails
- **Google Calendar** — If you want calendar integration

---

## Step 1: Install Obsidian

1. Go to [obsidian.md](https://obsidian.md) and download the app for your system (Mac, Windows, or Linux)
2. Open Obsidian
3. If this is your first time, click **"Create new vault"**
4. Give it a name (e.g., "My Brain", "Second Brain", "Knowledge Base" — whatever feels right)
5. Choose where to save it on your computer
6. Remember this location — you'll need it in Step 3

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

Don't worry if this feels like a lot — the Architect agent will remind you about missing plugins during setup.

---

## Step 2: Install Claude Code

1. Go to [claude.ai/code](https://claude.ai/code) and follow the instructions to install Claude Code
2. You need a **Claude Pro**, **Max**, or **Team** subscription
3. You can use either the **Desktop app** or the **CLI** (command-line interface)

---

## Step 3: Install the Crew

Choose the method that feels most comfortable:

### Method A: Desktop app (recommended — no terminal needed)

1. Download the plugin: go to [github.com/gnekt/My-Brain-Is-Full-Crew](https://github.com/gnekt/My-Brain-Is-Full-Crew), click the green **Code** button, then **Download ZIP**
2. Unzip the downloaded file (double-click it)
3. Open **Claude Code Desktop**
4. Go to **Customize** (or **Personalizza**) in the sidebar
5. Under **Personal plugins**, click the **+** button
6. Click **Load local plugin**
7. Select the unzipped folder
8. Done! All 10 agents are loaded

> The Gmail and Google Calendar connections for the Postman agent are pre-configured in the plugin — you'll be prompted to authorize them when you first use email features.

### Method B: Terminal (for CLI users)

Open your terminal and type these 3 commands, pressing Enter after each one:

```bash
git clone https://github.com/gnekt/My-Brain-Is-Full-Crew.git
```

This downloads the project to your computer. Then:

```bash
mkdir -p ~/.claude/agents
```

This creates the folder where Claude Code looks for agents (if it doesn't exist already). Finally:

```bash
cp My-Brain-Is-Full-Crew/agents/*.md ~/.claude/agents/
```

This copies all 10 agents into that folder. **Done!** The agents are now permanently available every time you use Claude Code.

> **Note for CLI users:** This installs only the agents. To also get Gmail/Calendar integration for the Postman, either load as a full plugin with `claude --plugin-dir /path/to/My-Brain-Is-Full-Crew`, or manually configure Gmail and Google Calendar MCP servers.

> **Something went wrong?** The most common issue is that `git` isn't installed. On Mac, the terminal will prompt you to install it automatically. On Windows, download it from [git-scm.com](https://git-scm.com). If you're stuck, just show this page to a tech-savvy friend — it takes 30 seconds.

---

## Step 4: Connect your vault

1. Open Claude Code
2. Navigate to your Obsidian vault folder, or tell Claude where it is (e.g., *"My vault is at /Users/me/Documents/MyBrain"*)

Claude now has access to read and write files in your vault.

---

## Step 5: Initialize your vault

This is the fun part. Just type:

> **"Initialize my vault"**

The **Architect** agent will wake up and start a friendly conversation with you. It will ask:

### About you
- What should I call you?
- What's your preferred language?
- What do you do? (student, professional, creative, researcher...)
- What brought you here? (overwhelm, organization, health, productivity...)

### About your vault
- Are you new to Obsidian, or migrating from an existing vault?
- Do you want all 10 agents, or just some?
- What areas of your life do you want to manage?

### About your health (optional)
If you opt in to the health agents:
- **Food Coach setup**: height, weight, age, goals, dietary restrictions, food preferences
- **Wellness Guide setup**: whether you see a therapist, what concerns you want to address, preferred approaches

### About integrations (optional)
- Do you want email triage? (requires Gmail connection)
- Do you want calendar integration? (requires Google Calendar connection)

After the conversation, the Architect creates your entire vault structure, saves your profile, and leaves you a personalized welcome note.

---

## Step 6: Start using it

From now on, you just talk to Claude. Here are some things to try on your first day:

### Capture some thoughts
> "Save this: I had an idea about reorganizing the team standup — maybe we should do async updates on Mondays and only meet on Wednesdays"

The **Scribe** will turn this into a clean note in your inbox.

### Dump several things at once
> "Quick notes: need to call the dentist, also Marco mentioned a book called Thinking Fast and Slow, and I should review the Q3 budget before Friday"

The **Scribe** detects multiple items and creates separate notes for each.

### Check your email
> "Check my email for anything important"

The **Postman** scans your Gmail, saves actionable emails, and gives you a summary.

### File everything
> "Triage my inbox"

The **Sorter** processes all notes in your inbox and files them to the right places.

### Search your brain
> "What do I know about the Henderson project?"

The **Seeker** searches your vault and synthesizes an answer with source citations.

### Get meal ideas
> "What should I eat this week? I have chicken, rice, and a lot of vegetables in the fridge"

The **Food Coach** creates a personalized meal plan.

### Decompress
> "I'm feeling overwhelmed and can't focus"

The **Wellness Guide** guides you through grounding techniques.

---

## Step 7: Build daily habits

The Crew works best with simple daily routines:

### Morning (2 minutes)
> "Check my calendar for today" — see what's ahead
> "Any messages from the crew?" — check if agents flagged anything

### Throughout the day
> Just dump thoughts as they come. The Scribe handles the rest.

### Evening (5 minutes)
> "Triage my inbox" — let the Sorter file everything
> "How was my day?" — the Wellness Guide helps you reflect (optional)

### Weekly (10 minutes)
> "Weekly review" — the Librarian runs a full vault health check
> "Show my diet progress" — the Food Coach gives you a progress report (optional)

---

## Troubleshooting

### "The agent doesn't seem to activate"
Make sure the plugin is installed correctly. Try `/plugin` to check if `my-brain-is-full-crew` appears in your installed plugins. If you used the manual copy method, verify the agent files are in `~/.claude/agents/`. Try saying the trigger phrase differently — agents understand natural language in multiple languages.

### "Gmail/Calendar isn't working"
The Postman needs Gmail and Google Calendar MCP connectors configured in Claude Code. Check your MCP settings.

### "My vault structure looks different from the docs"
The Architect customizes the structure based on your onboarding answers. If you opted out of health agents, for example, the Health folder won't be created.

### "How do I update to a new version?"
Run the same 3 commands from Step 3 again — the new files will overwrite the old ones. If you still have the cloned folder, you can also run `cd My-Brain-Is-Full-Crew && git pull` and then re-copy.

### "An agent did something weird"
Open an issue on GitHub with:
1. What you asked
2. What happened
3. What you expected

### "I want to change my profile"
> "Update my profile" — the Architect will help you modify your settings

---

## Next steps

- **[Examples](examples.md)** — See real-world usage scenarios
- **[Meet the Agents](agents/)** — Deep-dive into each agent's capabilities
- **[Contributing](../CONTRIBUTING.md)** — Help make the Crew better

---

*Remember: the best organizational system is the one you actually use. Start small. Talk to Claude. Let the Crew handle the rest.*
