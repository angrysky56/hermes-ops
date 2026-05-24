---
summary: LLM-WIKI vault schema, conventions, workflows, and tool reference for the cron-driven agent architecture
tags: [meta, schema, conventions, workflow, vault-structure]
updated: 2026-05-25
---

# AGENTS — LLM-WIKI Vault Schema

> **Operating guide:** Tool decision logic, workflows, and what to avoid → [[synapse-llm-wiki-operating-guide]]  
> **Conceptual index:** Concept-to-page mapping → [[concept-index]]  
> **Tag vocabulary:** Before tagging anything → [[tag-taxonomy]]

> **Architecture note:** This file reflects the **cron-driven** agent architecture used by hermes-ops — not the older Manager/Servitor delegation model. Agents run as scheduled cron jobs, each loading a skill that points to an agent sheet. There is no hierarchical delegation between agents at runtime.

---

## Vault Structure

```
LLM-WIKI/
├── raw/                        # INBOX — empty after every session
├── raw-inbox.base              # Queue view of pending raw/ files
├── clippings-archive.base      # Browsable view of all Clippings
│
├── Clippings/                  # SOURCE ARCHIVE — type / year
│   ├── papers/YYYY/            # Academic papers, preprints
│   ├── articles/YYYY/          # Blog posts, tutorials, web clips
│   ├── documentation/YYYY/     # Specs, manuals, skills, READMEs
│   └── repositories/YYYY/      # GitHub repos, packages
│
└── wiki/                       # LLM-GENERATED KNOWLEDGE LAYER
    ├── index.md                # Auto-generated structural TOC
    ├── concept-index.md        # Maintained conceptual index (by meaning)
    ├── log.md                  # Append-only activity log
    │
    ├── sources/                # Compressed summaries — mirrors Clippings/ types
    │   ├── papers/
    │   ├── articles/
    │   ├── documentation/
    │   └── repositories/
    │
    ├── entities/               # Reference pages for specific named things
    │   ├── tools/              # Software, databases, APIs, frameworks
    │   ├── people/             # Researchers, practitioners
    │   └── projects/           # Projects, systems, components
    │
    ├── concepts/               # External ideas, theories, patterns (FLAT)
    │
    ├── research/               # Research projects from Wiki Researcher agent
    │   └── index.md
    │
    ├── synthesis/              # Original cross-domain thinking and materialized insights
    │
    └── scratchpad/              # AGENT OPERATIONAL LAYER
        ├── agent-sheets/        # Directive files read by cron agents at runtime
        │   ├── news.md
        │   ├── arxiv.md
        │   ├── researcher.md
        │   ├── librarian.md
        │   ├── librarians-assistant.md
        │   ├── ingest.md
        │   └── insights.md
        └── jobs/
            ├── sheet.md          # Central task board — all agent job IDs and status
            └── reports/{agent}/ # Per-agent report folders + carryover.md
```

---

## Design Principles

- **No folder grows forever.** `Clippings/` adds a year subfolder each January. When any other folder exceeds ~20 pages, add a subdimension.
- **Folder = one navigational question.** `Clippings/` answers "what type + when?". `entities/` answers "what category of thing?". `concepts/` answers "what idea?". `synthesis/` answers "what original insight?".
- **Folder structure ≠ topical structure.** Tags and wikilinks handle topics. Folders handle type and access pattern.
- **4 levels max.** `Clippings/papers/2026/file.md` is already 4 deep — don't add more.

---

## Page Type → Folder Mapping

| Page type | Folder | When to use |
|-----------|--------|-------------|
| `source` | `wiki/sources/<type>/` | Compressed summary of an ingested source |
| `entity` (tool) | `wiki/entities/tools/` | Software, database, API, framework |
| `entity` (person) | `wiki/entities/people/` | Researcher, practitioner |
| `entity` (project) | `wiki/entities/projects/` | Project, system, component |
| `concept` | `wiki/concepts/` | External idea, theory, pattern (reference-quality) |
| `research` | `wiki/research/` | Research project page from Wiki Researcher agent |
| `synthesis` | `wiki/synthesis/` | Original cross-domain insight, materialized Zettel |
| — | `wiki/synthesis/` | System docs (operating guides, architecture notes) |

**Concepts vs. Synthesis:** `concepts/` = stable reference definitions of external ideas (RAG, GraphRAG, PARA). `synthesis/` = original thinking or analysis of our own system (causal-state isomorphism, retrieval architecture, operating guides). When in doubt: would this page exist if we weren't building this system? Yes → concepts/. No → synthesis/.

---

## Frontmatter

```yaml
---
created: 2026-04-11T00:00:00Z
updated: 2026-04-11T00:00:00Z
type: source | entity | concept | synthesis
summary: One-line description (used in index)
tags: [tag1, tag2]          # check tag-taxonomy.md first
sources: <original-url>     # URL, not file path
status: active | reference | archived
confidence: 0.0–1.0         # < 0.7 → add ## Caveats section
---
```

`log.md` and `index.md` are exempt from frontmatter requirements.

---

## Wikilinks

Filenames are lowercase-hyphen slugs. `[[neo4j]]` resolves to `neo4j.md` anywhere in the vault regardless of subfolder — Obsidian handles this automatically. Never use full paths in wikilinks.

For display text: `[[slug|Display Text]]`

Links in `## Connections` sections carry full retrieval weight. Body prose links are contextual (lower weight). Don't add wikilinks for mere mentions.

---

## Clippings Archive

`wiki_ingest_raw` and `wiki_fetch_url` automatically route files to the correct `Clippings/<type>/<year>/` subfolder:

| Signals | → Type |
|---------|-------|
| arxiv, doi.org, nature.com, acm.org, ieee.org, .pdf | papers/ |
| github.com, gitlab.com, pypi.org, huggingface.co | repositories/ |
| docs., /docs/, help., spec., standard, skill.md, README | documentation/ |
| everything else | articles/ |

Use `clippings-archive.base` in Obsidian for a browsable filtered view.

---

## Source Summary Paths

When writing a source summary page, use the typed path:
- Paper summaries → `wiki/sources/papers/<slug>.md`
- Article summaries → `wiki/sources/articles/<slug>.md`
- Documentation summaries → `wiki/sources/documentation/<slug>.md`
- Repository summaries → `wiki/sources/repositories/<slug>.md`

---

## Operational Workflows

### Session Start (wiki agent)
1. Read the agent sheet for your role (`wiki/scratchpad/agent-sheets/{agent}.md`)
2. Read the jobs sheet (`wiki/scratchpad/jobs/sheet.md`) for any user-flagged priorities
3. Read carryover (`wiki/scratchpad/jobs/reports/{agent}/carryover.md`) — do not duplicate prior work
4. Scan `raw/` for new files (check `raw-inbox.base`)

### Ingest (file in raw/)
1. `wiki_ingest_raw(filename)` → Neo4j + auto-routes to `Clippings/<type>/<year>/`
2. `wiki_write_page(wiki/sources/<type>/<slug>.md)` → compressed summary
3. Update touched entity/concept/synthesis pages with cross-links
4. `wiki_update_index()`
5. Update carryover before finishing

### Fetch (URL)
1. `wiki_fetch_url(url)` → defuddle → Neo4j → `Clippings/<type>/<year>/`
2. `wiki_write_page(wiki/sources/<type>/<slug>.md)` → summary
3. Update touched pages
4. `wiki_update_index()`
5. Update carryover before finishing

### Lint
1. `wiki_lint()` — orphans, broken links, missing frontmatter, non-reciprocal links, non-preferred tags
2. Ignore all `log.md` results — structural false positives, unfixable by design
3. `wiki_hits_analysis()` — identify authority pages needing depth, hub pages needing link coverage
4. `wiki_cluster_pages()` — find missing intra-cluster links and merge candidates

### Self-Improvement
When a convention is wrong, fix it. Log reasoning in `wiki/log.md` as `## [date] schema-update`.

---

## Synapse Tools

| Tool | Purpose |
|------|---------|
| `wiki_fetch_url(url)` | Fetch + clean + ingest + archive |
| `wiki_ingest_raw(filename)` | Ingest + archive |
| `wiki_write_page(path, body)` | Create/update any wiki page |
| `wiki_read_page(path)` | Read a specific page |
| `wiki_search(query)` | Keyword search across wiki files |
| `wiki_list_pages(subdir)` | List all pages |
| `wiki_update_index()` | Rebuild index.md |
| `wiki_lint()` | Full health check |
| `wiki_hits_analysis()` | Hub/authority scores on wikilink graph |
| `wiki_cluster_pages()` | GAAC clustering, missing links, merge candidates |
| `query_knowledge(query)` | 4-stage retrieval (entity → RRF → wikilinks → insights) |
| `explore_connections(entity)` | Graph traversal |
| `generate_insights()` | Zettelkasten pattern detection |

---

## Git

Synced via Obsidian Git plugin to `https://github.com/angrysky56/LLM-WIKI`. All rollbacks via git.