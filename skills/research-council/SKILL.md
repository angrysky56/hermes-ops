---
name: research-council
description: SEG-powered philosophical deliberation council — multi-persona reasoning on complex decisions. Trigger phrase: "research council".
profiles: [research-council]
model: MiniMax-M2.7
provider: minimax
---

# Research Council — hermes-ops Deployment Guide

**Runtime skill:** `~/.hermes/skills/autonomous-ai-agents/research-council/SKILL.md`

The Research Council is a philosophical deliberation layer. When activated, it runs a SEG-powered multi-persona council session to explore a premise from multiple experiential lenses before work is dispatched.

## Trigger

- `"research council"` — activates the philosophical council
- `"council on <topic>"` — starts a named council session

## Personas (7 Replicants)

| Replicant | Archetype | Role |
|-----------|-----------|------|
| **Bayesian Sage** | Rational updater | Probability and evidence weighting |
| **Comedic Trickster** | Chaos agent | Deflates certainty, surfaces hidden assumptions |
| **Weil** | Suffering witness | Who does this hurt? |
| **Lessing** | Historical dialectician | What did this look like before? |
| **Dickinson** | Lyric inward | What won't this say? |
| **Philosopher** | First-principles | What are the premises? |
| **Coder** | Systems builder | Does this actually run? |

## Deployment (hermes-ops)

### Step 1 — Load the skill

The runtime skill lives in `~/.hermes/skills/autonomous-ai-agents/research-council/SKILL.md`. No installation needed — Hermes loads it automatically when the trigger phrase is detected.

### Step 2 — Activate

```
hermes profile chat --profile research-council
```

Or trigger mid-conversation:
```
User: "We need a council on the autonomous hiring system case"
→ SEG council activates automatically
```

### Step 3 — Run the council session

Inside the profile, provide a premise. The council will:
1. Run 2 cycles of dialogic reasoning across all 7 replicants
2. Surface contradictions and veto-worthy patterns
3. Return a synthesis with named cases, formal constraints, and veto dispositions

### Step 4 — Extract work items

Council output contains:
- Named cases (e.g., "Maria Gutierrez", "James Adeyemi")
- Formal constraints (e.g., "origin-blind routing")
- Conditional vetoes
- Concrete work items → dispatch to kanban

## Output Schema

```
## Council Synthesis

### Veto Table
| Person | Veto? | Condition |
|--------|-------|-----------|
| Maria Gutierrez | VETO | Named + plausible + non-reversible |

### Constraints
- origin-blind routing: no geographic signal in initial screening

### Work Items
→ `hermes kanban create "Investigate regional bias in screening model"`
→ `hermes kanban create "Audit reversibility of candidate rejections"`
```

## Profile Files

- `~/.hermes/profiles/research-council/SOUL.md` — identity, directive, SEG framing
- `~/.hermes/skills/autonomous-ai-agents/research-council/SKILL.md` — runtime execution

## See Also

- [[two-council-architecture]] — how the research council fits above the technical working group
- [[spiral-architecture]] — inward spiral model for council deliberation
- [[empty-chair-protocol]] — how to invite missing perspectives