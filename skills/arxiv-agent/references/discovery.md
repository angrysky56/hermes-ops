# arXiv Discovery — HTML List Pages (API Fallback)

## When to Use

The arXiv API (`export.arxiv.org`) rate-limits or becomes unresponsive during heavy usage windows. This can persist for hours. HTML list pages are always accessible and contain the latest batch IDs.

## Method

```bash
# Scrape paper IDs from category list pages — no rate limit, always works
curl -s --max-time 10 "https://arxiv.org/list/cs.AI/recent" | grep -o '[0-9]\{4\}\.[0-9]\{5\}' | sort -u | head -10
curl -s --max-time 10 "https://arxiv.org/list/cs.LG/recent" | grep -o '[0-9]\{4\}\.[0-9]\{5\}' | sort -u | head -10
```

## Important Caveats

**IDs visible in HTML ≠ queryable via API immediately.**  
arXiv batches are posted to HTML list pages within hours of submission. The export.arxiv.org API indexes them with a 1-2 day lag. A paper with ID `2605.21489` visible in the HTML list may return empty results from the API for up to 48 hours.

**Flow when API is down:**
1. Scrape HTML list pages for IDs (always works)
2. Try API metadata fetch with exponential backoff (1s, 2s, 4s, 8s)
3. If API still fails → fall back to direct PDF download via curl; extract title/author from PDF first 2 pages using PyMuPDF
4. Log unresolved metadata in carryover for next cycle

## API Partial Outage — Category Filter Failure

When `cat:cs.AI` or similar category-only queries return **0 results** but basic keyword queries work, the API's category indexing is lagging. This can persist for hours.

**Workaround: Keyword search with client-side category filtering**

```python
queries = [
    'agentic',
    'self-evolution OR self-evolving OR autonomous agent',
    'reasoning',
    'checkpoint rollback',
    'multi-agent communication',
    'linear attention',
]
# Filter results by cs.* category prefix on the client side
relevant = [c for c in entry_categories if c.startswith('cs.')]
```

This is more reliable than category-only queries when the API is degraded. It also catches papers that cross-list into relevant categories.

**Always verify:** A paper ID visible in the HTML list page may take 1-2 days to become queryable via API. If the API returns 0 results for a known ID, fall back to direct PDF download + PyMuPDF extraction for metadata.

## Duplicate Batch Detection

arXiv batches are dated by submission date, not by processing date. A batch posted on Friday evening (late-UTC) may be processed on Saturday morning and again on Monday — if the Monday run finds papers with the same submission date as the Saturday run, they are likely duplicates from a prior processing pass.

**Check before processing:**
1. Look up the paper IDs in the wiki source directory (`wiki/sources/papers/`) — if the arXiv ID already has a source page with similar creation date, it's a duplicate
2. Check `arxiv-YYYY-MM-DD-top-papers.md` reports in `jobs/reports/arxiv/` for the same batch date — if a report already exists for that submission date, skip re-ingesting
3. If duplicate detected: verify the existing pages are complete, update the jobs sheet and carryover only, do not re-write source pages

## Batch Cadence

arXiv posts new batches on weekdays (Mon–Fri), late afternoon/evening UTC. A run on Friday evening may find nothing new if the batch hasn't posted yet — check carryover for last confirmed batch date. **Weekends produce zero new submissions.**

## Python API Query — URL Encoding

When calling the arXiv API via Python `urllib.request`, spaces in the query string cause `"URL can't contain control characters"` errors. Always use `urllib.parse.quote()`:

```python
import urllib.request, urllib.parse, xml.etree.ElementTree as ET

def search_arxiv(query, max_results=10, categories="cs.AI+OR+cs.LG+OR+cs.CL"):
    q_encoded = urllib.parse.quote(query)
    url = (f"https://export.arxiv.org/api/query"
           f"?search_query={q_encoded}+AND+%28{categories}%29"
           f"&max_results={max_results}&sortBy=submittedDate&sortOrder=descending")
    with urllib.request.urlopen(url, timeout=20) as resp:
        root = ET.parse(resp).getroot()
    # parse entries from root...
```

The `%28...%29` encodes `(` `)` — required for correct boolean grouping of the OR clause.

**Do NOT pipe Python scripts via `python3 << 'EOF'` in a foreground terminal call** — this hangs waiting for approval. Write the script to a file first, then call `python3 /path/to/script.py` as a foreground command, or use `terminal(command="...", background=True)` for true background execution.

## Relevant Category Pages

| Category | URL |
|----------|-----|
| cs.AI | https://arxiv.org/list/cs.AI/recent |
| cs.LG | https://arxiv.org/list/cs.LG/recent |
| cs.CL | https://arxiv.org/list/cs.CL/recent |
| cs.MA | https://arxiv.org/list/cs.MA/recent |