---
name: librarian-agent
description: "Wiki Librarian agent — bootstraps from agent-sheets/librarian.md directives. Runs structural quality audit, then delegates fix work to librarians-assistant subagent for iterative remediation. Reports what was done, not what needs doing."
trigger: /librarian-agent
---

# Librarian Agent

**Loads:** `wiki/scratchpad/agent-sheets/librarian.md` for full directives  
**Wiki root:** `/home/ty/Documents/LLM-WIKI`

## Bootstrap

1. Read this skill file (you just did)
2. Read your agent sheet: `wiki/scratchpad/agent-sheets/librarian.md`
3. Read the jobs sheet: `wiki/scratchpad/jobs/sheet.md`
4. Read the carryover: `wiki/scratchpad/jobs/reports/librarian/carryover.md` (if it exists)
5. Execute your task per the agent sheet directives

## MCP Tools — Availability Check Required

**All 22 MCP tools documented at:** `wiki/scratchpad/jobs/mcp-tools-reference.md` — includes args, return types, known issues, and timeout behaviors for every tool.

**CRITICAL:** The `project-synapse` MCP server may NOT be connected in cron/scheduled environments. The skill lists `wiki_lint`, `wiki_cluster_pages`, `wiki_hits_analysis`, `wiki_update_index`, `generate_insights` as "your tools" — but if the MCP server is unavailable, these will fail silently or throw module-not-found errors.

**MCP availability probe — TWO steps, not one:**

Step 1 (package import — necessary but NOT sufficient):
```bash
/home/ty/Repositories/ai_workspace/project-synapse-mcp/.venv/bin/python3 -c "from synapse_mcp.zettelkasten.insight_engine import InsightEngine; print('OK')" 2>/dev/null && echo "PACKAGE OK" || echo "PACKAGE MISSING"
```
This confirms the `synapse_mcp` package is in the project-synapse-mcp venv.

Step 2 (tool registration — the actual test):
After the import succeeds, make an actual MCP call: `debug_test` or `wiki_lint`. If it returns, the tools are registered. A clean `InsightEngine` import does NOT guarantee `wiki_lint`, `wiki_cluster_pages`, `wiki_hits_analysis` are available — those are registered MCP handlers in the server itself, not standalone Python modules.

**If MCP is unavailable** — fall back to filesystem analysis using `wiki/scratchpad/full_audit.py`:
```bash
cd /home/ty/Documents/LLM-WIKI && python3 wiki/scratchpad/full_audit.py
```

**If MCP is available but wiki_lint/cluster_pages/hits timeout** — these tools work but can be slow in cron context. Use filesystem `full_audit.py` as fallback ONLY for that cycle. Do NOT set a persistent "MCP down" flag — retry MCP tools in the next cycle.

**TIMEOUT BEHAVIOR (normal, not a failure):**
- `wiki_lint()` — fast (~5s)
- `wiki_cluster_pages()` — fast (~10s)
- `wiki_hits_analysis()` — fast (~10s)
- `wiki_update_index()` — medium (~30s)
- `generate_insights()` — **TIMEOUT at 300s** — this is expected. The Zettelkasten engine is slow. If it fails, skip it and note in carryover. Do NOT retry in the same cycle.
- `wiki_fetch_url()` — medium (~15s), may 403 on some sites (science.org, some paywalled sources)

**TIMEOUT = NOT "MCP UNAVAILABLE"** — A tool timing out means the engine is slow, not that MCP is down. Only fall back to `full_audit.py` if a tool throws an exception or returns a clear connection error.
This script performs: frontmatter completeness check (8 required fields), broken wikilink detection (alias resolution), orphan detection via wikilink graph analysis, and reciprocal link gap detection. It produces structured output suitable for carryover documentation.

The `full_audit.py` script covers: `full_audit.py` at `wiki/scratchpad/full_audit.py` is the primary audit tool when MCP is down. It outputs: count of pages missing each frontmatter field, list of broken wikilink alias targets, orphan count (0 = all pages have ≥1 inbound link).

**IMPORTANT — Orphan numbers differ by method:**
- MCP `wiki_lint()`: scans the Neo4j wikilink graph — reports 155 orphans (2026-05-21)
- `full_audit.py` filesystem scan: may report 0 orphans
- Do NOT treat these as comparable; use MCP results when available

**IMPORTANT — tag-taxonomy.md:** The canonical tag taxonomy is at `wiki/concepts/tag-taxonomy.md` — USE IT for tag normalization. Check this path first (not scratchpad or agent-sheets subdirectories).

- `wiki_lint()` — detect broken links, orphans, missing frontmatter
- `wiki_cluster_pages()` — GAAC clustering: topic clusters, missing same-cluster links, merge candidates
- `wiki_hits_analysis()` — HITS scoring: hub vs authority pages
- `wiki_list_pages()` — list all wiki pages
- `wiki_search` — keyword search
- `wiki_read_page` — read specific page
- `wiki_write_page` — fix frontmatter, add wikilinks, normalize tags (MCP, preferred)
- `write_file` — fallback when MCP is unavailable
- `wiki_update_index()` — rebuild index after fixes
- `generate_insights()` — Zettelkasten pattern detection (if 5+ pages modified)
- `query_knowledge` — vector ANN search

## CRITICAL: enabled_toolsets Must Include `patch`

All cron jobs for wiki agents MUST include `patch` in `enabled_toolsets`. Without it, any `patch` call during the cron run silently fails with:
```
{"error": "Background review denied non-whitelisted tool: patch. Only memory/skill tools are allowed."}
```
The job shows `last_status: ok` but the fix was skipped.

**Required toolsets for wiki agent cron jobs:**
- Base: `terminal`, `file`, `web`, `skills`, `search`
- **Always add:** `patch` (for updating carryover, batch-progress, frontmatter)
- Add `session_search` if the agent reads prior session transcripts

**Example cron update:**
```
cronjob update --job_id <id> --enabled_toolsets '["terminal","file","web","skills","search","patch"]'
```

## Key Paths

```
Wiki:                   /home/ty/Documents/LLM-WIKI/
Wiki content root:      /home/ty/Documents/LLM-WIKI/wiki/
Agent sheet:            wiki/scratchpad/agent-sheets/librarian.md
Jobs sheet:             wiki/scratchpad/jobs/sheet.md
Reports:                wiki/scratchpad/jobs/reports/librarian/
Carryover:              wiki/scratchpad/jobs/reports/librarian/carryover.md
Fallback audit script:  wiki/scratchpad/full_audit.py
```

## Required Frontmatter Fields (8 standard)

`created`, `updated`, `type`, `summary`, `tags`, `sources`, `status`, `confidence`

- Pages with `confidence < 0.7` → add `## Caveats` section
- `type` values: `concept`, `entity`, `agent`, `skill`, `source`, `project`, `article`, `paper`, `log`
- Frontmatter debt is the #1 issue across the vault — ~326/341 pages missing required fields as of 2026-05-23

## The 10-Task Librarian Checklist (per agent sheet)

Run ALL of these each cycle:

1. **Tag consistency** — collect all tags, cluster equivalents, normalize to canonical form
2. **HITS authority/hub scoring** — `wiki_hits_analysis()` → top authorities (efhf, maximum-occupancy-principle, project-synapse, edm-framework) need deepest content

**Verified deep pages (2026-05-30 audit):** efhf.md (5-layer architecture), maximum-occupancy-principle.md (full math + Prover9 verification), project-synapse.md (MCP architecture), edm-framework.md (EDM paper + simultaneous discovery problem). These load-bearing pages have substantive content — prioritize linking orphaned pages to them rather than adding content to them.
3. **Reciprocal wikilinks** — A→B without B→A is incomplete; 110 non-reciprocal pairs found 2026-05-21
4. **GAAC semantic clustering** — `wiki_cluster_pages()` → topic clusters, same-cluster missing links, merge candidates (sim > 0.7)
5. **Conceptual index health** — `concept-index.md` last updated 2026-04-28; may need manual refresh; separate from `index.md` (TOC)
6. **Mere mention review** — pages that reference a concept but don't wikilink it; flag for connection
7. **Frontmatter completeness** — all required fields: created, updated, type, summary, tags, sources, status, confidence
8. **Broken wikilinks repair** — `wiki_lint()` output shows 338 broken links (tag-list wikilinks like `[['news', ...]]`, non-existent concepts, relative path wikilinks); fix or remove
9. **Orphan detection** — `wiki_lint()` returns orphans; MCP-based detection (155 found 2026-05-21) differs from `full_audit.py` filesystem scan (which may report 0); **do not compare numbers across methods**
10. **Insight generation trigger** — `generate_insights(confidence_threshold=0.7)` — **WARNING**: times out after 300s; if it fails, skip and note in carryover; do not retry same cycle

11. **PDF path contamination check** — `find /home/ty/Documents/LLM-WIKI -name "*.pdf" -type f 2>/dev/null`. If any results: PDFs from arxiv-agent landed in wiki by mistake. Move them to `/home/ty/Documents/paper-research/` and note count in carryover.

### PHASE 1: AUDIT (your turn)

**First: Verify MCP availability** — run this before any MCP tool calls:
```bash
/home/ty/Repositories/ai_workspace/project-synapse-mcp/.venv/bin/python3 -c "from synapse_mcp.zettelkasten.insight_engine import InsightEngine; print('OK')" 2>/dev/null && echo "MCP OK" || echo "MCP UNAVAILABLE"
```
- If MCP UNAVAILABLE: fall back to `python3 wiki/scratchpad/full_audit.py` for the entire audit, skip MCP tools this cycle
- If MCP OK: proceed with MCP tools below

**TIMEOUT BEHAVIOR (normal, not a failure):**
- `wiki_lint()` — fast (~5s)
- `wiki_cluster_pages()` — fast (~10s)
- `wiki_hits_analysis()` — fast (~10s)
- `wiki_update_index()` — medium (~30s)
- `generate_insights()` — **TIMEOUT at 300s** — use CLI script instead
- `wiki_fetch_url()` — medium (~15s), may 403 on some sites

Run the full checklist silently:

1. **Tag consistency audit** — collect all tags, cluster equivalents, normalize to canonical form
2. **Reciprocal wikilink enforcement** — A→B without B→A is incomplete; add missing links
3. **GAAC clustering coherence** — `wiki_cluster_pages()` → ensure same-cluster links exist; flag merge candidates
4. **HITS authority scoring** — `wiki_hits_analysis()` → deepen load-bearing pages, fix wiki-layer orphans
5. **Broken wikilink repair** — `wiki_lint()` → fix or remove (never ignore log.md links)
6. **Frontmatter completeness** — all required fields: created, updated, type, summary, tags, sources, status, confidence; confidence < 0.7 → add Caveats section
7. **Wiki-layer orphan resolution** — pages with zero inbound wikilinks → add links from related pages
8. **Conceptual index vs TOC drift** — `wiki/index.md` is TOC not conceptual index; flag drift if separate index exists

Collect results. Do NOT write a report of findings. Move to Phase 2.

### PHASE 2: DELEGATE (spawn subagent)

After audit, spawn a `librarians-assistant` subagent using `delegate_task`:

```
goal: |
  You are the librarians-assistant for the LLM-WIKI at /home/ty/Documents/LLM-WIKI/.
  
  Your job is to fix what the librarian audit found. Work iteratively — do NOT try to fix everything at once.
  
  Priority order:
  1. Fix broken wikilink aliases: `[[titans]]`, `[[reasoning]]`, `[[agent-sheets/*]]` → create stub pages or remove the references
  2. Add inbound links to orphan pages (pages with zero incoming wikilinks) from related pages
  3. Fix non-reciprocal wikilinks (A→B without B→A) — add return links
  4. Fill missing frontmatter on pages flagged by wiki_lint
  5. Normalize tag variants to canonical form using tag-taxonomy.md
  
  Work in small batches. After each batch of 10-20 fixes, report briefly what you did.
  Use the project-synapse MCP tools: wiki_lint, wiki_read_page, wiki_write_page, wiki_search.
  
  If you cannot fix something (needs judgment, content gap, etc.), skip it and note it.
  
  Stop when: (a) you've made 50+ fixes, or (b) you hit a hard blocker, or (c) the librarian tells you to stop.
  
  Start by reading wiki/scratchpad/jobs/reports/librarian/carryover.md (if it exists) to understand what was already worked on.
```

role: `leaf`  
toolsets: `["terminal", "file", "web", "search"]`

**Fallback if `delegate_task` is not in your available tools:** Execute fixes directly using the same priority order above. Use `python3 wiki/scratchpad/full_audit.py` to re-check progress after each batch of ~20 fixes. Report what was done in the delivery message.

Wait for the subagent to complete. It will report what it did.

### PHASE 3: REPORT (your turn)

After the subagent finishes, write a brief delivery message that:
- States what was done (not what needs doing)
- Lists concrete actions: "Fixed 47 broken links, resolved 23 orphans, normalized tags on 12 pages"
- Flags anything that wasn't fixable and why
- Updates carryover.md with open items for next cycle

**Delivery rule:**
- All checks pass → `[SILENT]`
- Fixes made → brief summary of what was fixed, delivered to origin
- Do NOT write a standalone report file — output goes to cron delivery

**Carryover.md structure** — always record:
```
## Established
- Key metrics: page count, orphan count, broken link count, non-reciprocal pairs
- Top authorities (by HITS score) — these are load-bearing pages needing depth
- Top hubs — pages that link to many authorities

## Open
- Issues not fixed this cycle (with reason)
-工具/skill failures (e.g., insight generation timeout)

## Heading
- Priority fixes for next cycle
```

**Hard cap:** ~512 tokens (~2000 characters). Prioritize Open > Established > Heading.

## Broken Cron — Job Fires But Never Executes

**Symptom:** `cronjob run` returns `{"success": true}`, but `last_run_at` stays `null`, no session file appears in `~/.hermes/sessions/`, no output in `~/.hermes/cron/output/`. Job is `enabled=true`, `state=scheduled` — no API errors, scheduler just doesn't fire it.

**This is a scheduler bug, not a config error.** Deleting and recreating the cron does NOT fix it — the new job has the same behavior. Even setting `model=minimax/MiniMax-M2.7` explicitly doesn't resolve it.

**Workaround — use `delegate_task` instead:**
```python
delegate_task(
  context="...",
  goal="[full task context from the agent sheet]",
  toolsets=["terminal", "file", "web", "search", "skills"]
)
```

The delegate bypasses the broken scheduler path entirely and completes successfully every time. This is the reliable execution path when the cron scheduler is stuck.

**Do NOT:**
- Keep trying `cronjob run` hoping it fires — it won't
- Delete and recreate the job — the new one has the same bug
- Treat `last_run_at=null` as a timing issue — it's a persistent scheduler failure

**After using delegate_task as bypass:** Session file goes to `~/.hermes/sessions/` as `session_cron_<job_id>_<date>_<time>.json`. Output appears in `~/.hermes/cron/output/<job_id>/`.

## Stub Page Template

When creating stubs for high-frequency missing concepts, use this minimal structure:

```markdown
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: concept
summary: "[STUB] One-line description of the concept"
tags: [topic, stubs]
sources: []
status: stub
confidence: 0.3
---

# Concept Name

*Stub page — needs real content*

## Connections

- [[related-existing-page]]
```

### Batch Frontmatter Fixes — Python Script Pattern

When fixing 10+ pages' frontmatter (e.g., adding missing `type:` field to concept pages), use an inline Python script via `terminal()` rather than individual `patch` calls. This is more reliable and faster:

```python
from pathlib import Path
import re

WIKI = Path('/home/ty/Documents/LLM-WIKI/wiki')
TODAY = '2026-06-08'

# Pattern: add 'type: concept' when type is missing from frontmatter
pages = [
    'wiki/concepts/page1.md',
    'wiki/concepts/page2.md',
]

for p in pages:
    path = Path(p)
    if not path.exists():
        continue
    content = path.read_text()
    m = re.match(r'^(---\n)(.*?)(\n---)', content, re.DOTALL)
    if not m:
        continue
    fm = m.group(2)
    if 'type:' not in fm:
        new_fm = 'type: concept\n' + fm  # inject at top
        new_content = m.group(1) + new_fm + m.group(3) + content[m.end():]
        path.write_text(new_content)
        print(f'FIXED: {p}')
```

**Entity project pages** (`wiki/entities/projects/*.md`) use `type: entity`, not `type: project`. For missing `created` on these:
```python
if 'created:' not in fm:
    new_fm = f'created: {TODAY}\n' + fm
```

**Frontmatter field ordering:** Fields can appear in any order in valid YAML, but the canonical order (matching the operating guide) is: `created`, `updated`, `type`, `summary`, `tags`, `sources`, `status`, `confidence`. Pages with out-of-order fields (e.g., `type`/`sources`/`status`/`confidence` before `summary`/`tags`) should be corrected to canonical order.

Stub pages go in `wiki/concepts/` for concepts, `wiki/entities/projects/` for projects, `wiki/synthesis/` for synthesis topics.

### Batch Stub Creation (Cron-Fallback Pattern)

When MCP is unavailable and many missing stubs need to be created, execute via Python inline script rather than `wiki_write_page` (which requires MCP):

```python
import os
stubs = [
    ('slug-1', 'Description of concept 1'),
    ('slug-2', 'Description of concept 2'),
]
for slug, summary in stubs:
    path = f'wiki/concepts/{slug}.md'
    if os.path.exists(path):
        continue
    title = ' '.join(w.capitalize() for w in slug.split('-'))
    content = f'''---
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: concept
summary: "[STUB] {summary}"
tags: [stubs]
sources: []
status: stub
confidence: 0.3
---

# {title}

*Stub page — needs real content*

## Connections

- [[maximum-occupancy-principle]]
'''
    with open(path, 'w') as f:
        f.write(content)
```

**Slug resolution for broken wikilinks:**
- Always check `wiki/concepts/`, `wiki/entities/`, `wiki/synthesis/`, `wiki/sources/` recursively before creating a stub
- Wikilinks are case-insensitive and space-insensitive: `[[Agentic Design Picker]]` → `wiki/concepts/agentic-design-picker.md`
- Slash in wikilink (e.g., `[[Clippings/repositories/2026/cli-printing-press]]`) → parent dir stub at `wiki/sources/repositories/`

**Post-creation:** After stubs are created, run `python3 wiki/scratchpad/full_audit.py` to re-check and find any remaining broken links that need the same treatment.

**Stub fix history:** `references/stub-fix-log.md` — prior cycle fix log for cross-reference when re-auditing.  
**Audit output schema:** `references/full-audit-schema.md` — how to read full_audit.py output, known false positives, alias fix table.  
**Duplicate frontmatter:** `references/duplicate-frontmatter-systemic.md` — 8 synthesis pages with 11-58 duplicate `---` separators; fix pattern + affected page list.

## Common Fix Patterns Discovered

| Pattern | Fix | Example |
|---------|-----|---------|
| `[[Display Text]]` where Display Text ≠ slug | Fix alias to use slug | `[[Zettelkasten Engine]]` → `[[zettelkasten-engine]]` |
| `[[goodrobot-revenue-model]]` | Use existing page path | → `[[revenue-model]]` (in same dir) or full relative |
| Double frontmatter blocks | Remove first (duplicate) block | News pages often have both `[['news', ...]]` and proper frontmatter |
| Tag-list wikilinks `[['news', ...]]` | Remove — noise, not real links | Fix in news source pages only |
| `[[onboarding-standards]]` missing | Use `[[agent-onboarding]]` or create stub | Check research/index.md |
| Cross-stub references cascade | Fix one end of each pair; stubs pointing to stubs is acceptable as interim | |

## Broken Link Fix Order (when running wiki_lint)

1. Fix alias references (`[[titans]]`, `[[reasoning]]`, `[[agent-sheets/*]]`) — create stubs or remove
2. Remove tag-array wikilinks from news pages — these are `[['news', 'geopolitics', ...]]` style arrays that are noise, not real links (20+ instances in news sources)
3. Create stubs for real concepts that are linked but missing. **Gap list resolved 2026-05-30:**
   - `isabelle-hol` → created at `wiki/entities/tools/isabelle-hol.md`
   - `engineering-internal-awareness` → created at `wiki/concepts/engineering-internal-awareness.md`
   - `word-cloud-communication` → created at `wiki/concepts/word-cloud-communication.md`
   - `domain-onboarding-standards` → created at `wiki/concepts/domain-onboarding-standards.md`
   - `hermes-agent-skill` → appears in log.md only (dynamic, ignore)
   
   **Already EXISTS (do not recreate):** `wolfram-physics-project`, `aseke-framework`, `extraction-quality-audit`, `catastrophic-forgetting`, `in-context-learning`, `emergence`, `agentic-oversight`, `institutional-capture`, `geopolitics`, `evaluation`, `agent-onboarding`, `scaling-laws`, `titans`, `reasoning`, `initialization`, `criticality`, `working-memory`, `lcguard`, `epistemic-energy`, `bounded-rationality`, `panksepp-emotional-systems`, `superposition`

4. Orphan pages — add links from related pages
5. Missing frontmatter — fill required fields (highest volume issue: ~326 pages affected)
6. Confidence < 0.7 → add `## Caveats` section
7. Always ignore links in `log.md` — structural false positives (they contain dynamically generated wikilink references, not intentional cross-references)