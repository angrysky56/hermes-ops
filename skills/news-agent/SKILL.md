---
name: news-agent
description: News curator agent — bootstraps from agent-sheets/news.md directives. Loads Synapse + LLM-WIKI operating guide and executes the world-news-daily task.
trigger: /news-agent
---

# News Agent

**Loads:** `wiki/scratchpad/agent-sheets/news.md` for full directives
**Wiki root:** `/home/ty/Documents/LLM-WIKI`
**Operating guide:** `wiki/synthesis/synapse-llm-wiki-operating-guide.md`

## Bootstrap

1. Read the agent sheet at `wiki/scratchpad/agent-sheets/news.md` (this file gives you your task directives)
2. Read the jobs sheet: `wiki/scratchpad/jobs/sheet.md`
3. Read carryover: `wiki/scratchpad/jobs/reports/news/carryover.md` — includes the **Article Index** (last 10 URLs ingested); do NOT re-ingest anything already indexed
4. **Discover via RSS only — not wiki search:**
   ```bash
   curl -s "https://news.google.com/rss/search?q=geopolitics+may+2026&hl=en-US&gl=US&ceid=US%3Aen"
   curl -s "https://news.google.com/rss/search?q=AI+tech+policy+regulation+may+2026&hl=en-US&gl=US&ceid=US%3Aen"
   curl -s "https://news.google.com/rss/search?q=science+breakthrough+may+2026&hl=en-US&gl=US&ceid=US%3Aen"
   curl -s "https://news.google.com/rss/search?q=economy+trade+tariff+may+2026&hl=en-US&gl=US&ceid=US%3Aen"
   ```
5. **De-duplicate** against Article Index in carryover.md and recent `headlines-*.md` files before ingesting
6. Write 3-5 new stories per cycle (not more)
7. Update carryover.md: add new articles to Article Index, update Established/Open sections, prune index to last 10 entries
8. Report to `#news` Discord channel

## Primary Ingestion Pattern

**RSS via terminal (curl) + manual file write is the reliable primary workflow.** MCP tools (wiki_fetch_url, wiki_ingest_raw) have inconsistent module paths and unreliable fetch rates for mainstream news — do not treat them as primary.

### Step-by-step: RSS → Ingested Wiki Page

1. **Discover via RSS:**
   ```bash
   curl -s "https://news.google.com/rss/search?q={query}&hl=en-US&gl=US&ceid=US%3Aen"
   ```
   Use topic-specific queries: `geopolitics+may+2026`, `AI+tech+policy+regulation+may+2026`, `science+breakthrough+may+2026`, `economy+trade+tariff+may+2026`
   
2. **Parse RSS** — extract `<title>`, `<link>`, `<pubDate>` for each `<item>`

3. **Select stories** — aim for 3-5 significant stories per cycle; use RSS item count as signal (empty = no recent coverage, many items = active story)

4. **Write the source page** — create a markdown file locally with frontmatter and body, then copy to:
   ```
   /home/ty/Documents/LLM-WIKI/wiki/sources/articles/{slug}.md
   ```
   Do NOT use `wiki_ingest_raw` or `wiki_fetch_url` as primary ingestion — they fail at meaningful rates for mainstream news.

5. **Update carryover** at `wiki/scratchpad/jobs/reports/news/carryover.md`

### Why MCP tools are not primary

- `synapse_mcp.zettelkasten.ingestion.ingest_raw` does not exist at that path — actual module structure is `synapse_mcp.wiki.wiki_adapter.WikiAdapter`
- `wiki_fetch_url` (defuddle-based) fails at meaningful rates for: BBC (404 on article IDs), Reuters (bot blocking), Guardian (403), Al Jazeera (slug changes)
- RSS gives you structured data with titles, dates, and links — no defuddle parsing needed
- Manual write to `wiki/sources/articles/` is deterministic and reliable

### When to use MCP tools (limited scope)

- `wiki_fetch_url`: Only when you have a direct working URL for a specific story and RSS returned no results for that topic
- `wiki_lint`: Informational only after writes — output is noisy, do not block on it
- `query_knowledge` / `explore_connections`: For cross-referencing existing wiki content, not for ingestion

## URL Slug Patterns by Major Publisher

When `defuddle` returns 404 on a known article, the URL slug format may have changed. Known working patterns:

| Publisher | URL Pattern | Notes |
|-----------|-------------|-------|
| Al Jazeera | `https://www.aljazeera.com/news/YYYY/M/D/{slug}` | Date-based subdirectory; slug includes full headline |
| BBC | `https://www.bbc.com/news/world-{article-id}` | Numeric article ID, not slug-based |
| Reuters | `https://www.reuters.com/{world|world/{region}}/...` | Title in path, may change |

**When a direct URL fails**: Use the browser to visit the section page, extract article links from there, then feed those links to `wiki_fetch_url`. The browser renders dynamic content that defuddle cannot fetch.

**When browser also fails**: Use Google News search for the story title, extract the canonical URL from the Google News result (which usually has a working link to the publisher), then use that URL with `wiki_fetch_url`.

## After Writing: Update Carryover

Before finishing, update `wiki/scratchpad/jobs/reports/news/carryover.md` with:
- New emerging themes from this run
- Stories to keep monitoring (with brief notes on why)
- Any regions needing continued attention
- Connections to existing wiki research threads

The carryover is the primary mechanism to avoid duplicate work across runs. Read it at session start; update it before session end.

## Wiki Lint: Informational Only

Running `wiki_lint()` after writes is good practice but the output is noisy (orphans, broken links, non-reciprocal links are endemic to this wiki). Do not let lint failures block your run. Lint is for health awareness, not gatekeeping.

## Operational Notes

- Major geopolitical events, AI/tech policy, scientific breakthroughs, economic shifts = priority
- Soft news (celebrity, sports) = exclude unless it intersects your research threads
- Aim for 3-5 stories per cycle, ingested with significance not volume
- Cross-link to existing wiki threads to make news actionable knowledge

## URL Fetch Failure Reference

When `wiki_fetch_url` fails on known stories, see `references/news-source-url-patterns.md` for:
- Publisher-specific URL patterns that work
- Why defuddle fails on certain sources (BBC article IDs, Reuters bot detection)
- The Google News canonical URL resolver pattern (universal fallback)
- Quick reference table for which method works per publisher

**Rule:** Never spend more than 2 direct URL attempts on a story before switching to Google News URL resolution.