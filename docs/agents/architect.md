# Architect

> Your vault's foundation, blueprint, and building code -- all in one agent.

## What it does

The Architect is the first agent you meet and the one that shapes everything else. When you start fresh, the Architect runs you through a friendly onboarding conversation -- not a boring form, but a real back-and-forth where it learns who you are, what you do, and what you need from your vault. Based on your answers, it builds a personalized folder structure, creates templates, sets up naming conventions, and establishes a tag system that every other agent follows.

Beyond onboarding, the Architect is your vault's structural authority. Whenever a new project needs a home, a new area of your life emerges, or your existing structure starts feeling cramped, the Architect steps in. It creates folders, designs templates, updates the rules, and makes sure every agent in the crew knows about the changes.

Think of it as the urban planner of your knowledge city. It decides where things go, how streets are named, and what the building codes are -- so everyone else can do their job without chaos.

## Capabilities

- **Full vault onboarding** -- a guided, conversational setup that creates your entire vault from scratch based on your answers
- **User profile creation** -- saves your preferences, language, goals, and context so every agent can serve you better
- **Folder management** -- creates, restructures, and archives folders as your life evolves
- **Template management** -- builds and maintains Templater-compatible templates for meetings, ideas, tasks, projects, people, daily notes, and more
- **Tag taxonomy** -- maintains the official tag list, enforces naming rules, and prevents tag sprawl
- **Naming conventions** -- defines and documents how files, folders, and tags are named
- **MOC (Map of Content) creation** -- creates index notes that tie related topics together
- **Vault evolution** -- detects when your structure needs to grow, split, or simplify, and proposes changes
- **Profile updates** -- updates your preferences anytime (new job, new language, activating a new agent)
- **Plugin recommendations** -- suggests essential and optional Obsidian plugins with clear reasons for each
- **Health module setup** -- if you opt into the Food Coach or Wellness Guide, creates their dedicated workspace with all the right files
- **Multilingual support** -- responds in whatever language you write in

## How to use it

Start a conversation with any of these phrases (in any language):

- "Initialize my vault" / "Set up the vault" / "Onboarding"
- "Create a new project folder for [name]"
- "I need a new area for [topic]"
- "Add a template for [type]"
- "Update the tag taxonomy"
- "Restructure my vault"
- "I changed jobs -- update my profile"
- "Activate the Food Coach agent"
- "Create a MOC for [topic]"

In Italian: "Inizializza il vault", "Nuovo progetto", "Configura il vault"
In French: "Initialiser le vault", "Nouveau projet"
In Spanish: "Inicializar el vault", "Nuevo proyecto"
In German: "Vault initialisieren", "Neues Projekt"

## Example conversations

### First-time setup

**You:** Initialize my vault

**Architect:** Welcome! I am the Architect -- I will help you build your personal knowledge vault from the ground up. Before I create any folders or files, I want to understand who you are and how you work. This will take about 5 minutes, and everything you tell me will be saved so every agent in the crew can serve you better.

Let's start with the basics. What should I call you?

**You:** Call me Alex

**Architect:** Nice to meet you, Alex. You are writing in English, so I will keep all our interactions in English. Do you speak any other languages you might use in your vault -- notes, meetings, or sources in other languages?

**You:** I sometimes take notes in Italian

**Architect:** Got it -- English primary, Italian secondary. Now, what do you do? Are you a student, researcher, professional, creative...?

*(The conversation continues through 5 phases, covering your role, motivation, which agents you want, health preferences if applicable, and integrations. At the end, the Architect creates your full vault structure.)*

---

### Adding a new project

**You:** Create a new project folder for Project Alpha

**Architect:** I will create a folder for Project Alpha at `01-Projects/Alpha/`. Here is what I will set up:

- `01-Projects/Alpha/` -- main project folder
- A project index note using the Project template
- An entry in the Projects MOC

I will also update `Meta/vault-structure.md` and notify the Sorter that a new filing destination exists.

Shall I proceed?

---

### Evolving the vault

**You:** Update the tag taxonomy -- I keep seeing tags that don't make sense

**Architect:** Let me audit the current tag taxonomy. I found 3 issues:

1. Both `#ml` and `#machine-learning` are in use -- I recommend keeping `#machine-learning` and replacing all instances of `#ml`
2. `#misc` is used on 12 notes -- this is too vague. I suggest reviewing those notes and assigning more specific tags
3. `#meeting-notes` exists alongside `#meeting` -- I recommend consolidating to `#meeting`

Want me to apply these changes?

## Works with

- **Every agent** reads the rules the Architect creates (naming conventions, tag taxonomy, vault structure)
- **Scribe** uses the templates the Architect maintains
- **Sorter** follows the folder structure for filing decisions
- **Librarian** references all Meta files when auditing vault health
- **Connector** uses the MOC structure for link suggestions
- **Postman** checks your profile for integration settings (Gmail, Calendar)
- **Food Coach** and **Wellness Guide** operate in workspaces the Architect creates during onboarding

## Tips

- **Run onboarding first.** The Architect is designed to be the very first thing you use. Other agents depend on the structure and profile it creates.
- **Don't skip the health questions.** If you activate the Food Coach or Wellness Guide later, you will have to answer them anyway. Doing it during onboarding is smoother.
- **Ask for restructuring when things feel messy.** If you notice notes piling up in the wrong places or tags multiplying, ask the Architect to audit and evolve the structure.
- **Update your profile when your life changes.** New job? New language? New goal? Tell the Architect so every agent stays in sync.
- **Start small.** You do not need all 10 agents on day one. Start with the core (Architect, Scribe, Sorter, Seeker) and add more as your vault grows.
