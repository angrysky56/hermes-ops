---
name: ingest-agent
description: Ingest pipeline operator agent — bootstraps from agent-sheets/ingest.md directives. Processes raw files from raw/ inbox into structured wiki knowledge.
trigger: /ingest-agent
---

# Ingest Agent

**Loads:** `wiki/scratchpad/agent-sheets/ingest.md` for full directives
**Wiki root:** `/home/ty/Documents/LLM-WIKI`

## Bootstrap

1. Read this skill file (you just did)
2. Read your agent sheet: `wiki/scratchpad/agent-sheets/ingest.md`
3. Read the jobs sheet: `wiki/scratchpad/jobs/sheet.md`
4. Execute your task per the agent sheet directives

## Your Tools

**MCP availability probe** (run first if using MCP tools):
```bash
/home/ty/Repositories/ai_workspace/project-synapse-mcp/.venv/bin/python3 -c "from synapse_mcp.zettelkasten.insight_engine import InsightEngine; print('OK')" 2>/dev/null && echo "MCP OK" || echo "MCP UNAVAILABLE"
```
If MCP unavailable: skip `wiki_ingest_raw` and `wiki_lint`, log to carryover and retry next cycle.

- `wiki_ingest_raw` — ingest file from raw/ into Neo4j + wiki
- `wiki_write_page` — write source summary pages
- `wiki_lint()` — health check after ingestion
- `wiki_update_index(deep=True)` — rebuild index
- `terminal` + `find` — discover files in raw/ paths

See `references/path-context.md` for path structure, pipeline quirks, and run pattern.

## Key Paths

```
Wiki:           /home/ty/Documents/LLM-WIKI/
Agent sheet:    wiki/scratchpad/agent-sheets/ingest.md
Jobs sheet:     wiki/scratchpad/jobs/sheet.md
Reports:        wiki/scratchpad/jobs/reports/ingest/
Raw inbox:      /home/ty/Documents/LLM-WIKI/raw/   ← NOT under wiki/ — at LLM-WIKI root level
Clippings:      /home/ty/Documents/LLM-WIKI/Clippings/
Carryover:      wiki/scratchpad/jobs/reports/ingest/carryover.md
```

**Path correction:** `raw/` is at `/home/ty/Documents/LLM-WIKI/raw` (parent of `wiki/`), NOT `wiki/raw/`.
All find/ls operations must use the correct absolute path: `/home/ty/Documents/LLM-WIKI/raw`

## Critical Rule: raw/ Must Stay Empty

After every run, `raw/` should be EMPTY. Every file should either be:
- Ingested → `wiki/sources/` → auto-moved to `Clippings/`
- Skipped with explicit reason in report
- Flagged for special handling

Do NOT let raw/ accumulate files. This is the #1 pipeline health metric.

## Delivery Rule

- local delivery (internal job, no Discord output)
- If nothing to ingest: `[SILENT]`
- Write report to: `wiki/scratchpad/jobs/reports/ingest/ingest-{date}.md`

## wiki_ingest_raw Behavior

- On success: auto-archives the file to `Clippings/articles/YYYY/<filename>.md`
- Do NOT manually `rm` files after ingestion — the tool handles the archive move
- If a file was already ingested by a prior run, it may no longer exist in raw/ — this is expected
- Do NOT call wiki_ingest_raw twice on the same file in one session — duplicate calls can produce stale error messages even on success

## Processing Order

1. Priority files flagged by Ty in jobs sheet
2. New files added since last run
3. Old files still pending (backlog)