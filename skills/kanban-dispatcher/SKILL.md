---
name: kanban-dispatcher
description: Every 2h routes unclaimed kanban tasks to agent skills for execution
triggers:
  - cron: 0 */2 * * *
  - manual: delegate_task
routing:
  ingest: ingest-agent
  librarian: librarian-agent
  librarians-assistant: librarians-assistant
  researcher: researcher-agent
  news-agent: news-agent
  arxiv-agent: arxiv-agent
  insights-agent: insights-agent
  web-researcher: web-researcher-agent
---

# Kanban Dispatcher

Dispatches unclaimed `ready` tasks to the appropriate agent skill by routing on task assignee prefix.

## Trigger

Cron: `0 */2 * * *` (every 2 hours), or manual run via `delegate_task`.

## Process

1. **Find unclaimed tasks** — `ready` status, no `task_runs` entry (never dispatched)
2. **Route by assignee prefix:**
   - `ingest` / `ingest-agent` → `ingest-agent` skill
   - `librarian` / `librarian-agent` → `librarian-agent` skill  
   - `librarians-assistant` → `librarians-assistant` skill
   - `researcher` / `researcher-agent` → `researcher-agent` skill
   - `news-agent` → `news-agent` skill
   - `arxiv-agent` → `arxiv-agent` skill
   - `insights-agent` → `insights-agent` skill
   - Default → skip (log, leave in `ready`)
3. **Mark task `in_progress`** via `hermes kanban update <task_id> --status in_progress`
4. **Dispatch to agent skill** via `delegate_task(goal=f"Execute kanban task {task_id}: {task_title}", skills=[<routed_skill>])`
5. **On worker failure** → mark task `ready` again so it's retried

## Verification

After dispatch, task status must be `in_progress` in kanban, and a `task_runs` row must exist in `~/.hermes/kanban.db`.

## Skills

- `kanban-morning-review` (for context on task lifecycle)
- `hermes-agent` (for cron setup commands)