---
name: librarians-assistant
description: "Wiki remediation agent — fixes broken links, orphans, non-reciprocal wikilinks, frontmatter, and tags identified by the Wiki Librarian audit. Runs after librarian at 08:50 AM daily."
trigger: /librarians-assistant
---

# Librarians Assistant

**Loads:** `wiki/scratchpad/agent-sheets/librarians-assistant.md` for full directives
**MCP tools reference:** `wiki/scratchpad/jobs/mcp-tools-reference.md` — all 22 tools documented with args, behaviors, and known issues
**Wiki root:** `/home/ty/Documents/LLM-WIKI`
**Runs after:** Wiki Librarian (48a3a009a820) — reads its carryover for context

## Bootstrap

1. Read this skill file (you just did)
2. Read your agent sheet: `wiki/scratchpad/agent-sheets/librarians-assistant.md`
3. Read the librarian's carryover: `wiki/scratchpad/jobs/reports/librarian/carryover.md`
4. Read the batch progress: `wiki/scratchpad/jobs/reports/librarian/batch-progress.md` (if it exists)
5. **Verify MCP availability before using your tools — TWO steps:**
   ```bash
   # Step 1: Package import (necessary but NOT sufficient)
/home/ty/Repositories/ai_workspace/project-synapse-mcp/.venv/bin/python3 -c "from synapse_mcp.zettelkasten.insight_engine import InsightEngine; print('OK')" 2>/dev/null && echo "PACKAGE OK" || echo "PACKAGE MISSING"
   ```
   This confirms `synapse_mcp` is in the project-synapse-mcp venv — but `InsightEngine` import does NOT guarantee `wiki_lint`, `wiki_cluster_pages`, etc. are registered MCP handlers.

   ```bash
   # Step 2: Make an actual MCP call to verify tools are registered
   # Try: debug_test, wiki_lint, or wiki_list_pages
   ```
   If Step 1 succeeds but Step 2 fails (tool not found), MCP server is running but the tool wasn't registered. Use filesystem fallback.
   
   **If MCP is unavailable:** Use direct filesystem fixes instead of MCP tools (see fallback below).
6. Execute per the agent sheet

## Your Tools (all via project-synapse MCP)

- `wiki_lint()` — detect remaining broken links, orphans, missing frontmatter
- `wiki_read_page` — read a page to fix it
- `wiki_write_page` — fix frontmatter, add wikilinks, normalize tags
- `wiki_search` — find related pages for orphan linking
- `wiki_cluster_pages()` — find same-cluster pages for cross-linking

## MCP Unavailable — Filesystem Fallback

When the MCP availability probe (`python3 -c "from synapse_mcp.zettelkasten.insight_engine import InsightEngine; print('OK')"`) returns UNAVAILABLE, use direct filesystem operations instead:

1. **Broken wikilinks**: grep for `\[\[` patterns, resolve via filesystem read/write
2. **Orphan pages**: analyze wikilink graph with Python script at `wiki/scratchpad/full_audit.py`
3. **Frontmatter**: use `grep -l "^---" wiki/**/*.md | xargs python3 -c "..."` for bulk operations
4. **Reciprocal link gaps**: compute wikilink graph, find asymmetric edges, add return links

The `wiki/scratchpad/full_audit.py` script is the primary audit tool in MCP-unavailable environments — run it first to get current state.

## Key Paths

```
Wiki:                       /home/ty/Documents/LLM-WIKI/
Agent sheet:                wiki/scratchpad/agent-sheets/librarians-assistant.md
Librarian carryover:        wiki/scratchpad/jobs/reports/librarian/carryover.md
Batch progress:             wiki/scratchpad/jobs/reports/librarian/batch-progress.md
Assistant carryover:        wiki/scratchpad/jobs/reports/librarians-assistant/carryover.md
```

## Workflow

1. Read carryover from last librarian run — understand what was already fixed and what remains
2. Read batch-progress.md if it exists — know where previous assistant run stopped
3. **Always verify MCP availability first** (see Bootstrap step 5)
4. Run fixes in priority order (from carryover's "Next session focus")
5. Write progress every 15-20 fixes to batch-progress.md
6. When done (50+ fixes or hard blocker): update assistant carryover with open items

## Known Pitfalls

### CRITICAL: All cron jobs need full `enabled_toolsets`
If any tool is missing from `enabled_toolsets`, the call silently fails and the job shows `last_status: ok` while the work was skipped. See `references/cron-toolsets.md` for the complete toolset table, error → missing-tool mapping, and job ID reference.

### CRITICAL: execute_code is NOT available to cron agents
The "Primary Frontmatter Fix Workflow" section shows `terminal` heredoc as the **fallback** — this pattern is unreliable in cron context (triggers `pending_approval`). Preferred fallback order:
1. **`wiki_write_page`** (MCP) — best for wiki pages, bypasses filesystem
2. **`write_file`** (toolset) — direct overwrite, reliable for targeted fixes
3. **Terminal heredoc** — only if both above are unavailable; risks `pending_approval`

When using `write_file` to fix frontmatter, read the file first with `read_file`, then write corrected content with `write_file`. Prefer `wiki_write_page` (MCP) over filesystem writes wherever possible.

### generate_insights CLI — use correct pattern
The Zettelkasten engine times out at 300s via MCP. For CLI insight generation, use:
```bash
timeout --kill-after=10s 580s uv run python /home/ty/Repositories/ai_workspace/project-synapse-mcp/scripts/generate_insights.py --topic general --print --max-runtime 540
```
Exit codes: 0=success, 3=timeout (file may be valid), 1=init failure. Do NOT use `~/.hermes/scripts/generate_insights.sh` — that script does not exist.

- **`concept-index.md` is auto-generated** — its broken links should NOT be manually fixed; fix the generation pipeline instead
- **`log.md` links are structural false positives** — they contain dynamically generated wikilink references, ignore them in broken link audits
- **Compound-tag noise in news sources**: `[['news', 'geopolitics', ...]]` style tag arrays are noise, not real wikilinks — strip them, don't create links for them (18+ instances)
- **Insight generation is unreliable**: `generate_insights()` times out after 300s; if it fails, skip and note in carryover — do NOT retry the same cycle
- **Orphan counts differ by method**: MCP `wiki_lint()` reports ~155 orphans (Neo4j graph), while `full_audit.py` filesystem scan may report 0 — these are not comparable; use MCP results when available
- **Top authorities need depth, not just links**: efhf, maximum-occupancy-principle, project-synapse, edm-framework are load-bearing pages — when linking to them, add substantive content, not just wikilinks
### Broken link triage — filesystem pre-scan beats full_audit.py for content focus

`full_audit.py` reports broken links in ALL files including scratchpad/report noise. To focus on real wiki content:

```bash
cd /home/ty/Documents/LLM-WIKI && python3 -c "
import re, os

# Only scan high-value content dirs (not scratchpad)
dirs = ['wiki/concepts', 'wiki/entities', 'wiki/synthesis', 'wiki/sources']
all_md = {}
for root, _, files in os.walk('wiki'):
    for f in files:
        if f.endswith('.md'):
            all_md[f[:-3].lower()] = os.path.join(root, f)

broken = []
for d in dirs:
    if not os.path.exists(d): continue
    for root, _, files in os.walk(d):
        for f in files:
            if not f.endswith('.md'): continue
            path = os.path.join(root, f)
            with open(path) as fh: content = fh.read()
            links = re.findall(r'\[\[([^\]|]+)', content)
            for link in links:
                slug = link.strip().lower().replace(' ', '-').replace('/', '-')
                if slug not in all_md:
                    broken.append((path, link))
# Group by link target
from collections import Counter
counter = Counter([link for _, link in broken])
for link, count in counter.most_common(20):
    print(f'  {link}: {count} references')
"
```

`wiki/sources/` always has the most broken link targets (131 at 2026-06-08) — these are entity references from Zettelkasten insight generation, not content gaps. `wiki/concepts/` and `wiki/entities/` should always have 0 broken links if prior cycles ran correctly.

### Template wikilink examples vs. real broken links

Some pages contain intentional template syntax in their documentation/body. These appear as broken links but are NOT real issues:

- `synapse-llm-wiki-operating-guide.md` contains `[[page-slug]]`, `[[slug]]`, `[[Display]]` — these are **template examples** in the Wikilink Rules section showing correct wikilink syntax. Do NOT create stubs for these.

To detect this case: if a wikilink target looks like a generic placeholder (contains "slug", "page-", "display") and the containing file is a documentation/operating-guide page, verify the context before creating a stub. The correct scan already excludes code blocks, but these template examples appear as inline prose examples, not in code blocks.

### Insight pages have a specific dual-frontmatter pattern

The Zettelkasten engine produces insight pages with TWO frontmatter blocks concatenated:
1. A minimal auto-generated block (created, updated, summary, tags)
2. A full block (created, updated, type, summary, tags, sources, status, confidence)

After running the duplicate-frontmatter cleaner, **verify the result** — extra `---` delimiters can remain between blocks, leaving the file still malformed. Always do a `head -10` check after cleaning insight pages. If double `---` delimiters appear, use `write_file` with the fully merged content.

### write_file safety

`write_file` OVERWRITES the entire file. Use it only when:
- You have freshly read the full file (not offset-limited)
- You are constructing the content from scratch (e.g., merging duplicate blocks)
- You have verified the current state before overwriting

Do NOT use `write_file` as a substitute for `patch` when fixing small targeted issues — `patch` is safer for surgical edits.

### Current cleaner limitation

The duplicate frontmatter cleaner (`fix_frontmatter_missing_closing`) removes the duplicate field lines but CAN leave extra `---` blank-`---` sequences between blocks, requiring a second pass or manual write_file. The cleaner function detects body start by first `# ` heading, but doesn't handle the case where the "cleaned" output still has two `---` delimiters with blank lines between them. Workaround: after cleaner, check `grep -c '^---' file.md`. If count > 2, use write_file to manually merge.
- **P0: elevate source → concept when wikilinks outnumber content**: If a wikilink target only exists as a `wiki/sources/articles/<slug>.md` but is referenced 20+ times from `wiki/concepts/` and `wiki/entities/`, create a full `wiki/concepts/<slug>.md` concept page rather than a stub. Use the source article content as the basis; add connections to related concepts/entities.
- **engineering-internal-awareness wikilink**: Already resolved this session — `wiki/concepts/engineering-internal-awareness.md` created (2026-05-30) to handle all 19 references in log.md + scratchpad files. Previous guidance to "ignore" is now replaced with actual fix.

#### Reference Files — USE FULL PATHS

**Path rule:** Reference files are in the skill directory, NOT relative to workdir. Always use absolute paths.

| File | Full path |
|------|-----------|
| `fix-patterns.md` | `/home/ty/.hermes/skills/agent-sheets/librarians-assistant/references/fix-patterns.md` |
| `stub-fix-log.md` | `/home/ty/.hermes/skills/agent-sheets/librarians-assistant/references/stub-fix-log.md` |

**Never use relative paths like `references/fix-patterns.md`** — the agent's workdir is `/home/ty/Documents/LLM-WIKI`, so relative paths resolve to the wrong location.

If a file read fails, search for it first:
```bash
find /home/ty/.hermes/skills/agent-sheets/librarians-assistant/ -name "*.md" 2>/dev/null
```

## Known Stub List

## Known Stub List (verified 2026-05-30 — do not recreate)

`wolfram-physics-project`, `aseke-framework`, `extraction-quality-audit`, `catastrophic-forgetting`, `in-context-learning`, `emergence`, `agentic-oversight`, `institutional-capture`, `geopolitics`, `evaluation`, `agent-onboarding`, `scaling-laws`, `titans`, `reasoning` — all verified existing.

## Complex Synthesis Pages — Do Not Auto-Clean (Accurate Description)

These 8 pages had **duplicate field lines within a single frontmatter block** (e.g., `created`, `updated`, `type`, `summary` each appear twice), and **no closing `---`** delimiter — frontmatter ran directly into body content. The skill's bulk cleaner code was wrong about the block structure.

**Status (2026-06-08): ALL 8 FIXED.**

- `cross-layer-drift-falsification.md` — **FIXED**
- `codegraph-hermes-integration-plan.md` — **FIXED**
- `librarian-report-2026-05-09.md` — **FIXED**
- `self-prompting-via-production-stage-architecture.md` — **FIXED**
- `essan-internal-representation.md` — **FIXED**
- `wiki-indexing-theory.md` — **FIXED**
- `research-brief-2026-05-09.md` — had no frontmatter at all — **FIXED** (added from scratch)
- `research-brief-2026-05-13.md` — had no frontmatter at all — **FIXED** (added from scratch)

**Additional insight pages fixed (2026-06-08 session):**
- `wiki/synthesis/insights/para-knowledge-architecture-cohesion-insight.md` — dual block merged
- `wiki/synthesis/insights/francesca-albanese-sanctions-case-insight.md` — dual block merged

The Zettelkasten engine produces insight pages with a specific dual-frontmatter pattern. See "Insight pages have a specific dual-frontmatter pattern" pitfall above for cleanup verification steps.

## Correct Bulk Duplicate Frontmatter Cleaner

**The `split('\n---\n')` approach FAILS for files missing the closing `---`.** Use this instead:

```python
import re

def fix_frontmatter_missing_closing(path):
    """Fix frontmatter with duplicate fields and NO closing '---' delimiter."""
    with open(path, 'r') as f:
        lines = f.read().split('\n')

    if lines[0] != '---':
        return False, "no opening ---"

    # Find boundary: first line starting with '#' (markdown heading) = body start
    fm_end = -1
    for i in range(1, len(lines)):
        if lines[i].startswith('# ') or (lines[i].strip() and not re.match(r'^[\w-]+:', lines[i])):
            fm_end = i - 1
            break
    while fm_end >= 0 and lines[fm_end].strip() == '':
        fm_end -= 1  # strip trailing blank lines

    fm_lines = lines[0:fm_end+1]
    body_lines = lines[fm_end+1:]

    # Deduplicate: last value wins for each key
    fields = {}
    for line in fm_lines[1:]:  # skip opening ---
        m = re.match(r'^(\w[\w-]*):(.*)', line)
        if m:
            fields[m.group(1)] = line

    # Rebuild in canonical field order
    order = ['created', 'updated', 'type', 'summary', 'tags', 'sources', 'status', 'confidence']
    new_fm_lines = ['---']
    for key in order:
        if key in fields:
            new_fm_lines.append(fields[key])
    new_fm_lines.append('---')

    with open(path, 'w') as f:
        f.write('\n'.join(new_fm_lines) + '\n' + '\n'.join(body_lines))
    return True, f"cleaned, kept {len(fields)} fields"
```

**Also handles:** files that have frontmatter but no closing `---` (the frontmatter just runs into body). Detect by: `if content.startswith('---') and '---' not in content[3:content.find('\n# ')]`.

## Known Broken Wikilink Targets (need stub creation)

- **`mesa-optimization`** — referenced in `wiki/concepts/reward-hacking.md` but page does not exist. Stub created (2026-06-08) with note "mesa-optimization (stub — page not yet created)"; a full stub page should be created if this link is referenced elsewhere.

## PDF Path Contamination — Detection and Cleanup

**Problem:** Other agents (arxiv-agent) may write PDFs to the wrong directory when workdir changes. Files land in `/home/ty/Documents/LLM-WIKI/` instead of `/home/ty/Documents/paper-research/`. This causes the wiki folder to grow with binary files that shouldn't be there.

**Detection:**
```bash
find /home/ty/Documents/LLM-WIKI -name "*.pdf" -type f 2>/dev/null
```
If any results appear, PDFs have migrated to the wrong location.

**Cleanup (move to correct location):**
```bash
# Move strays to paper-research
mv /home/ty/Documents/LLM-WIKI/2605.22781v1.pdf /home/ty/Documents/paper-research/
mv /home/ty/Documents/LLM-WIKI/2605.22786v1.pdf /home/ty/Documents/paper-research/

# Also check Clipping subdirectories
find /home/ty/Documents/LLM-WIKI -name "*.pdf" -exec mv {} /home/ty/Documents/paper-research/ \; 2>/dev/null
```

**Prevention (for arxiv-agent):** Always verify after download: `ls -la /home/ty/Documents/paper-research/{id}.pdf` confirms the file landed in the right place, not the current workdir. See `references/obsidian-vault.md` for the full post-mortem.

## Reference Files

- `references/obsidian-vault.md` — Obsidian vs wiki separation, PDF path contamination post-mortem
- `references/stub-fix-log.md` — verified stubs from prior sessions (do not recreate)
- `references/fix-patterns.md` — **UNVERIFIED** — this file was listed but may not exist on disk; verify before loading

## Wikilink Normalization Pattern

### 2026-05-31 (this session)
- 54 frontmatter completions (40 concept + 4 people + 14 project/entity pages) using batch Python approach
- Verified efhf ↔ maximum-occupancy-principle already reciprocal (skip creation)
- Verified markovian-dev-agency → hermes-agent and hermes_agent → load-bearing-reasoning already have return links
- MCP: UNAVAILABLE (confirmed — norm for this environment)

### 2026-06-08 (assistant run after librarian)
- 9 fixes: 1 broken wikilink + 8 frontmatter fixes (6 pages missing closing `---`, 2 pages missing frontmatter entirely)
- MCP: OK (project-synapse-mcp venv confirmed working)
- Wiki content confirmed clean — broken links (165) ALL in scratchpad/report files; orphans (158) ALL in scratchpad/system files
- Key discovery: `maximum-occupancy-principle.md` actually EXISTS at `wiki/concepts/maximum-occupancy-principle.md` — prior sessions listed it as non-existent incorrectly

### 2026-05-30 (prior session)
- 4 wikilinks normalized (llm-wiki-pattern.md, meta-harness.md)
- 31 duplicate frontmatter pages cleaned (16 concept/entity + 11 synthesis + 4 type:missing)
- 3 alias stubs verified clean: reasoning.md, llama-nas.md, rz-nas.md
- 8 complex synthesis pages with 26-34 blocks identified — do NOT auto-clean, need individual review

## MCP Status — Correct Understanding

**MCP probe — TWO steps, not one:**

Step 1 (package import — necessary but NOT sufficient):
```bash
/home/ty/Repositories/ai_workspace/project-synapse-mcp/.venv/bin/python3 -c "from synapse_mcp.zettelkasten.insight_engine import InsightEngine; print('OK')" 2>/dev/null && echo "PACKAGE OK" || echo "PACKAGE MISSING"
```
This confirms the `synapse_mcp` package is in the project-synapse-mcp venv — NOT the hermes-agent venv.

Step 2 (tool registration — the actual test):
After the import succeeds, make an actual MCP call: `debug_test` or `wiki_lint`. If it returns, tools are registered. A clean `InsightEngine` import does NOT guarantee `wiki_lint`, `wiki_cluster_pages`, `wiki_hits_analysis` are available — those are registered MCP handlers in the server itself, not standalone Python modules.

**If MCP calls succeed:** Use the MCP tools freely — `wiki_lint()` (~5s), `wiki_cluster_pages()` (~10s), `wiki_hits_analysis()` (~10s), `wiki_write_page` (primary wiki write channel).

**If MCP is down (import fails):** Fall back to filesystem via `python3 wiki/scratchpad/full_audit.py`.

**IMPORTANT: `generate_insights()` times out at 300s.** Do NOT use the MCP tool in cron context. Use the CLI wrapper:
```bash
timeout --kill-after=10s 580s uv run python /home/ty/Repositories/ai_workspace/project-synapse-mcp/scripts/generate_insights.py --topic general --print --max-runtime 540
```
Exit codes: 0=success, 3=timeout (file may be valid), 1=init failure. Do NOT use `~/.hermes/scripts/generate_insights.sh` — that path does not exist.

## Primary Frontmatter Fix Workflow (MCP Unavailable)

When filling missing `type`/`sources`/`status`/`confidence` on 10+ pages, use batch Python via `terminal` heredoc — NOT `execute_code` (which is not available to cron agents):

```bash
cd /home/ty/Documents/LLM-WIKI && python3 << 'PYEOF'
import re, os

pages = [
    ("wiki/concepts/page1.md", ["type", "sources", "status", "confidence"]),
    ("wiki/concepts/page2.md", ["sources", "status"]),
]
for path, missing in pages:
    if not os.path.exists(path):
        print(f"SKIP: {path} does not exist")
        continue
    with open(path) as f:
        content = f.read()
    fm_match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not fm_match:
        print(f"NO FM: {path}")
        continue
    fm_text = fm_match.group(1)
    body = content[fm_match.end():]
    updates = {"sources": "[]", "status": "active", "confidence": "0.8"}
    for key, val in updates.items():
        if key not in fm_text and key in missing:
            fm_text += f"\n{key}: {val}"
    with open(path, "w") as f:
        f.write(f"---\n{fm_text}\n---{body}")
    print(f"OK: {os.path.basename(path)}")

print("Done.")
PYEOF
```

Batch in groups of 10-15. Verify sample files before continuing.

## Reciprocal Link Pre-Verification

Before creating reciprocal links, check if they already exist:
```bash
grep -l "\[\[target-page\]\]" wiki/concepts/*.md wiki/entities/*.md wiki/synthesis/*.md 2>/dev/null
```
Common pairs that are ALREADY reciprocal (skip creation):
- `efhf.md` ↔ `maximum-occupancy-principle.md` — efhf.md sources field + MOP connections section
- `markovian-dev-agency.md` → `hermes-agent.md` — already linked in both directions
- `hermes_agent.md` → `load-bearing-reasoning.md` — reasoning.md has return link

## Delivery Rule

- Delivery: origin (Discord thread)  
- Report: "Fixed N broken links, resolved N orphans, normalized N pages, added N wikilinks"  
- If nothing left to do: `[Librarians-assistant — no open items]`  
- Do NOT write a report file — output goes to cron delivery