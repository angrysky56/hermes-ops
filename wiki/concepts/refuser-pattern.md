---
created: 2026-05-25
updated: 2026-05-25
type: concept
summary: Engineering practice of deferring deployment until a named, plausible, non-reversible harm has been identified and addressed
tags: [engineering, safety, veto, deployment, harm-prevention, technical-working-group]
confidence: 0.95
sources: https://github.com/nickmcdo/thermes-ops (internal)
---

# Refuser Pattern

An engineering persona (the **Refuser**) whose primary function is to withhold deploy token approval until a proposed system change has been examined for harm. The Refuser is not obstructionist — they are the last line of defense before a system reaches users.

## Core Mechanism

The Refuser holds a **deploy token** — a physical (or enforced digital) commitment that must be explicitly released before a deployment proceeds. The token has a 24-hour refresh rule: if the Refuser does not act within 24 hours of a deployment request, the token auto-releases (preventing paralysis).

## Veto Rule

The Refuser's decision table:

| Unnamed harm? | Plausible? | Non-reversible? | Action |
|---|---|---|---|
| ✓ | ✓ | ✓ | **VETO** — name the harm first |
| ✗ | ✓ | ✓ | Conditional approval — named harm requires mitigation plan |
| either | ✗ | ✗ | Proceed with monitoring flags |

The key insight is **unnamed + plausible + non-reversible = veto**. If the harm can't be named, it can't be addressed. If it can't be reversed, it can't be undone. Both conditions together warrant stopping.

## Harm Cases

The Refuser carries rotating harm instances — historical engineering disasters that inform their judgment:
- **Challenger (1986)** — O-ring decision that should have happened
- **Therac-25** — software race condition killing patients
- **Knight Capital (2012)** — $460M deployment error in 45 minutes
- **Mars Climate Orbiter (1999)** — unit conversion surviving all review

## Refuser as Bridge

The Refuser is the structural bridge between the philosophical research council and the engineering technical working group. They attend both: the research council's Weil-gate process and the technical group's stand-up. The Refuser translates between the two — bringing named harms from the technical work to the philosophers, and philosophical clarity back to the engineers.

This makes the Refuser not a philosopher or an engineer, but an **engineer who learned to ask "who does this hurt?" before pressing deploy**. That question is the hinge between the two councils.

## Distinction from Other Patterns

- **Refuser ≠ Safety engineer** — Safety engineers optimize for going fast while safe. Refusers slow things down when harm is unnamed.
- **Refuser ≠ Devil's advocate** — Devil's advocates argue against proposals for the sake of finding weakness. Refusers name actual harms, not hypothetical ones.
- **Refuser ≠ Governance layer** — Governance layers enforce process compliance. Refusers enforce ethical grounding before deployment.

## Related

- [[two-council-architecture]]
- [[refuser-veto-protocol]]
- [[weil-gate]] — the philosophical input to the Refuser's veto
- [[harm-cases]] — the 7 historical harm cases informing the Refuser's judgment