---
name: kanban-orchestrator
description: Kanban board creation and workflow decomposition persona. Trigger phrases: "orchestrator", "dispatch workers", "kanban workflow creator".
profiles: [kanban-orchestrator]
model: MiniMax-M2.7
provider: minimax
---

# Kanban Workflow Creator / Orchestrator — hermes-ops Deployment Guide

**Runtime skill:** `~/.hermes/skills/autonomous-ai-agents/kanban-orchestrator/SKILL.md`

The Kanban Orchestrator is the routing layer between intent and execution. It:
1. Takes a goal and decomposes it into structured kanban tasks
2. Fans work items out to the appropriate worker lanes
3. Verifies output and closes the loop

## Trigger

- `"orchestrator"` or `"run the orchestrator"`
- `"dispatch workers"`, `"fan out"`, `"workstream"`
- `"kanban workflow creator"` — creates board structure from a goal

## Two Modes

### Mode 1: Workflow Creator
Given a goal → decompose into a full kanban board with lanes.

```
User: "build a paper ingestion pipeline"
↓
Orchestrator creates:
- Backlog lane
  - t_001: Parse PDF metadata
  - t_002: Extract figures and tables
  - t_003: Generate S2ORC JSON
- Doing lane
- Done lane
```

### Mode 2: Orchestrator Dispatch
Takes output from Research Council or TWG → fans out to workers.

```
Research Council synthesizes: "3 work items identified"
↓
Orchestrator:
- hermes kanban create for each item
- Assigns to worker lanes (codex, orcaid, subagents)
- Runs verification loop
- Closes loop on completion
```

## Deployment (hermes-ops)

### Step 1 — Load the skill

The runtime skill lives in `~/.hermes/skills/autonomous-ai-agents/kanban-orchestrator/SKILL.md`. No installation needed.

### Step 2 — Activate

```
hermes profile chat --profile kanban-orchestrator
```

### Step 3 — Provide a goal

The orchestrator reads the goal and:
1. Decomposes into discrete work items
2. Creates kanban tasks with `--body` containing the task definition
3. Assigns lane priority (backlog → ready → doing → done)
4. Sets WIP limits per lane
5. Dispatches initial items to worker lanes

### Step 4 — Monitor and close

```
hermes kanban list                          # track progress
hermes kanban complete t_XXXX --result "..."  # close with verification
hermes kanban heartbeat t_XXXX             # signal alive
```

## Orchestrator Dispatch Loop

```
WHILE unverified_items:
    item = select_next(kanban)
    worker = assign(item, worker_pool)
    result = worker.execute(item)
    IF verification_passed(result):
        kanban.complete(item, result)
        notify(user)
    ELSE:
        kanban.block(item, reason)
        notify(orchestrator, "rework needed")
```

## Profile Files

- `~/.hermes/profiles/kanban-orchestrator/SOUL.md` — identity, dispatch loop, drift correction
- `~/.hermes/skills/autonomous-ai-agents/kanban-orchestrator/SKILL.md` — runtime execution

## See Also

- [[two-council-architecture]] — orchestrator stack position
- [[delegation-verification]] — verification loop pattern
- [[orchestrator-memory]] — verified outcomes and drift logs