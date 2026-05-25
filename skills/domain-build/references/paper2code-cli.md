# Paper2Code-Enhanced CLI Reference

**Binary:** `/home/ty/Repositories/ai_workspace/Paper2Code-Enhanced/paper2code-cli/build/stage/bin/paper2code-pp-cli`

## pipeline

Starts the PaperCoder pipeline in the background and returns the run ID.

```bash
paper2code-pp-cli pipeline [flags]
```

**Key flags:**
| Flag | Default | Description |
|---|---|---|
| `--paper-name` | — | Name of the paper |
| `--pdf-json-path` | — | Path to the PDF-based JSON format |
| `--output-dir` | — | Directory to save generated artifacts |
| `--output-repo-dir` | — | Directory to save final output repository |
| `--run-planning` | true | Execute planning stage |
| `--run-analyzing` | true | Execute analyzing stage |
| `--run-coding` | true | Execute coding stage |
| `--run-debugging` | false | Execute debugging stage |
| `--model` | — | Model override (e.g. `MiniMax-M2.7`) |
| `--resume` | false | Resume from an interrupted or failed run |

**Agent mode flags:** `--agent --json --compact --no-input --no-color --yes`

## eval

Runs programmatic reference-free or reference-based evaluation.

```bash
paper2code-pp-cli eval [flags]
```

**Key flags:**
| Flag | Default | Description |
|---|---|---|
| `--paper-name` | — | Name of the paper |
| `--pdf-json-path` | — | Path to the PDF-based JSON |
| `--target-repo-dir` | — | Generated repository directory |
| `--gold-repo-dir` | — | Official gold repository directory |
| `--output-dir` | — | Artifact directory of the pipeline |
| `--eval-result-dir` | — | Directory to save evaluation results |
| `--eval-type` | `ref_free` | `ref_free` or `ref_based` |
| `--generated-n` | 8 | Number of evaluation samples to average |
| `--gpt-version` | — | Model choice override |

## doctor

Check CLI health and auth connectivity.

```bash
paper2code-pp-cli doctor --json
```