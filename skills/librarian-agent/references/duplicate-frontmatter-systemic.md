# Duplicate Frontmatter Fix — Systemic Issue

**Detected:** 2026-06-08  
**Scope:** 8 synthesis pages with 11-58 duplicate `---` yaml header separators

## Symptom

`full_audit.py` reports these pages as having many `---` counts. Each page has accumulated multiple frontmatter blocks from repeated edits — the original `---...---` block was never replaced, only new content + new `---...---` blocks appended.

## Affected Pages

| Page | `---` count | Status |
|------|-------------|--------|
| `wiki/synthesis/cross-layer-drift-falsification.md` | 40 | Needs individual review |
| `wiki/synthesis/codegraph-hermes-integration-plan.md` | 58 | Needs individual review |
| `wiki/synthesis/librarian-report-2026-05-09.md` | 58 | Needs individual review |
| `wiki/synthesis/research-brief-2026-05-09.md` | 37 | Needs individual review |
| `wiki/synthesis/self-prompting-via-production-stage-architecture.md` | 13 | Needs individual review |
| `wiki/synthesis/essan-internal-representation.md` | 23 | Needs individual review |
| `wiki/synthesis/wiki-indexing-theory.md` | 11 | Needs individual review |
| `wiki/synthesis/research-brief-2026-05-13.md` | 15 | Needs individual review |

## Fix Pattern

For each page:
1. Read the page and identify which `---` block is the actual valid frontmatter (first block with valid YAML fields: created, updated, type, summary, tags, sources, status, confidence)
2. Extract the content between that first `---` block and the second `---` block
3. Rewrite the page with a single clean frontmatter block + the content

**Detection script:**
```python
from pathlib import Path

synthesis_pages = [
    'wiki/synthesis/cross-layer-drift-falsification.md',
    'wiki/synthesis/codegraph-hermes-integration-plan.md',
    'wiki/synthesis/librarian-report-2026-05-09.md',
    'wiki/synthesis/research-brief-2026-05-09.md',
    'wiki/synthesis/self-prompting-via-production-stage-architecture.md',
    'wiki/synthesis/essan-internal-representation.md',
    'wiki/synthesis/wiki-indexing-theory.md',
    'wiki/synthesis/research-brief-2026-05-13.md',
]

for p in synthesis_pages:
    path = Path(f'/home/ty/Documents/LLM-WIKI/{p}')
    if path.exists():
        content = path.read_text()
        count = content.count('---')
        print(f'{p}: {count} frontmatter separators')
```

## Why This Happens

The `wiki_write_page` MCP tool appends to pages rather than replacing frontmatter. When frontmatter is updated via patch, the old block stays in place and a new one is appended. Over multiple cycles, this compounds.

**Prevention:** When using `patch` to update frontmatter, replace the entire `---...---` block in one operation, not just a subset of fields within it.