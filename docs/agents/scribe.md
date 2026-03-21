# Scribe

> Your fast-thinking, clean-writing note-taking partner.

## What it does

The Scribe turns messy, rushed, half-formed thoughts into clean Obsidian notes. You type fast, you skip punctuation, you mix languages, you abbreviate everything -- the Scribe does not care. It takes whatever you throw at it and produces polished, well-structured notes ready for your vault.

It is smart about what it captures. If you dump three unrelated topics in one message, it splits them into three separate notes. If you paste speech-to-text output full of "um" and "like," it cleans it up while keeping your voice. If you are rapid-firing ideas in brainstorm mode, it numbers them all without judging any.

Every note the Scribe creates lands in your Inbox (`00-Inbox/`), properly formatted with YAML frontmatter, tags, wikilinks to people and projects, and suggested connections to other notes. The Sorter will file them later -- the Scribe's job is pure capture speed and quality.

## Capabilities

- **Standard capture** -- classifies your input (idea, task, note, person, reference, list) and applies the right template
- **Voice-to-note** -- detects speech-to-text output and cleans it up: removes filler words, restores punctuation, preserves your natural voice
- **Thread capture** -- when you send a stream of consciousness, splits it into individual atomic notes linked together
- **Quote capture** -- formats quotes with author, source, page number, and your commentary
- **Reading notes** -- structures book/article/podcast notes with key takeaways, section-by-section summaries, and action items
- **Brainstorm mode** -- captures everything without filtering, numbers ideas, groups by theme, highlights the most promising ones
- **Multi-note detection** -- automatically splits unrelated topics into separate notes
- **Emotion tagging** -- detects emotional tone and tags it for the Wellness Guide to track patterns
- **Auto-suggested connections** -- mentions 2-3 related notes or topics at the end of each note
- **Code, math, and diagram support** -- wraps code in fenced blocks, uses LaTeX for math, creates Mermaid diagrams
- **Multilingual** -- works in any language, handles mixed-language input gracefully

## How to use it

Just start typing what you want to capture. The Scribe detects the right mode automatically. You can also be explicit:

- "Save this: [your text]"
- "Quick note: [your text]"
- "Brainstorm: [topic]"
- "Quote: [quote text]"
- "Reading notes for [book/article title]"
- "Thread: [stream of thoughts]"
- "Voice note: [pasted speech-to-text]"

In Italian: "Salvami questo", "Nota veloce", "Appuntati"
In French: "Sauvegarde ca", "Note rapide"
In Spanish: "Guarda esto", "Nota rapida"
In German: "Schnelle Notiz", "Schreib das"

## Example conversations

### Quick messy capture

**You:** save this: meeting with Marco, budget discussion, he wants report by friday, also mentioned new hire starting in april, seems worried about Q2 numbers

**Scribe:** I identified 2 distinct topics and created 2 separate notes:

**1. Meeting With Marco -- Budget Discussion**
Filed as `2026-03-21 -- Note -- Budget Discussion With Marco.md` in `00-Inbox/`

Key points captured:
- Marco wants the budget report by Friday
- He expressed concern about Q2 numbers
- Action item: deliver report by Friday

**2. New Hire Starting in April**
Filed as `2026-03-21 -- Note -- New Hire April.md` in `00-Inbox/`

Linked to [[05-People/Marco]] in both notes. Does this capture everything correctly?

---

### Brainstorm mode

**You:** Brainstorm: ways to improve the onboarding experience for new users

**Scribe:** Created `2026-03-21 -- Brainstorm -- Onboarding Improvements.md` in `00-Inbox/`

Captured all your ideas, numbered and grouped. I noticed 3 natural clusters: UI changes, documentation improvements, and community-driven ideas. The two most promising ideas (based on feasibility and impact) are highlighted in the Hot Takes section.

Want to expand on any of these?

---

### Voice-to-note

**You:** Voice note: so basically i was thinking about um the whole pricing structure right and like marco said yesterday that we should probably move to a tiered model because uh the enterprise clients are paying the same as the small ones and thats just not sustainable you know so maybe we do three tiers basic pro and enterprise and each one gets different levels of support

**Scribe:** Detected speech-to-text input. Cleaned and structured as:

**Pricing Structure -- Tiered Model Proposal**

Marco suggested moving to a tiered pricing model because enterprise clients currently pay the same as small clients, which is not sustainable. The proposed tiers:
- **Basic** -- entry level
- **Pro** -- mid-tier
- **Enterprise** -- full support

Each tier would include different levels of support.

Filed as `2026-03-21 -- Idea -- Tiered Pricing Model.md` with `source: voice-note` in the frontmatter. Sound right?

## Works with

- **Sorter** -- files the notes the Scribe drops in the Inbox
- **Architect** -- the Scribe follows the Architect's templates and naming conventions. If a new project or area seems to be emerging, the Scribe flags it for the Architect
- **Connector** -- when the Scribe notices a note relates to many existing notes, it flags it for the Connector to do deep linking
- **Food Coach** -- food, diet, or weight information captured by the Scribe gets flagged for the Food Coach
- **Wellness Guide** -- the Scribe acts as the Wellness Guide's writing proxy, since the Wellness Guide operates in read-only mode. When the Wellness Guide wants to save session insights or affirmations, the Scribe does the actual writing

## Tips

- **Do not overthink your input.** The messier, the better -- that is literally what the Scribe is for. Just dump your thoughts.
- **Use "quick dump" for multiple topics.** The Scribe will detect and split them automatically.
- **Paste raw speech-to-text directly.** No need to clean it up first -- the Scribe handles filler words, broken sentences, and transcription artifacts.
- **Say "brainstorm" when you want zero filtering.** The Scribe will capture every idea without judging, then gently highlight the best ones.
- **Check the suggested connections.** The Scribe adds a Connections section at the end of each note -- these are quick wins for building your knowledge graph.
- **Trust the assumptions.** The Scribe makes judgment calls when your input is ambiguous. It always tells you what it assumed, so you can correct it if needed.
