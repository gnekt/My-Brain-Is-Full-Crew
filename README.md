# 🧠 Obsidian Vault Crew

**A team of AI agents that manage your Obsidian vault — so your brain doesn't have to.**

---

## The honest origin story

I'm a PhD researcher. I've spent years training my brain to hold enormous amounts of information — papers, ideas, deadlines, people, half-baked theories at 2am. And for a while, it worked.

Then it didn't.

Memory started slipping. Not dramatically — no diagnosis, no crisis — just the slow, creeping realization that the mental RAM was getting full, and things were falling through the cracks. I'd forget what I'd read. Lose track of conversations. Start projects I'd already started. Feel constantly behind, constantly overwhelmed.

I started looking for solutions. I found a lot of Obsidian + Claude setups online. They were mostly clever note-capture tools, glorified search engines for your second brain. Useful. But not what I needed.

What I needed wasn't just a memory extension. I needed a **brain dump system** — something that could help me organize not just my knowledge, but my life: my overwhelmed mind, my wrecked physical health, the avalanche of emails and commitments and things I should have done last week.

So I built this.

---

## What makes this different

Most Obsidian + AI tools are **for people who already have their life together** and want to optimize. This one is for people who are **drowning** and need a lifeline.

A few things that set this apart:

**1. The chat IS the interface.**
I don't browse Obsidian. I don't drag files around. I don't maintain complex folder structures manually. I just talk to Claude. Everything else happens automatically.

**2. It's not just knowledge management.**
The Crew includes a **personal nutritionist** (because my physical health was falling apart too) and a **mental health support agent** trained in CBT, ACT, and Mindfulness (because the two things are connected). These aren't gimmicks — they're agents with real depth that communicate with each other.

**3. It speaks your language — literally.**
Initial skills are in Italian because that's my native language. The system is designed for non-native English speakers. You shouldn't need to think in English to manage your brain. Multi-language support is a first-class feature, not an afterthought.

**4. The agents talk to each other.**
When the nutritionist notices you're stress-eating, it sends a message to the therapist. When the transcription agent processes a meeting, it flags follow-up tasks for the inbox manager. It's a crew, not a collection of isolated tools.

---

## Meet the Crew

| Agent | Role | What it does |
|-------|------|------|
| 📝 **Scriba** | Text capture | Turns your messy, fast-typed thoughts into clean Obsidian notes |
| 📥 **Smistatore** | Inbox triage | Empties your inbox every evening, routes notes to the right place |
| 🔍 **Cercatore** | Search & retrieval | Finds anything in your vault, answers questions with citations |
| 🏛️ **Architetto** | Vault structure | Designs your folder system, templates, and naming conventions |
| 🔗 **Connettore** | Knowledge graph | Finds missing links between notes, kills orphan notes |
| 📚 **Bibliotecario** | Weekly maintenance | Runs vault health checks, fixes broken links, merges duplicates |
| 🎤 **Trascrittore** | Transcription | Turns audio recordings and raw transcripts into structured meeting notes |
| 📬 **Postino** | Gmail + Calendar | Processes your inbox and calendar into the vault |
| 🥗 **Dietologo** | Nutrition coach | Personal nutritionist — meal plans, shopping lists, progress tracking |
| 🧘 **Psicoterapeuta** | Mental health support | CBT + ACT + Mindfulness support — for when your brain needs a hand |

---

## Who this is for

- PhD students, researchers, academics drowning in papers and commitments
- Anyone with **brain fog**, ADHD, or just an overloaded working memory
- People managing health challenges alongside cognitive work
- Non-native English speakers who want a system that works in their language
- Anyone who's tried Obsidian before and gave up because it felt like a second job

If you've ever thought *"I need to get organized, but I'm too exhausted to get organized"* — this is for you.

---

## How it works

The plugin runs inside **Claude's Cowork mode**. You connect it to your Obsidian vault folder, and you interact entirely through chat. No GUI, no drag-and-drop, no manual file management.

```
You → Claude chat → Agent picks up your intent → Does the work → Updates your vault
```

The vault structure is a hybrid **PARA + Zettelkasten** system:

```
00-Inbox/       → Everything new lands here first
01-Projects/    → Active projects with deadlines
02-Areas/       → Ongoing responsibilities (including Health)
03-Resources/   → Reference material
04-Archive/     → Completed / historical content
05-People/      → Personal CRM
06-Meetings/    → Meeting notes
07-Daily/       → Daily notes
MOC/            → Maps of Content (thematic indexes)
Templates/      → Obsidian templates
Meta/           → Vault health, agent messages
```

---

## Getting started

1. Install the plugin in Claude's Cowork mode
2. Mount your Obsidian vault folder
3. Say **"inizializza il vault"** (or "initialize the vault") — the Architetto sets everything up
4. Start dumping thoughts — paste text for the Scriba, upload audio for the Trascrittore
5. Say **"smista la inbox"** at the end of the day
6. Say **"review settimanale"** once a week
7. Connect Gmail and Google Calendar to activate the Postino

---

## Required connectors

The **Postino** agent requires two connected services:
- **Gmail** — to read and process your inbox
- **Google Calendar** — to import events and manage your schedule

Both are bundled with the plugin.

---

## Recommended Obsidian plugins

**Essential:** Templater, Dataview, Calendar, Tasks

**Recommended:** QuickAdd, Folder Notes, Tag Wrangler, Natural Language Dates, Periodic Notes, Omnisearch, Linter

---

## On the health and mental wellness agents

I want to be transparent about what these agents are and aren't.

The **Dietologo** is a nutrition support tool. It helps with meal planning, shopping lists, calorie awareness, and motivation. It is not a substitute for a dietitian or doctor. If you have medical conditions affecting your diet, please consult a professional.

The **Psicoterapeuta** is a mental health support agent trained in CBT, ACT, and Mindfulness techniques. It is explicitly designed to **support** (not replace) professional therapy. It won't diagnose you. It will listen, help you apply evidence-based techniques, and actively encourage you to bring insights to your real therapist.

I built these because I needed them. They've been genuinely helpful. But they come with the same caveat every responsible tool comes with: if you're in crisis, please reach out to a real human.

---

## Languages

Current skills are written in Italian (with English skill descriptions for discoverability). The system is language-aware — agents respond in the language you write in.

The roadmap includes skill variants for other languages. If you want to contribute a translation, see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Structure of this repo

```
obsidian-vault-crew/
├── plugin.json                  → Plugin manifest
├── references/
│   ├── agents.md                → Agent registry and inter-agent communication
│   └── inter-agent-messaging.md → Messaging protocol between agents
└── skills/
    ├── architetto/SKILL.md
    ├── bibliotecario/SKILL.md
    ├── cercatore/SKILL.md
    ├── connettore/SKILL.md
    ├── dietologo/SKILL.md
    ├── postino/SKILL.md
    ├── psicoterapeuta/SKILL.md
    ├── scriba/SKILL.md
    ├── smistatore/SKILL.md
    └── trascrittore/SKILL.md
```

---

## Contributing

This started as a very personal project to fix a very personal problem. But the problems it tries to solve — overwhelm, memory, health, the feeling that you're always behind — are pretty universal.

If you:
- Want to translate skills into your language
- Have a skill idea (a new crew member)
- Found a bug or want to improve a skill

...PRs and issues are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT — do whatever you want with it, just don't remove the attribution.

---

*Built by a PhD who got tired of forgetting things.*
