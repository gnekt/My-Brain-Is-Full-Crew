# Connector

> The agent that turns isolated notes into a living knowledge web.

## What it does

The Connector is obsessed with relationships between your notes. It reads your vault, analyzes the link structure, and finds connections you did not know existed. That meeting note from January? It relates to the idea you jotted down last week. That book quote? It supports the argument in your project brief. The Connector sees these threads and weaves them together.

Your vault's value grows exponentially with the quality of its connections. A note with zero links is an island -- useful on its own but invisible to everything around it. The Connector ensures no note stays isolated for long. It discovers missing links, suggests new connections ranked by confidence, identifies clusters of related notes that need a Map of Content, and can even surprise you with unexpected relationships between seemingly unrelated topics.

It is also your graph health monitor. It tracks metrics like orphan rate, link density, and cluster count, and tells you when parts of your vault are drifting into isolation.

## Capabilities

- **Full graph audit** -- maps all wikilinks, identifies orphan notes (no incoming links), dead-end notes (no outgoing links), and disconnected clusters
- **Targeted connection discovery** -- given a specific note, finds all potentially related notes ranked by strength (strong, medium, weak)
- **Serendipity mode** -- discovers unexpected connections between notes that share no obvious keywords but relate conceptually
- **Semantic bridging** -- finds notes about the same concept using different terminology
- **Bridge notes** -- creates new notes that explicitly connect two otherwise separate clusters
- **MOC enhancement** -- audits Maps of Content for completeness and suggests missing entries
- **Constellation view** -- shows how a topic connects across different areas of your vault (work, personal, learning)
- **People network** -- maps how people in your vault are connected through meetings, projects, and references
- **Graph health metrics** -- tracks connectivity ratio, orphan rate, average path length, cluster count, and MOC coverage
- **Batch processing** -- after the Sorter files a batch of notes, analyzes all of them for connections at once

## How to use it

Trigger the Connector when you want to strengthen your vault's knowledge graph:

- "Find connections for my latest note"
- "Analyze my vault graph"
- "What notes are isolated?"
- "What connects [topic A] and [topic B]?"
- "Find missing links"
- "Surprise me -- what unexpected connections exist?"
- "Audit the MOCs"
- "How is my graph health?"
- "Show me the people network"

In Italian: "Trova connessioni", "Analizza le relazioni", "Collega le note"
In French: "Trouve des connexions", "Analyse du graphe"
In Spanish: "Encuentra conexiones", "Analiza el grafo"
In German: "Finde Verbindungen", "Netzwerkanalyse"

## Example conversations

### Connection discovery for a specific note

**You:** Find connections for my latest note on tiered pricing

**Connector:** I analyzed "Tiered Pricing Model" and found these potential connections:

**Strong (add these):**
- [[Client Feedback on Pricing]] -- contains the client's response to the tiered model idea
- [[Sprint Planning Q2]] -- meeting where Marco first proposed the tiers

**Medium (probably useful):**
- [[Competitor Analysis Q1]] -- includes competitor pricing models for comparison
- [[Revenue Projections 2026]] -- would be impacted by a pricing change

**Weak (worth considering):**
- [[Reading Notes -- SaaS Pricing Strategies]] -- book notes with relevant frameworks

Want me to add the strong connections now?

---

### Graph health check

**You:** How is my graph health?

**Connector:** Vault Graph Analysis

Stats:
- Total notes: 147
- Total links: 312
- Average density: 2.1 links per note
- Orphan notes: 18 (12%) -- target is under 10%
- Dead-end notes: 9

Islands (disconnected clusters):
1. "Personal Finance" -- 5 interconnected notes, 0 external links
2. "Old Project Beta" -- 8 notes, only 1 link to the rest of the vault

Top 5 most connected notes:
1. [[MOC/Index]] -- 23 links out
2. [[Sprint Planning Q2]] -- 8 links in, 6 links out
3. [[Project Alpha Roadmap]] -- 5 links in, 9 links out

Recommendations:
- The Personal Finance cluster should be linked to your Areas and daily notes
- 18 orphan notes need attention -- want me to suggest connections for each?

---

### Serendipity mode

**You:** Surprise me -- what unexpected connections exist?

**Connector:** Here are some connections you probably did not expect:

1. Your reading notes on "Atomic Habits" and your project retrospective for Beta share the same core insight about feedback loops -- one in personal habits, one in software development. Linking them could create a powerful cross-domain concept note.

2. Three different people in your vault (Marco, Sarah, and the podcast guest from last week) all independently mentioned the same concern about "sustainable growth." This might be an emerging theme worth a dedicated note.

3. Your voice journal from March 5 about feeling overwhelmed uses almost identical language to your burnout reflection from January. The Wellness Guide might find this pattern valuable.

Want me to create any of these connections?

## Works with

- **Sorter** -- after a batch filing, the Connector receives a notification to analyze newly filed notes
- **Architect** -- when the Connector discovers a cluster needing a new MOC, it flags the Architect to create one
- **Seeker** -- the Connector can ask the Seeker to verify content-level relationships before suggesting links
- **Librarian** -- broken wikilinks found during analysis are reported to the Librarian
- **Food Coach** -- connects diet-related notes that should be linked (meal plans to grocery lists, progress notes to each other)
- **Wellness Guide** -- surfaces recurring emotional themes across the vault that may be valuable context for mental health sessions

## Tips

- **Run it after big filing sessions.** The best time to use the Connector is right after the Sorter processes a batch of notes. The new notes have the most linking potential.
- **Start with "strong" connections.** When the Connector suggests links at three confidence levels, always approve the strong ones. They are almost always correct.
- **Use serendipity mode for creative work.** The unexpected connections it finds can spark genuinely new ideas by linking concepts from different domains.
- **Watch the orphan rate.** If it climbs above 15-20%, your vault is accumulating unlinked knowledge that is effectively invisible. Run a graph audit.
- **Do not over-link.** The Connector follows a quality-over-quantity principle. A few meaningful links are worth more than dozens of superficial ones. Trust its judgment.
- **Check the people network.** It is a surprisingly useful way to see who appears most often in your vault and how they are connected to your projects.
