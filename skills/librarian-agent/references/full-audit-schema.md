# full_audit.py Output Schema

How to read the output of `python3 wiki/scratchpad/full_audit.py` when MCP is unavailable.

## Output Sections

### FRONTMATTER ISSUES
Lists pages missing frontmatter fields. Format:
```
wiki/path/to/page.md: missing ['field1', 'field2']
```

**Key categories (can ignore):**
- `NO-FRONTMATTER` — carryover files, batch-progress.md, audit reports, log files. These are operational docs, not wiki content. Do not add frontmatter to them.
- `missing ['sources']` — common in news sources; low priority unless the page has no other issues

**Priority order for fixing:**
1. `wiki/concepts/` pages missing `type`, `sources`, `status`, `confidence`
2. `wiki/entities/` pages missing the same
3. `wiki/synthesis/` pages missing the same
4. `wiki/sources/` articles — lower priority, operational content

### BROKEN WIKILINKS
Lists broken link targets with source file. Top 30 shown, then total.

**Known false positives (ignore):**
- `[['news', ...]]` in scratchpad report files — tag-array noise, not real wikilinks
- `[[aseke framework]]` in `audit-2026-05-*.md` — old audit files referencing aseke that exists
- `[[domain onboarding standards]]` — now resolved (stub created 2026-05-30)
- `[[engineering-internal-awareness]]` in `log.md` — dynamically generated, ignore
- `[[hermes-agent-skill]]` in carryover files — dynamic, ignore

**All remaining broken links are in scratchpad/report files — not wiki content.**
Real content-layer broken links have been resolved over multiple cycles. As of 2026-06-03, ~57 remaining are:
- News date-stamped refs: `china-cuba-us-threats-2026-05-21`, `hormuz-strait-security` (now stub-created), etc.
- External repo/guy references: `colbymchenry/codegraph`, `Clippings/repositories/2026/...`, `huggingface`, `priorlabs`, `xgboost`, etc.
- Slug mapping issues in synthesis: `revenue-model` → `goodrobot-revenue-model`, `seg-molecular-self`, etc.

### SUMMARY
```
Total pages: NNN
Missing frontmatter: NNN
Broken wikilinks: NNN
```

## Alias Fix Table

| Broken Alias | Resolution |
|---|---|
| `[[titans]]` | → `wiki/concepts/titans.md` (exists) |
| `[[reasoning]]` | → `wiki/concepts/reasoning.md` (exists) |
| `[[zettelkasten engine]]` | → `wiki/entities/projects/zettelkasten-engine.md` (exists) |
| `[[project synapse]]` | → `wiki/entities/projects/project-synapse.md` (exists) |
| `[[andrej karpathy]]` | → `wiki/entities/people/andrej-karpathy.md` (exists) |
| `[[engineering-internal-awareness]]` | → `wiki/concepts/engineering-internal-awareness.md` (created 2026-05-30) |
| `[[isabelle-hol]]` | → `wiki/entities/tools/isabelle-hol.md` (created 2026-05-30) |
| `[[word cloud communication]]` | → `wiki/concepts/word-cloud-communication.md` (created 2026-05-30) |
| `[[domain onboarding standards]]` | → `wiki/concepts/domain-onboarding-standards.md` (created 2026-05-30) |
| `[[lcguard]]` | → `wiki/concepts/lcguard.md` (created 2026-06-15) |
| `[[epistemic-energy]]` | → `wiki/concepts/epistemic-energy.md` (created 2026-06-15) |
| `[[bounded-rationality]]` | → `wiki/concepts/bounded-rationality.md` (created 2026-06-15) |
| `[[panksepp-emotional-systems]]` | → `wiki/concepts/panksepp-emotional-systems.md` (created 2026-06-15) |
| `[[superposition]]` | → `wiki/concepts/superposition.md` (created 2026-06-15) |
| `[[initialization]]` | → `wiki/concepts/initialization.md` (created 2026-06-15) |
| `[[criticality]]` | → `wiki/concepts/criticality.md` (created 2026-06-15) |
| `[[working-memory]]` | → `wiki/concepts/working-memory.md` (created 2026-06-15) |

## Orphan Detection

`full_audit.py` orphan count: filesystem scan based on wikilink graph. May report 0 even when MCP-based scan reports 155 (these use different methods — do not compare). When MCP is unavailable, treat orphan count as unreliable — focus on frontmatter and broken links instead.

**2026-06-08 update:** Orphan scan now returns only 2 — `log.md` and `insights.md` (system files with no inbound links expected by design). Actual content orphan issue is resolved.

## Current State (as of 2026-06-15)

| Metric | Value | Notes |
|--------|-------|-------|
| Total pages | 608 | Up from 578 (stubs created, report files added) |
| Broken wikilinks | 215 | ALL in scratchpad/report files — structural noise |
| Missing frontmatter | 279 | Dominated by scratchpad/agent-sheet noise |
| Orphans | 0 | `critical-initialization-biological-neural-networks.md` resolved via stub creation |

**Real wiki content is clean.** All remaining broken links are in scratchpad/report files. High-value dirs (concepts/entities/synthesis, 289 pages): 0 missing frontmatter.

**MCP state this cycle:** Package `synapse_mcp.zettelkasten.insight_engine.InsightEngine` imports successfully, but `wiki_lint`, `wiki_cluster_pages`, `wiki_hits_analysis` are NOT registered as MCP handlers. Only filesystem `full_audit.py` available in cron context. Re-verify MCP handler registration each cycle — it may come back online.