# Cron Job Toolset Reference

## The Problem
`enabled_toolsets` controls which tools a cron agent can use. Missing tools cause silent failures — the job shows `last_status: ok` but the actual work was skipped.

## Correct Toolset (all 7 wiki agents)
```
terminal, file, read_file, web, search, skills, search_files, session_search, patch, write_file
```

## Tool-by-Tool Justification

| Tool | Why needed |
|------|-------------|
| `terminal` | Run shell commands (heredoc Python, curl, find, git) |
| `file` | Filesystem operations (mkdir, mv, rm via terminal) |
| `read_file` | Read skill files, agent sheets, wiki pages before editing |
| `web` | Fetch URLs, download from arXiv, web search |
| `search` | MCP wiki_search for wiki discovery |
| `skills` | Load and patch skill files |
| `search_files` | Grep-style content search, glob find |
| `session_search` | Search conversation history for prior context |
| `patch` | Surgical targeted string replacements — primary editing tool |
| `write_file` | Full-file overwrite (fallback when patch won't work) |

## NOT needed
- `execute_code` — not available to cron agents
- MCP tools (`wiki_write_page`, `wiki_lint`, etc.) — routed through MCP server, not toolset-gated

## Error → Missing Tool Mapping

| Error | Missing tool |
|-------|-------------|
| `Background review denied non-whitelisted tool: patch` | `patch` |
| `Background review denied non-whitelisted tool: read_file` | `read_file` |
| `Background review denied non-whitelisted tool: search_files` | `search_files` |
| `Background review denied non-whitelisted tool: terminal` | `terminal` |
| `Background review denied non-whitelisted tool: write_file` | `write_file` |
| `{status: pending_approval}` on foreground call | No `&` in foreground heredoc; use `background=True` |

## Verification Command
```bash
# After updating a cron job, verify its toolsets:
hermes cron list  # or via cronjob action=list)
```

## Wiki Agent Jobs

| Job ID | Name | skill | Toolset |
|--------|------|-------|---------|
| `8ea33cfa560a` | Wiki Researcher | researcher-agent | full (above) |
| `72599f850df2` | arxiv-top3-weekly | arxiv-agent | full |
| `eaaa6bdc8503` | world-news-daily | news-agent | full |
| `c838e81a1496` | llm-wiki-raw-ingest | ingest-agent | full |
| `48a3a009a820` | Wiki Librarian | librarian-agent | full |
| `385aa0819a57` | Wiki Librarians-Assistant | librarians-assistant | full |
| `723e76246970` | Wiki Insights Generator | insights-agent | full |

All jobs: `workdir: /home/ty/Documents/LLM-WIKI` except insights-generator (`project-synapse-mcp`).

## When Adding a New Tool to a Skill
If a skill introduces a new tool call (e.g., `patch` for `fix_frontmatter_missing_closing`), that tool must be added to the cron job's `enabled_toolsets` before the next run — otherwise the call silently fails.