# Obsidian Vault — Separation from Wiki

## The Two Systems Are Separate

| System | Path | What goes there |
|--------|------|-----------------|
| LLM-WIKI | `/home/ty/Documents/LLM-WIKI/` | Agent-created wiki pages, source summaries, scratchpads |
| Obsidian vault | User's personal vault (separate path) | User's personal notes, manually curated |
| paper-research | `/home/ty/Documents/paper-research/` | PDF storage for arxiv downloads |

The arxiv-agent only has access to the LLM-WIKI path via wiki tools and the paper-research path via terminal. It cannot write to Obsidian.

## What Happened (2026-05-31, 23:09)

Investigation confirmed PDFs were NOT in Obsidian — they were in `/home/ty/Documents/LLM-WIKI/`:
- `2605.22781v1.pdf` (DeltaBox)
- `2605.22786v1.pdf` (LCGuard)
- Also found: `betteti-idp-hopfield-sciadv-2025.pdf` in `Clippings/papers/2025/`

**Root cause identified**: The cron job's workdir is `/home/ty/Documents/LLM-WIKI/`. curl downloads used what appeared to be absolute paths but the shell resolved them relative to workdir, OR the agent used relative paths. When workdir is LLM-WIKI and you don't use a fully-absolute path starting with `/`, files land in the wrong directory.

**Confirmed by**: Files existed in paper-research (correct location from an earlier run) AND in LLM-WIKI (wrong location from this run).

## Resolution

1. All PDFs moved from LLM-WIKI to paper-research
2. LLM-WIKI is now clean (zero PDFs)
3. Skill and agent sheet updated with explicit rule: **every curl download MUST use absolute path starting with `/home/ty/Documents/paper-research/`**

## What the Agent Should Never Do

- Write PDFs to any location other than `/home/ty/Documents/paper-research/`
- Trust that a path is absolute just because it looks like one in the command — always verify with `ls` after downloading
- Attempt to write to Obsidian vault (no access)

## What the Agent Should Always Do

After any PDF download: `ls -la /home/ty/Documents/paper-research/{id}.pdf` to confirm it landed in the right place.