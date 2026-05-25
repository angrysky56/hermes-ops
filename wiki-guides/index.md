---
summary: hermes-ops skill guides and agent sheet index
tags: [index, skills, agent-sheets, deployment]
updated: 2026-05-25
created: 2026-05-18
---

# hermes-ops — Skill Guides & Agent Sheets

Documentation for deploying personas, agent sheets, and skills in hermes-ops.

## Personas & Councils

| Persona | Skill Guide | Deployment |
|---------|-------------|------------|
| **Research Council** | [[skills/research-council/SKILL.md]] | SEG-powered philosophical deliberation |
| **Technical Working Group** | [[skills/technical-working-group/SKILL.md]] | Engineering safety council with Refuser veto |
| **Kanban Orchestrator** | [[skills/kanban-orchestrator/SKILL.md]] | Workflow creation and worker dispatch |

## Core Agent Sheets

| Agent | Sheet | Job ID | Schedule |
|-------|-------|--------|----------|
| Librarian | [[agent-sheets/librarian.md]] | — | — |
| Research | [[agent-sheets/researcher.md]] | — | — |
| Coder | [[agent-sheets/coder.md]] | — | — |
| News | [[agent-sheets/news.md]] | `eaaa6bdc8503` | Daily 08:00 |
| OrCAID | [[agent-sheets/orcaid.md]] | `orcaid-main-001` | Daily 09:00 |
| ArXiv | [[agent-sheets/arxiv.md]] | — | — |
| Pathfinder | [[agent-sheets/pathfinder.md]] | — | — |
| Principal Researcher | [[agent-sheets/principal-researcher.md]] | — | — |
| Philosophic Investigator | [[agent-sheets/philosophic-investigator.md]] | — | — |

## Skills Index

| Skill | Path | Purpose |
|-------|------|---------|
| `research-council` | `skills/research-council/` | SEG council deployment guide |
| `technical-working-group` | `skills/technical-working-group/` | TWG + Refuser deployment guide |
| `kanban-orchestrator` | `skills/kanban-orchestrator/` | Orchestrator dispatch guide |
| `coder` | `skills/coder/` | Surgical code execution |
| `orcaid` | `agent-sheets/orcaid.md` | OrCAID multi-agent delegation |
| `kanban` | `~/.hermes/skills/devops/kanban/SKILL.md` | Kanban workflow patterns (runtime) |

## Wiki Synthesis

Architecture docs written during this session:

- [[wiki/synthesis/two-council-architecture]] — Research Council + TWG stack
- [[wiki/synthesis/harm-cases]] — Documented harm patterns
- [[wiki/synthesis/replicant-mapping]] — SEG replicant → persona mapping
- [[wiki/synthesis/spiral-architecture]] — Spiral deliberation model
- [[wiki/synthesis/empty-chair-protocol]] — Missing voice protocol
- [[wiki/synthesis/refuser-pattern]] — Veto authority and Refuser

## Architecture

```
User
  ↓
kanban-orchestrator  (routing layer)
  ↓
research-council + technical-working-group  (tier-2 councils)
  ↓
workers — codex, orcaid, subagents  (execution layer)
  ↓
delegation-verification + kanban close  (verification layer)
```

Trigger phrases: `"research council"`, `"technical working group"`, `"orchestrator"`
