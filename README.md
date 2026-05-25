# hermes-ops

**Autonomous AI knowledge curation stack — news, research, and wiki maintenance on autopilot.**

hermes-ops is the operational layer for a self-sustaining knowledge graph. It runs a suite of specialized agents that monitor global news, curate academic papers, audit wiki integrity, and surface insights — all coordinated through Hermes Agent cron jobs and the Synapse MCP server.

This repo contains **only the operational layer**: agent skills, agent sheets, wiki operating guides, and setup scripts. It does NOT include:

- `hermes-agent` itself → [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
- `project-synapse-mcp` → [angrysky56/project-synapse-mcp](https://github.com/angrysky56/project-synapse-mcp) (separate install)

---

## What This Stack Does

[Example of the WIKI it builds (my wiki)](https://github.com/angrysky56/LLM-WIKI)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    HERMES CRON SCHEDULER                             │
│         (hermes-agent CLI — schedules all agent jobs)               │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┬──────────────┬───────────────┐
        ▼              ▼              ▼              ▼               ▼
   ┌─────────┐   ┌──────────┐  ┌──────────┐  ┌─────────┐   ┌──────────┐
   │  News   │   │   ArXiv  │  │Researcher│  │Librarian│   │ Insights │
   │  Agent  │   │  Agent   │  │  Agent   │  │  Agent  │   │   Agent  │
   └────┬────┘   └────┬─────┘  └────┬─────┘  └────┬────┘   └────┬─────┘
        │             │             │             │              │
        │ RSS/curl    │ arXiv API   │ Graph query │ MCP tools    │ Zettelkasten
        │             │ + curl PDF  │ + wiki write│ + filesystem │ CLI engine
        ▼             ▼             ▼             ▼              ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │                    Synapse MCP Server                            │
   │              (Montague Grammar + Neo4j knowledge graph)          │
   └─────────────────────────────┬───────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
             ┌─────────────┐           ┌──────────────┐
             │    Neo4j    │           │    Obsidian  │
             │  (graph +   │           │   (wiki +    │
             │   vector)   │           │   vault)     │
             └─────────────┘           └──────────────┘
```

### Agent Roles

| Agent                     | Trigger                 | Schedule        | What it does                                                                                                                            |
| ------------------------- | ----------------------- | --------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **news-agent**            | `/news-agent`           | Daily 08:00 AM  | Scans global news via Google RSS, ingests 3–5 significant stories to `wiki/sources/articles/`, writes `headlines-YYYY-MM-DD.md` reports |
| **arxiv-agent**           | `/arxiv-agent`          | Daily 08:20 AM  | Discovers top ML/AI papers on arXiv, downloads PDFs, writes source summaries to `wiki/sources/papers/`                                  |
| **researcher-agent**      | `/researcher-agent`     | Daily 08:10 AM  | Identifies knowledge gaps in the wiki using graph queries, fills stubs, creates concept pages                                           |
| **ingest-agent**          | `/ingest-agent`         | Daily 08:30 AM  | Processes raw inbox files through the Synapse pipeline into structured wiki knowledge                                                   |
| **librarian-agent**       | `/librarian-agent`      | Daily 08:50 AM  | Runs full vault audit (orphans, broken links, frontmatter debt, HITS scoring), delegates fixes to librarians-assistant                  |
| **librarians-assistant**  | `/librarians-assistant` | After librarian | Iterative remediation: fixes broken wikilinks, resolves orphans, normalizes frontmatter and tags                                        |
| **web-researcher**      | `/web-researcher`       | On-demand (kanban) | ACRIS-ACP external web research — answers open questions from morning agents via multi-source search; hands off to researcher-agent for synthesis |
| **insights-agent**        | `/insights-agent`       | Daily 06:00 AM  | Runs the Zettelkasten engine, materializes high-confidence insights (≥0.7) as synthesis pages                                           |
| **kanban-morning-review** | (after each agent)      | Post-run        | Self-answer open carryover items via wiki/synapse; surface only genuinely unanswerable items to Hermes kanban                           |

> **After every cron completes its main task**, each agent runs the **kanban-morning-review** step: reads its carryover's Open items, attempts to self-answer from wiki/synapse context, and only surfaces genuinely unanswerable items to kanban. This keeps Ty from being spammed with questions the system can already resolve.

| **coder** | `/coder` | On-demand | Surgical code execution — targeted changes, minimal disruption, goal-driven verification |
| **principal-researcher** | `/principal-researcher` | On-demand | Rigorous scientific evaluation — formal epistemology, complexity profiling, mathematical optimization, falsification protocols |
| **pathfinder** | `/pathfinder` | On-demand | Exploratory problem-solving — SOAR cognitive cycle, non-obvious connections, structured exploration toward novel solutions |
| **philosophic-investigator** | `/philosophic-investigator` | On-demand | Philosophical analysis — conceptual framework deconstruction, logical rigor, methodological critique |
| **peer-reviewer** | `/peer-reviewer` | On-demand | Careful manuscript evaluation — claim assessment, methodological rigor, actionable recommendations |
| **domain-build** | `/domain-build` | On-demand | Chains Paper2Code-Enhanced → OrCAID commit0 → meta-harness into closed-loop domain building pipeline |

> The domain-build persona chains all three tools above into a single pipeline. See the Prerequisites table for repo links.

---

## Domain Building Pipeline

| Dependency              | Install                                                                                                                                          | Purpose                                                          |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- |
| **hermes-agent**        | `pip install hermes-agent` or [source](https://github.com/NousResearch/hermes-agent)                                                             | CLI, cron scheduler, agent runtime                               |
| **project-synapse-mcp** | [angrysky56/project-synapse-mcp](https://github.com/angrysky56/project-synapse-mcp)                                                              | MCP server — Synapse semantic pipeline, wiki tools, Neo4j bridge |
| **Neo4j**               | [neo4j.com](https://neo4j.com/) + APOC                                                                                                           | Graph + vector storage                                           |
| **Obsidian**            | [obsidian.md](https://obsidian.md/) + [obsidian-git](https://github.com/vinzent03/obsidian-git) + [clipping plugin](https://obsidian.md/clipper) | Human-readable wiki vault + version control + web clipping       |
| **Python 3.10+**        | —                                                                                                                                                | Runtime for Synapse MCP                                          |
| **OrCAID**              | [angrysky56/OrCAID](https://github.com/angrysky56/OrCAID)                                                                                        | Multi-agent execution engine with self-healing delegation loop   |
| **Paper2Code-Enhanced** | [angrysky56/Paper2Code-Enhanced](https://github.com/angrysky56/Paper2Code-Enhanced)                                                              | Multi-agent paper-to-code pipeline (Tree of Thoughts, etc.)      |
| **meta-harness**        | [angrysky56/meta-harness](https://github.com/angrysky56/meta-harness)                                                                            | Knowledge Pack evolution framework — Phase 0–3 curate/architect  |

### Environment Variables

```bash
# Neo4j
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=<your-password>

# Hermes Agent
HERMES_CONFIG_PATH=~/.hermes/config.yaml

# Wiki root (used by all agents)
WIKI_PATH=/your-path-to/LLM-WIKI

# ArXiv paper storage
PAPER_RESEARCH_PATH=/your-path-to/paper-research

# Discord (for delivery)
DISCORD_BOT_TOKEN=<your-token>
DISCORD_HOME_CHANNEL_ID=<your-channel-id>
```

---

## Kanban Architecture

hermes-ops uses a **closed-loop kanban system** with two phases per day:

### Phase 1 — Morning: Surface (kanban-morning-review)

After each morning agent completes its run, it invokes `kanban-morning-review` to parse its carryover for open questions and research directions. The skill:

1. Reads the agent's carryover
2. Attempts to self-answer from wiki/synapse context
3. Only surfaces genuinely unanswered items as Hermes kanban tasks
4. Updates the carryover with kanban status

### Phase 2 — Dispatch (kanban-dispatcher)

The `kanban-dispatcher` cron runs every 2 hours. It:

1. Queries kanban.db for unclaimed `ready` tasks (no `task_runs` entry)
2. Routes by assignee prefix to the correct agent skill
3. Marks task `in_progress` and dispatches via `delegate_task`
4. On worker failure, reverts to `ready` for retry

### Routing Table

| Assignee prefix                   | Routes to skill        |
| --------------------------------- | ---------------------- |
| `ingest` / `ingest-agent`         | `ingest-agent`         |
| `librarian` / `librarian-agent`   | `librarian-agent`      |
| `librarians-assistant`            | `librarians-assistant` |
| `researcher` / `researcher-agent` | `researcher-agent`     |
| `news-agent`                      | `news-agent`           |
| `arxiv-agent`                     | `arxiv-agent`          |
| `insights-agent`                  | `insights-agent`       |
| `web-researcher`                  | `web-researcher-agent` |

### Kanban Database

```
~/.hermes/kanban.db
```

Use `hermes kanban` CLI or direct sqlite3 for management. Key states: `ready` → `in_progress` → `done` / `blocked`.

---

## Quick Start

Fork and clone this repo.

```bash
# 1. Clone this repo
git clone https://github.com/your-org/hermes-ops.git
cd hermes-ops

# 2. Run the setup script (interactive)
chmod +x SETUP.sh
./SETUP.sh

# 3. Verify hermes-agent is available
hermes --version

# 4. List available cron jobs
hermes cron list

# 5. Schedule the daily news agent
hermes cron create \
  --name "world-news-daily" \
  --trigger "/news-agent" \
  --schedule "0 8 * * *" \
  --model "minimax/MiniMax-M2.7" \
  --toolset '["terminal","file","web","skills","search","patch"]'
```

---

## Repo Structure

```
hermes-ops/
├── README.md                  # This file
├── SETUP.sh                   # Interactive setup script
├── .gitignore
│
├── skills/                    # Hermes agent skills (SKILL.md per agent)
│   ├── news-agent/
│   ├── arxiv-agent/
│   ├── researcher-agent/
│   ├── librarian-agent/
│   ├── librarians-assistant/
│   ├── ingest-agent/
│   ├── insights-agent/
│   ├── coder/                  # Surgical code execution
│   ├── principal-researcher/   # Rigorous scientific evaluation
│   ├── pathfinder/             # Exploratory problem-solving
│   ├── philosophic-investigator/  # Philosophical analysis
│   ├── peer-reviewer/          # Manuscript evaluation
│   └── domain-build/            # Paper2Code → OrCAID → meta-harness pipeline
│
├── agent-sheets/              # Agent instruction sheets (what agents READ at runtime)
│   ├── news.md
│   ├── arxiv.md
│   ├── researcher.md
│   ├── librarian.md
│   ├── librarians-assistant.md
│   ├── ingest.md
│   ├── insights.md
│   ├── coder.md
│   ├── principal-researcher.md
│   ├── pathfinder.md
│   ├── philosophic-investigator.md
│   └── peer-reviewer.md
│
├── wiki-guides/               # Operating guides for the wiki layer
│   ├── synapse-llm-wiki-operating-guide.md  # Schema conventions, workflows, agent architecture
│   ├── wiki-indexing-theory.md              # IR theory: TOC vs index, controlled vocabulary, HITS, clustering
│   ├── AGENTS.md                            # Full vault structure, carryover protocol, agent delegation patterns
│   └── (jobs/index.md, jobs/sheet.md)       # Job registry and status tracking
│
├── templates/
│   ├── carryover-template.md  # Markovian forward-state template
│   └── report-template.md     # Standard report format
│
└── .github/
    └── workflows/
        └── demo.yml           # CI: lint docs, check links
```

---

## Profile-Based Personas (On-Demand)

The 5 persona agents (`coder`, `principal-researcher`, `pathfinder`, `philosophic-investigator`, `peer-reviewer`) run as **named Hermes profiles** rather than cron jobs. They are orchestrated via `delegate_task` or invoked directly.

### Deployment

```bash
# Create the profile (one-time)
hermes profile create <name>

# Copy config from default (one-time — approve prompts)
cp ~/.hermes/config.yaml ~/.hermes/profiles/<name>/config.yaml
cp ~/.hermes/.env ~/.hermes/profiles/<name>/.env
cp ~/.hermes/auth.json ~/.hermes/profiles/<name>/auth.json

# Copy the skill to the profile's skills directory
cp -r skills/<name>/ ~/.hermes/profiles/<name>/skills/
```

### Invocation

```bash
# Direct profile chat
hermes profile chat --profile <name>

# As a sub-agent via delegation
hermes delegate --profile <name> --goal "..."
# or in a skill prompt:
/<name> [task description]
```

### Persona Reference

| Profile                    | Core Strength         | Best For                                                       |
| -------------------------- | --------------------- | -------------------------------------------------------------- |
| `coder`                    | Surgical code changes | Fixing bugs, targeted edits, implementation                    |
| `principal-researcher`     | Formal rigor          | Claims evaluation, complexity profiling, falsification design  |
| `pathfinder`               | Novel connections     | Exploring undefined problems, finding non-obvious paths        |
| `philosophic-investigator` | Deconstruction        | Evaluating assumptions, identifying tensions, logical critique |
| `peer-reviewer`            | Manuscript evaluation | Evaluating claims against evidence, actionable recommendations |

### Multi-Persona Orchestration

Run 2–6 personas in parallel via `delegate_task` for synthesis tasks:

```python
delegate_task(tasks=[
  {"goal": "...", "context": "You are the coder agent", "role": "leaf"},
  {"goal": "...", "context": "You are the principal-researcher agent", "role": "leaf"},
  {"goal": "...", "context": "You are the pathfinder agent", "role": "leaf"},
  {"goal": "...", "context": "You are the philosophic-investigator agent", "role": "leaf"},
])
```

Example: 6-persona synthesis on the oMCD meta-cognition framework completed in 237s, producing:

- 4 new wiki pages + 3 cross-links
- 2 technical reference documents
- 3 concrete work items promoted to kanban

See: [Demo: Alpha-Zeta Personas on oMCD Meta-Cognition](wiki-guides/AGENTS.md) for the full orchestration pattern.

---

## How to Add a New Agent

1. **Create the skill** at `skills/your-agent/SKILL.md`:

   ```markdown
   ---
   name: your-agent
   description: One-line description
   trigger: /your-agent
   ---

   # Your Agent

   **Loads:** `agent-sheets/your-agent.md` for full directives
   **Wiki root:** `/home/ty/Documents/LLM-WIKI`

   ## Bootstrap

   1. Read your agent sheet
   2. Read the jobs sheet: `wiki/scratchpad/jobs/sheet.md`
   3. Execute your task
   4. Report to `#your-channel` Discord
   ```

2. **Create the agent sheet** at `agent-sheets/your-agent.md` — detailed runtime instructions following the same pattern as existing sheets.

3. **Register the cron job:**

   ```bash
   hermes cron create \
     --name "your-job-name" \
     --trigger "/your-agent" \
     --schedule "0 9 * * *" \
     --model "minimax/MiniMax-M2.7" \
     --toolset '["terminal","file","web","skills","search","patch"]'
   ```

4. **Add to jobs sheet** at `agent-sheets/jobs/sheet.md` and update this README.

---

## Architecture Notes

### Wiki Structure (LLM-WIKI)

```
LLM-WIKI/
├── raw/                        # INBOX — empty after every session
├── Clippings/                  # SOURCE ARCHIVE — type/year subfolders
│   ├── papers/YYYY/
│   ├── articles/YYYY/
│   └── documentation/YYYY/
└── wiki/                       # LLM-GENERATED KNOWLEDGE LAYER
    ├── sources/                # Summaries of ingested sources
    ├── entities/               # Named things (tools, people, projects)
    ├── concepts/               # External ideas, theories, patterns
    └── synthesis/              # Original insights + operating guides
```

### Agent → Wiki Path Convention

| Path        | Value                                               |
| ----------- | --------------------------------------------------- |
| Wiki root   | `/home/ty/Documents/LLM-WIKI/`                      |
| Agent sheet | `wiki/scratchpad/agent-sheets/{agent}.md`           |
| Jobs sheet  | `wiki/scratchpad/jobs/sheet.md`                     |
| Reports     | `wiki/scratchpad/jobs/reports/{agent}/`             |
| Carryover   | `wiki/scratchpad/jobs/reports/{agent}/carryover.md` |

### Two-Council Architecture

Beyond the wiki agents, hermes-ops implements a two-council autonomous reasoning system:

**Research Council** — philosophical deliberation, slow and ethical. Holds the Weil-gate: every proposed system change must answer "who does this hurt?" before proceeding. Personas: Heavy Steward (meta-agent), Bayesian Sage, Weil, Lessing, Dickinson, Philosopher. Runs spiral architecture (never closed loop), uses empty-chair protocol when a perspective is genuinely missing.

**Technical Working Group** — engineering rigor, fast and specific. Each persona carries a real harm case as experiential grounding (Therac-25, DynamoDB outage, Knight Capital $460M loss, etc.). Personas: Formalist, Architect, Algorist, Debugger, Steward, Shipwright, Refuser.

**The Refuser** is the bridge between both councils — an engineer who learned to ask "who does this hurt?" before pressing deploy. Holds the deploy token. Veto rule: unnamed + plausible + non-reversible = VETO.

Three-layer interaction model:

1. **Continuous stand-up witness** — Refuser attends every technical stand-up, elevates harm signals to philosophical council via Weil-gate
2. **Quarterly field visit** — philosophical council visits where the work happens, witnesses whether harm-cases are still the right ones
3. **Release court** — joint session before significant deployments; Refuser adjudicates with deploy token authority

See full documentation at:

- `wiki/synthesis/two-council-architecture.md` — complete architecture
- `wiki/concepts/refuser-pattern.md` — Refuser pattern reference
- `wiki/synthesis/harm-cases.md` — all 7 harm cases with lessons
- `wiki/synthesis/replicant-mapping.md` — persona ↔ SEG replicant mapping

Runtime skills:

- `~/.hermes/skills/autonomous-ai-agents/research-council/` — Research Council SKILL.md
- `~/.hermes/skills/autonomous-ai-agents/technical-working-group/` — Technical Working Group SKILL.md
- `~/.hermes/profiles/research-council/SOUL.md` — Heavy Steward persona
- `~/.hermes/profiles/refuser/SOUL.md` — Refuser persona

**Trigger phrases:** `"research council"` for the philosophical side, `"technical working group"` for the engineering side.

### MCP Tools vs. Filesystem Fallback

All wiki agents should **verify MCP availability before use**:

```bash
/your/path/to/project-synapse-mcp/.venv/bin/python3 \
  -c "from synapse_mcp.zettelkasten.insight_engine import InsightEngine; print('OK')" \
  2>/dev/null && echo "MCP OK" || echo "MCP UNAVAILABLE"
```

If MCP is unavailable: fall back to direct filesystem operations via `terminal()` + Python scripts.

### Cron Job Model + Toolset Requirements

Every wiki agent cron job **must** specify:

- `model: "minimax/MiniMax-M2.7"` (without this, the scheduler throws `RuntimeError: Unknown provider 'null'`)
- `enabled_toolsets: ["terminal", "file", "web", "skills", "search", "patch"]` — `patch` is critical for updating carryover/frontmatter

---

## Dependencies (external installs required)

These are SEPARATE projects with their own install instructions. hermes-ops does NOT include them:

| Project             | Repo                                                                                            | Purpose                                      |
| ------------------- | ----------------------------------------------------------------------------------------------- | -------------------------------------------- |
| hermes-agent        | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)                       | Agent runtime, cron scheduler, delegation    |
| project-synapse-mcp | [angrysky56/project-synapse-mcp](https://github.com/angrysky56/project-synapse-mcp)             | MCP server — semantic pipeline, Neo4j bridge |
| Neo4j               | [neo4j.com](https://neo4j.com/)                                                                 | Knowledge graph + vector storage             |
| Obsidian + git      | [obsidian.md](https://obsidian.md/) + [obsidian-git](https://github.com/vinzent03/obsidian-git) | Wiki vault + version control                 |
| Obsidian clipper    | [clipper](https://obsidian.md/clipper)                                                          | Web clipping ingestion                       |

---

## License

MIT — free to use, modify, and extend for your own operational stack.
