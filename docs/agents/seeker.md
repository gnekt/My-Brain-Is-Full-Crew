# Seeker

> Ask your vault a question. Get an answer with sources.

## What it does

The Seeker is your vault's search engine and research assistant rolled into one. It does not just find files -- it understands questions. Ask "What did we decide about pricing?" and it searches across meeting notes, project files, and email imports to synthesize an answer with source links. Ask "Find all notes about Marco from this month" and it queries by person, date range, and content.

The Seeker searches everything: file contents, filenames, YAML frontmatter, tags, wikilinks, and relationship graphs. It ranks results by relevance, separates high-quality matches from tangential ones, and presents everything in a clean, scannable format. When it finds nothing, it suggests alternative searches, checks for typos, and offers to create a new note on the topic.

Beyond searching, the Seeker can also modify existing notes -- updating content, adding tags, fixing broken links, or appending new information. It always reads the full note first and confirms changes before making them.

## Capabilities

- **Full-text search** -- searches file contents with keyword and phrase matching
- **Metadata search** -- queries by type, date range, tag, person, project, or status
- **Relationship search** -- navigates the wikilink graph (forward links, backlinks, common connections)
- **Answer mode** -- synthesizes information from multiple notes to answer a question, with source citations
- **Timeline mode** -- finds notes within a date range, useful for "what happened last week" queries
- **Diff mode** -- compares versions of a topic across different notes to spot contradictions or evolution
- **Missing knowledge detection** -- identifies gaps in your vault (topics mentioned but never explained)
- **Note modification** -- append, update, refactor, re-tag, or fix links in existing notes
- **Cross-reference answering** -- pulls data from multiple sources and presents a unified answer

## How to use it

Ask any question about your vault, or search for specific content:

- "What did we decide about [topic]?"
- "Find all meeting notes from March"
- "What do I know about [topic]?"
- "Find notes tagged #marketing"
- "What notes mention Marco?"
- "Where did I put the note about [subject]?"
- "What am I missing about microservices?"
- "Update the note about [topic] with [new info]"
- "What connects Marketing and Sales in my vault?"

In Italian: "Cerca nel vault", "Trova", "Dove ho messo", "Che note ho su"
In French: "Cherche dans le vault", "Trouve"
In Spanish: "Busca en el vault", "Encuentra"
In German: "Suche im Vault", "Finde"

## Example conversations

### Answer mode

**You:** What did we decide about the pricing model?

**Seeker:** Based on your notes, here is what I found about pricing decisions:

Marco proposed moving to a tiered pricing model (Basic, Pro, Enterprise) during the Sprint Planning on March 18. The main driver is that enterprise clients currently pay the same as small clients. The client feedback note from March 20 suggests the client is open to tiered pricing but wants volume discounts included.

No final decision has been recorded yet. The next step appears to be delivering the pricing report by Friday (March 22).

Sources:
- [[06-Meetings/2026/03/Sprint Planning Q2]] -- initial proposal
- [[02-Areas/Sales/Client Feedback on Pricing]] -- client response
- [[00-Inbox/Tiered Pricing Model]] -- Marco's voice note with details

---

### Finding notes by criteria

**You:** Find all meeting notes from this month with open action items

**Seeker:** Found 5 meeting notes from March 2026 with uncompleted action items:

Top results:
1. [[Sprint Planning Q2]] -- March 18, 3 open action items (2 assigned to you)
2. [[Client Review Contract]] -- March 15, 1 open action item (pending legal review)
3. [[Marketing Sync]] -- March 12, 2 open action items

Other results:
4. [[Team Standup March 10]] -- 1 minor follow-up
5. [[Budget Meeting]] -- March 5, 1 item marked low priority

Total: 8 open action items across 5 meetings. Want me to compile them into a task list?

---

### Missing knowledge

**You:** What am I missing about microservices?

**Seeker:** You have 4 notes that mention microservices, but I notice some gaps:

You have covered:
- Architecture decision to adopt microservices (from a meeting note)
- Service mesh comparison (from reading notes)

Missing or thin:
- No notes on deployment strategy or CI/CD for microservices
- No notes on monitoring and observability
- The meeting note references a "microservices RFC" that does not exist in your vault

Would you like to create notes for any of these gaps, or search for related content that might cover them indirectly?

## Works with

- **Sorter** -- the Seeker can verify whether similar notes already exist before the Sorter files new ones
- **Connector** -- when the Seeker finds unlinked but related notes, it flags them for the Connector
- **Librarian** -- the Seeker often discovers broken links, orphan notes, or frontmatter problems while searching
- **Scribe** -- if a search reveals missing knowledge, the Seeker can suggest creating a new note via the Scribe
- **Food Coach** -- can search for health and diet content across the vault
- **Wellness Guide** -- can surface notes with recurring emotional themes when relevant

## Tips

- **Ask questions, not just keywords.** The Seeker is best when you ask "What do I know about X?" rather than just typing "X."
- **Use it for decision archaeology.** "What did we decide about Y?" is one of the most powerful queries -- it searches across meetings, emails, and project notes.
- **Request a timeline.** Saying "Show me everything about project Alpha in chronological order" gives you the full story of a project.
- **Ask about gaps.** "What am I missing about [topic]?" triggers the missing knowledge detector, which is surprisingly useful for learning and project planning.
- **Combine criteria.** "Find all notes tagged #urgent that mention Marco from the last two weeks" -- the Seeker handles compound queries.
- **Use it to update notes.** Instead of finding a note and editing it yourself, tell the Seeker: "Update the note about X with this new info."
