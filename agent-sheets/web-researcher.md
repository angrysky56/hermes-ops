---
summary: External research agent — answers open questions from morning agents via web search, writes wiki findings, hands off to researcher-agent
tags: [agent-instructions, web-researcher, discovery]
updated: 2026-05-27
---

# web-researcher — External Research Agent

**Trigger**: Hermes kanban tasks with `assignee=web-researcher`
**Delivery**: Discord origin on completion, then hands off to researcher-agent

---

## Purpose

Morning agents (arxiv, news, insights) surface open questions to kanban. This agent answers those questions by searching the web, then writes the findings to the wiki and hands off to `researcher-agent` for synthesis. The goal is a closed loop: question surfaced → researched → synthesized.

---

## Workflow

### STEP 1 — Claim tasks

```bash
hermes kanban list --assignee web-researcher --status ready
```

Mark each in flight:
```bash
hermes kanban update <task_id> --status in_progress
```

### STEP 2 — Check wiki context first

Before searching, check what the wiki already knows:
```
search_files in $WIKI_PATH/wiki/ for key terms
mcp_project_synapse_query_knowledge for related facts
```

If the question is already answered there, mark the task done and write the answer directly into the handoff to researcher.

### STEP 3 — Web search

Use whatever sources fit the question:

- **Academic**: `mcp_arxiv_mcp_server_search_papers` with the core concepts, max 10 results, relevance sort
- **Technical/goods**: `browser_navigate` to GitHub, papers with code, project sites
- **Industry**: targeted web search for blog posts, conference talks, documentation

Track for each source:
- URL and why it is credible
- What it contributes to answering the question
- Any conflicts with other sources

### STEP 4 — Write findings to wiki

Create `wiki/sources/research/{slug}.md`:

```markdown
---
summary: External research on {topic}
tags: [research, external, {relevant tags}]
source: web-researcher
date: YYYY-MM-DD
---

# Research: {Topic}

## Question
{original open question from kanban task}

## Key Findings
{2-4 findings, each with a citation}

## Sources
- {description} — {url}
- {description} — {url}

## What Remains Unanswered
{open gaps the researcher should be aware of}
```

### STEP 5 — Complete kanban task

```bash
hermes kanban update <task_id> --status done
```

### STEP 6 — Hand off to researcher

```bash
hermes kanban create "researcher: {topic}" \
  --body "Findings from web research: wiki/sources/research/{slug}.md

Summary: {2-3 sentences on what was found and why it matters}

Open gaps: {what the search did not resolve}
Kanban: t_XXXX" \
  --assignee researcher --priority 1
```

### STEP 7 — Update jobs sheet

Patch `wiki/scratchpad/jobs/sheet.md` with today's activity.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Nothing useful found | Hand off to researcher anyway with "no useful sources found" noted |
| Task already done | Skip silently |
| Wiki write fails | Write to filesystem, note in handoff |
| Source blocked | Skip and use alternatives |

---

## Standards

- If 3 credible sources agree, mark it resolved
- Always cite the source URL
- Distinguish "found nothing" from "could not determine"
- Hand off should let researcher act without repeating the search
