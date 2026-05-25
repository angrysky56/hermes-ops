---
name: kanban-morning-review
description: "Morning kanban review — parse all agent carryovers after cron reports, surface open questions as Hermes kanban tasks, update agent status, deliver Discord summary. Creates tasks in hermes kanban (not sheet.md). Proactive: each morning agent cron triggers its own carryover parse."
tags: [kanban, cron, wiki, llm-wiki, task-board, delegation]
updated: 2026-06-26
created_by: agent
---

# Kanban Morning Review

**Purpose**: After morning cron reports land, parse all agent carryovers, surface open questions as Hermes kanban tasks, update agent task status, and deliver a Discord summary to origin.

**Wiki root**: Uses `$WIKI_PATH` env var — defaults to `$HOME/Documents/LLM-WIKI` if unset.

**Proactive trigger**: Each morning agent cron fires its own kanban review. The trailing `Morning Kanban Review` cron at 10:30 AM aggregates and summarizes. Each agent cron should invoke this skill after writing its carryover, so items appear in kanban immediately rather than waiting for a manual review.

**Output destinations**:
- Hermes kanban: tasks created for each open question, assigned to the relevant agent
- Discord: summary of surfaced items with kanban links
- Each agent's carryover: noted with surfaced status

---

## Morning Agent Cron Pattern

Each morning cron (insights, news, arxiv, ingest, librarian, librarians-assistant, researcher) should:

1. Run its agent skill normally
2. At the end of the run, invoke this `kanban-morning-review` skill on the carryover it just wrote
3. The skill creates hermes kanban tasks for each open item found

The trailing 10:30 AM cron aggregates all carryovers into a summary Discord message.

---

## Active Agents and Carryover Paths

Workdir for all: `$WIKI_PATH` (env var, default `$HOME/Documents/LLM-WIKI`)

| Agent | Carryover Path |
|-------|----------------|
| insights | `wiki/scratchpad/jobs/reports/insights/carryover.md` |
| news | `wiki/scratchpad/jobs/reports/news/carryover.md` |
| arxiv | `wiki/scratchpad/jobs/reports/arxiv/carryover.md` |
| ingest | `wiki/scratchpad/jobs/reports/ingest/carryover.md` |
| librarian | `wiki/scratchpad/jobs/reports/librarian/carryover.md` |
| librarians-assistant | `wiki/scratchpad/jobs/reports/librarians-assistant/carryover.md` |
| researcher | `wiki/scratchpad/jobs/reports/researcher/carryover.md` |
| web-researcher | `wiki/scratchpad/jobs/reports/web-researcher/carryover.md` |

**Note**: `web-researcher` is not a time-based cron. Its carryover is written after each task completion (STEP 6 of the web-researcher workflow). The trailing morning-review cron only processes time-based morning agents.

**Important**: Agent dir names use hyphens (`librarians-assistant`), not underscores. Carryover filename is `carryover.md`.

---

## Workflow

### STEP 1 — Read the agent's carryover

Read the carryover file for the agent being processed. Extract:
- **Open Questions** (explicit "Open Questions" / "What Remains" / "Still Open" / "Next" sections)
- **Research Directions** (emerging topics needing deeper coverage)
- **Hard Blockers** (items needing human judgment / Ty input)
- **Priority** (from carryover's own language — high/med/low, default med)

### STEP 2 — Create hermes kanban tasks

**Primary: direct SQL via Python**

The `hermes kanban` CLI is narrow. Direct sqlite3 is more reliable for bulk task creation:

```python
import sqlite3, hashlib, os

DB = sqlite3.connect(os.path.expanduser("~/.hermes/kanban.db"))
cur = DB.execute(
    "SELECT id, title, status FROM tasks WHERE status != 'done'",
    ()
)
existing = {str(row[1]).strip(): row[0] for row in cur.fetchall()}

def upsert(agent, title, body, priority=1, blocked=False):
    key = f"{agent}: {title}".strip()
    if key in existing:
        return existing[key], "skipped"
    ik = hashlib.sha256(key.encode()).hexdigest()[:16]
    status = "blocked" if blocked else "ready"
    cur.execute("""
        INSERT INTO tasks
          (id, title, body, assignee, status, priority, created_by, idempotency_key)
        VALUES (?, ?, ?, ?, ?, ?, 'cron:kanban-morning-review', ?)
    """, (f"t_{ik}", key, body, agent, status, priority, ik))
    DB.commit()
    return f"t_{ik}", "created"

priority_map = {"high": 2, "medium": 1, "low": 0}
```

**Fallback: hermes kanban CLI** (if Python is unavailable):

```bash
hermes kanban create "{agent}: {title}" \
  --body "{description}\n\nSource: {agent}/carryover.md" \
  --assignee "{agent}" \
  --priority {0|1|2}

hermes kanban block t_XXXX   # for blocked items
```

**Priority values**: 0=low, 1=med, 2=high — use integers only. The `--metadata` flag does NOT exist on `hermes kanban create` — do not use it.

### STEP 3 — Update agent carryover

Patch the agent's carryover to annotate surfaced items:

```markdown
## Kanban Status
- [x] Surfaced to hermes kanban: YYYY-MM-DD HH:MM
  - {count} open items → {kanban task IDs}
```

### STEP 4 — Deliver Discord summary (trailing cron only)

The trailing 10:30 AM cron sends the aggregate summary to Discord origin:

```
**Morning Kanban — YYYY-MM-DD**

{count} open questions from {N} agents → Hermes kanban

**High Priority** ({N} items)
[ ] {agent}: {question} → t_XXXX

**Blocked (needs Ty)** ({N} items)
[ ] {agent}: {blocked item} → t_XXXX

Run: `hermes kanban list` to see all tasks
```

If an agent has no open items, skip it silently.

---

## Correct Paths

Workdir: `$WIKI_PATH` (env var, default `$HOME/Documents/LLM-WIKI`)

| Resource | Path |
|----------|------|
| sheet.md | `wiki/scratchpad/jobs/sheet.md` |
| carryovers | `wiki/scratchpad/jobs/reports/{agent}/carryover.md` |
| agent sheets | `wiki/scratchpad/agent-sheets/{agent}.md` |
| kanban.db | `~/.hermes/kanban.db` |

---

## hermes kanban CLI — Known Limitations

- `hermes kanban create` does NOT support `--metadata` flag (this was an erroneous invention in an earlier draft — do not use)
- `hermes kanban list` is the correct read/query interface
- `hermes kanban block <id>` sets status to `blocked`
- `hermes kanban assign <id> <agent>` sets the assignee
- For bulk creates with metadata, use direct sqlite3 (see STEP 2)

---

## Quality Rules

- Only create tasks for genuinely open items (not done, not stale)
- **Attempt self-answer first**: Before creating any task, try to answer the question using available context:
  - Search the wiki (`search_files` or `mcp_project_synapse_wiki_search`) for existing content on the topic
  - Check carryover Established section for related filled concepts
  - Consult `synapse_recall` for relevant episodic facts
  - If the answer exists in wiki/synapse context → write it directly to the carryover as "Resolved this cycle" and skip task creation
- Only create a task when the question genuinely cannot be answered from available context
- Blocked items (needs Ty input) must be marked with `hermes kanban block` after creation (or set status="blocked" in SQL)
- Use the carryover's own priority language; default to `med` (1)
- Don't duplicate tasks already in kanban — check via `hermes kanban list` or SQL query before inserting
- If carryover is missing or has no open items, skip silently
- Use idempotency: hash of `"${agent}: ${title}"` as `idempotency_key` to prevent duplicates across runs
- **Answered items**: If an open question gets answered during the review, patch the carryover to mark it resolved — don't create a task for it

---

## Edge Cases

- **Carryover missing**: skip that agent, note in Discord summary
- **All agents clean** (no open items): send `[SILENT]` — nothing to surface
- **Item already in kanban**: skip (check existing titles before inserting)
- **Agent dir name with hyphen**: `librarians-assistant` uses hyphens, not underscores
- **Python unavailable**: fall back to `sqlite3` CLI via `terminal()`, or `hermes kanban create` CLI (with known limitations above)