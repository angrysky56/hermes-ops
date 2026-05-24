# Librarians-Assistant Fix Patterns

## Duplicate Frontmatter Fix

Many wiki pages have **two concatenated frontmatter blocks** — caused by repeated patching without cleaning up the previous block. Pattern:

**Before:**
```yaml
---
summary: Added [[agem]] return link to EFHF
tags: [EFHF, lumpability, ...]
updated: 2026-05-21T23:13:31Z
---

---
created: 2026-04-14T01:26:54Z
updated: 2026-05-23T08:55:00Z
type: project
summary: Five-layer AI architecture implementing...
tags: [EFHF, lumpability, ...]
status: active
confidence: 1.0
---
```

**After (patch to remove the duplicate and merge):**
```yaml
patch(old_string="""---
summary: Added [[agem]] return link to EFHF
tags: [EFHF, lumpability, ...]
updated: 2026-05-21T23:13:31Z
---

---
created: 2026-04-14T01:26:54Z
updated: 2026-05-23T08:55:00Z
type: project
summary: Five-layer AI architecture implementing...
tags: [EFHF, lumpability, ...]
status: active
confidence: 1.0
---""",
new_string="""---
created: 2026-04-14T01:26:54Z
updated: 2026-05-23T08:55:00Z
type: project
summary: Five-layer AI architecture implementing...
tags: [EFHF, lumpability, ...]
status: active
confidence: 1.0
sources: [[edm-framework]], [[maximum-occupancy-principle]]
---""")
```

**Key rules:**
1. Always `read_file` first — don't patch without seeing the actual file structure
2. Merge ALL fields into one clean block (created, updated, type, summary, tags, sources, status, confidence)
3. Remove operational log lines from summary (e.g. "Added [[agem]] return link" — these are noise)
4. When patching duplicate frontmatter, include enough surrounding context to uniquely identify the right location

## Source-Only → Concept Elevation (P0 Stub Creation)

When a `wiki/sources/articles/<slug>.md` exists but `wiki/concepts/<slug>.md` doesn't, and the source is referenced 15+ times from concept/entity pages:

1. Read the source article
2. Write a full `wiki/concepts/<slug>.md` concept page:
   - Use the source content as the basis
   - Add `## Connections` section linking to related concepts/entities
   - Set `status: reference`, `confidence: 1.0`, `type: concept`
   - Include a "Key Pages in This Vault" section for internal wikilinks

**Example: `llm-wiki-pattern.md`** — 20+ references from concept-index, entities, and synthesis pages, but only existed as `wiki/sources/articles/llm-wiki-pattern.md`. Created `wiki/concepts/llm-wiki-pattern.md` with full concept content derived from the source.

## Frontmatter Field Priority

When filling missing frontmatter on high-value pages, prioritize:

1. `type` — entity, concept, source, synthesis
2. `sources` — URL or `[[wikilink]]` to source material
3. `status` — active (work in progress) | reference (stable) | archived
4. `confidence` — 0.0–1.0 (below 0.7 needs `## Caveats` section)
5. `created` / `updated` — ISO timestamps
6. `summary` — one-line description (don't put wikilinks in summary — they're noise in the summary field)

## Reciprocal Link Check (P1)

Top-authority pages that already have reciprocal links (skip these):
- `efhf.md` ↔ `maximum-occupancy-principle.md` — already done
- `efhf.md` ↔ `agem.md` — already done  
- `meta-harness.md` ↔ `agem.md` — already done
- `markovian-dev-agency.md` ↔ `hermes-agent.md` — already done

## Key Discovery This Session (2026-05-30)

- `engineering-internal-awareness`: Resolved — `wiki/concepts/engineering-internal-awareness.md` created. Handles all 19 references in log.md + scratchpad files. Previous "ignore" guidance superseded by actual fix.
- `isabelle-hol`: Resolved — `wiki/entities/tools/isabelle-hol.md` created. Fixes `[[isabelle-hol]]` link from `isabelle.md`.
- `word-cloud-communication`: Resolved — `wiki/concepts/word-cloud-communication.md` created.
- `domain-onboarding-standards`: Resolved — `wiki/concepts/domain-onboarding-standards.md` created.
- ALL remaining broken links per `full_audit.py` are structural false positives in `scratchpad/` report files and `log.md` — no real broken links remain in wiki content.

## Known Stub List (verified 2026-05-30 — do not recreate)

`wolfram-physics-project`, `aseke-framework`, `extraction-quality-audit`, `catastrophic-forgetting`, `in-context-learning`, `emergence`, `agentic-oversight`, `institutional-capture`, `geopolitics`, `evaluation`, `agent-onboarding`, `scaling-laws`, `titans`, `reasoning` — all verified existing.

## Key Discovery (2026-06-08)

- **Orphan problem resolved**: Only 2 orphans remain — `log.md` and `insights.md` (system files, no inbound expected). Content orphans are resolved.
- **Real wiki content is clean**: All 171 "broken wikilinks" are in scratchpad/news/report files. No content-layer broken links remain.
- **Frontmatter progress**: 16 entity/tool pages + 14 synthesis pages fixed. Missing frontmatter dropped from 304 to 282.