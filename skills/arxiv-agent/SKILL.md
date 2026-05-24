---
name: arxiv-agent
description: ArXiv research curator agent — bootstraps from agent-sheets/arxiv.md directives. Discovers, downloads, and reports on ML/AI papers from arXiv.
trigger: /arxiv-agent
---

# ArXiv Agent

**Loads:** `wiki/scratchpad/agent-sheets/arxiv.md` for full directives
**Wiki root:** `/home/ty/Documents/LLM-WIKI`
**Paper storage:** `/home/ty/Documents/paper-research/`

## Bootstrap

1. Read this skill file (you just did)
2. Read your agent sheet: `wiki/scratchpad/agent-sheets/arxiv.md`
3. Read the jobs sheet: `wiki/scratchpad/jobs/sheet.md`
4. Execute your task per the agent sheet directives
5. Report to `#research` Discord channel

## Your Tools

- `mcp_arxiv_mcp_server_search_papers` — search arXiv by keyword/author/category (MCP, try first; fallback to curl on 429 or timeout)
- `terminal` + curl — download PDFs to `/home/ty/Documents/paper-research/` (bypasses MCP rate limits; **always use absolute paths**)
- `write_file` — write wiki source pages directly to the filesystem (creates parent dirs automatically)
- `wiki_fetch_url` — ingest web sources
- `mcp` tools — wiki_write_page, wiki_read_page, wiki_search, wiki_lint, etc. when MCP is available

**`delegate_task` is NOT available in this environment.** Do NOT list it as a subagent tool. Write wiki pages directly from the main agent context. If parallel research is needed, use separate `terminal()` calls or run papers sequentially.

## Critical Patterns

### PDF storage: paper-research/ — NOT wiki/sources/papers/ — NOT Obsidian vault
- PDFs: `/home/ty/Documents/paper-research/` — never write PDFs to wiki folder or Obsidian vault
- **Every curl download MUST use absolute path** — always prefix with `/home/ty/Documents/paper-research/` so the file goes to the correct location regardless of workdir
- Wiki/sources/papers/ contains only metadata summary pages (text, ~2–15KB)
- **ALWAYS verify after download** — run `ls -la /home/ty/Documents/paper-research/{id}.pdf` to confirm the file landed in the correct place, not in the current workdir
- If a "page" in wiki/sources/papers/ or Obsidian vault is a chunked PDF or >50KB, it was written incorrectly — remove it
- **Obsidian vault is separate from the LLM-WIKI wiki directory** — the agent has no access to Obsidian via the wiki path; if you see PDFs appearing in Obsidian, something outside the normal workflow is writing them there (check for manual actions or other processes)

### Terminal Background — NO `&` in Foreground Calls
Wiki:           /home/ty/Documents/LLM-WIKI/
Agent sheet:    wiki/scratchpad/agent-sheets/arxiv.md
Jobs sheet:     wiki/scratchpad/jobs/sheet.md
Reports:        wiki/scratchpad/jobs/reports/arxiv/
Paper storage:  /home/ty/Documents/paper-research/
Source pages:   wiki/sources/papers/
Carryover:      wiki/scratchpad/jobs/reports/arxiv/carryover.md
```

## Discovery — Primary Method (HTML List Pages)

When the arXiv API is rate-limiting or unreachable (which can last hours to days):

```bash
# Get recent paper IDs for a category — this ALWAYS works
curl -s --max-time 10 "https://arxiv.org/list/cs.AI/recent" | \
  grep -o '[0-9]\{4\}\.[0-9]\{5\}' | sort -u | head -10
```

Then use those IDs to look up metadata via the API (try with backoff), or use the PDF URL directly: `https://arxiv.org/pdf/{id}` — curl download works even when API queries fail.

**Flow when API is down:**
1. Scrape `arxiv.org/list/cs.AI/recent` and/or `arxiv.org/list/cs.LG/recent` for IDs
2. Attempt API metadata fetch with backoff (1s, 2s, 4s, 8s)
3. If API still fails → download PDF directly via curl, extract title/author from PDF first page via PyMuPDF
4. Queue any papers that couldn't have metadata resolved for next cycle's API retry

## PDF Extraction — PyMuPDF

```bash
pip install pymupdf  # install once; may not be in environment
```

```python
import pymupdf
doc = pymupdf.open(f"/path/to/{arxiv_id}.pdf")
text = "\n".join(page.get_text() for page in doc)
# First 2 pages are usually enough for title, authors, abstract
```

## Critical Patterns

### Terminal Background — NO `&` in Foreground Calls

If you need to run something in the background, use `terminal(background=True)` — never use `&` inside a foreground call. Foreground calls with `&` return `{status: pending_approval}` and hang.

```python
# WRONG — will hang on approval_pending:
terminal(command="python3 << 'EOF'\n...script...\nEOF &")

# CORRECT — use a file-based script:
terminal(command="python3 /path/to/script.py", background=True)

# Or for short extractions, run inline (foreground):
write_file(content="import pymupdf\n...", path="/tmp/extract.py")
terminal(command="python3 /tmp/extract.py")
```

### Duplicate Batch Detection
Before downloading PDFs, check whether the paper IDs from a newly discovered batch were already processed in a prior run. arXiv batches are dated by submission date, not processing date — a Friday-UTC batch processed Saturday morning may appear again Monday morning if the Monday run also encounters it.

Check: `wiki/sources/papers/` for existing source pages with the same arXiv ID prefix + same batch submission date. If found, skip re-ingesting — update jobs sheet and carryover only.

### arXiv API down → HTML page + direct PDF
```
# Discovery: scrape HTML list page (always works)
curl -s "https://arxiv.org/list/cs.AI/recent" | grep -o '[0-9]\{4\}\.[0-9]\{5\}' | head -10

# Download: direct PDF via curl (bypasses API entirely)
curl -s -L "https://arxiv.org/pdf/{id}" -o "{path}/{id}.pdf" -w "%{http_code}"
```

### MCP fails → curl fallback immediately
```
if mcp_download → 429 or timeout:
    curl -s -L "https://arxiv.org/pdf/{id}" -o {storage_path}/{id}.pdf
```
One failure = switch to curl. Do NOT retry MCP twice.

### arXiv API (export.arxiv.org)
- Max 4 requests/second with 1s sleep between
- 429 → exponential backoff (1s, 2s, 4s, 8s)
- Batch boolean queries over separate calls

## Delivery Rule

- Deliver report to `#research` Discord channel (channel ID: `1505826045511602176`)
- Always write a substantive report — never `[SILENT]`
- If MCP hits rate limit: fall back to curl, note in report

**References:** `references/discovery.md` (HTML list page fallback), `references/pdf-extraction.md` (PyMuPDF pattern), `references/obsidian-vault.md` (Obsidian vs wiki separation)

## Obsidian Vault — Separate from Wiki Directory

The LLM-WIKI wiki directory (`/home/ty/Documents/LLM-WIKI/`) is **separate** from the user's Obsidian vault. The arxiv-agent has no access to Obsidian via the wiki path.

| Location | Purpose | Agent access |
|----------|---------|--------------|
| `/home/ty/Documents/LLM-WIKI/` | Wiki source pages (metadata summaries only) | read/write via wiki tools |
| `/home/ty/Documents/paper-research/` | PDF storage | read/write via terminal |
| Obsidian vault | User's personal notes | **no access** — do not attempt to read or write |

**If you see PDFs appearing in Obsidian**, something outside the normal cron/agent workflow is writing them there. The agent itself does not write to Obsidian. Do not attempt cleanup there unless the user explicitly asks.

## Selection Criteria

- Novel contribution (not incremental on prior work)
- Relevance to active wiki research threads
- Technical depth sufficient to be useful
- Select 3 papers per cycle