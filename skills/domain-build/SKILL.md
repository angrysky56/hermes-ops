---
name: domain-build
description: Domain building persona — chains Paper2Code-Enhanced + OrCAID commit0 into a closed-loop paper-to-validated-code pipeline, then meta-harness reads outcomes
trigger: /domain-build
skills: [paper2code-enhanced, orcaid]
---

# Domain Build — Paper2Code → OrCAID → Meta-Harness

## What This Does

```
Paper PDF → Paper2Code-Enhanced → generated repo
           ↓ (--patch_target)
OrCAID commit0 → validated + fixed repo
                 ↓
       Meta-harness reads orchestrator-memory/
       → computes frontier score + Pack delta proposals
```

## Key Paths

- Paper2Code-Enhanced CLI: `/home/ty/Repositories/ai_workspace/Paper2Code-Enhanced/paper2code-cli/build/stage/bin/paper2code-pp-cli`
- OrCAID: `/home/ty/Repositories/ai_workspace/OrCAID`
- Meta-harness: `/home/ty/Repositories/ai_workspace/meta-harness`
- Orchestrator memory: `~/.hermes/orcaid-bridge/` (symlink) or `~/.orcaid/orchestrator-memory/` (native)

## Stage 1 — Paper to Code

```bash
P=/home/ty/Repositories/ai_workspace/Paper2Code-Enhanced/paper2code-cli/build/stage/bin/paper2code-pp-cli

$P pipeline \
  --paper-name "<title>" \
  --pdf-json-path /path/to/<paper>_cleaned.json \
  --output-dir /tmp/paper2code/<slug>/artifacts \
  --output-repo-dir /tmp/paper2code/<slug>_repo \
  --run-planning \
  --run-analyzing \
  --run-coding \
  --run-debugging \
  --model MiniMax-M2.7 \
  --agent --json --no-input
```

Check output:
```bash
ls /tmp/paper2code/<slug>_repo/
# Expect: config.yaml, main.py, utils.py, tasks/, tot/, etc.
```

**Memory path fix:** If running OrCAID with `ORCHESTRATOR_MEMORY_BASE=~/.hermes/orcaid-bridge`, Paper2Code must output to a path that OrCAID can access as `--patch_target`.

## Stage 2 — Validate and Patch

```bash
cd /home/ty/Repositories/ai_workspace/OrCAID

uv run python -m orcaid.cli \
  --task=commit0 \
  --repo /tmp/paper2code/<slug>_repo \
  --patch_target /tmp/paper2code/<slug>_repo \
  --model=minimax/MiniMax-M2.7 \
  --multi_agent=false \
  --max_iterations=5
```

- `--repo` and `--patch_target` can both be the same path (self-validation mode)
- Use `--multi_agent=true` for 4-engineer parallel mode (slower but thorough)

**Memory path:** OrCAID writes verified outcomes to `~/.orcaid/orchestrator-memory/verified/` by default. Meta-harness reads from `~/.hermes/orcaid-bridge/`. Set `ORCHESTRATOR_MEMORY_BASE=~/.hermes/orcaid-bridge` before running OrCAID to align paths.

```bash
export ORCHESTRATOR_MEMORY_BASE=~/.hermes/orcaid-bridge
cd /home/ty/Repositories/ai_workspace/OrCAID && uv run python -m orcaid.cli [flags...]
```

## Stage 3 — Meta-Harness Read

```bash
cd /home/ty/Repositories/ai_workspace/meta-harness

uv run python run_evolution.py --domain orcaid --iterations 1
```

This reads `orchestrator-memory/verified/`, computes frontier scores, proposes Pack deltas. One iteration for read-only benchmark.

## Output

Report:
1. **Paper2Code**: repo path, files generated, line count (`wc -l $(find $repo -name "*.py")`)
2. **OrCAID**: patch count from outputs/patch.diff, files modified
3. **Meta-harness**: frontier score, top 3 Pack delta proposals

## OrCAID → Hermes Profile Mapping

Engineer roles map to Hermes profiles for OrCAID's self-healing loop:

| Engineer | Profile | Role |
|---|---|---|
| `engineer_1` | `coder` | Surgical fixes |
| `engineer_2` | `researcher` | Investigation |
| `engineer_3` | `peer-reviewer` | Evaluation |
| `engineer_4` | `pathfinder` | Novel connections |

## Verified Paths (from prior runs)

```bash
# Paper2Code output (Tree of Thoughts)
ls /home/ty/Repositories/ai_workspace/paper2code-projects/TreeOfThoughts_repo/

# OrCAID orchestrator memory
ls ~/.hermes/orcaid-bridge/verified/ 2>/dev/null || ls ~/.orcaid/orchestrator-memory/verified/

# Meta-harness domain
ls /home/ty/Repositories/ai_workspace/meta-harness/domains/orcaid/
```

## Pitfalls

| Issue | Fix |
|---|---|
| Paper2Code CLI not on PATH | Use full path: `P=/home/ty/Repositories/ai_workspace/Paper2Code-Enhanced/paper2code-cli/build/stage/bin/paper2code-pp-cli` |
| `--repo` and `--patch_target` same path = self-validation | Works fine — OrCAID self-heals its own output |
| Empty Paper2Code output | Check Stage 1 succeeded (`$P pipeline` exits 0) before Stage 2 |
| Meta-harness reads nothing | Memory path mismatch — set `ORCHESTRATOR_MEMORY_BASE=~/.hermes/orcaid-bridge` before OrCAID |
| Paper2Code paper2code domain empty | `~/Repositories/ai_workspace/meta-harness/domains/paper2code/` Pack not populated — only OrCAID is wired as evolvable domain |