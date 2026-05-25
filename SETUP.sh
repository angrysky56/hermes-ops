#!/usr/bin/env bash
#
# hermes-ops setup script
# Installs the operational layer: skills, agent sheets, wiki guides, templates
#

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

ask() {
  printf '%s%s%s ' "$YELLOW" "$1" "$RESET"
  read -r reply
  echo "$reply"
}

confirm() {
  printf '%s%s%s [Y/n] ' "$YELLOW" "$1" "$RESET"
  read -r reply
  [[ ! "${reply:-Y}" =~ ^[Nn]$ ]]
}

# ── Detect hermes-agent ───────────────────────────────────────────────────────
check_hermes() {
  if command -v hermes &>/dev/null; then
    HERMES_VERSION=$(hermes --version 2>/dev/null || echo "unknown")
    success "hermes-agent found: $HERMES_VERSION"
    return 0
  else
    warn "hermes-agent CLI not found in PATH"
    return 1
  fi
}

# ── Copy skills ───────────────────────────────────────────────────────────────
install_skills() {
  # hermes-ops skills dir → ~/.hermes/skills/ (sibling to built-in skills)
  local src="$(cd "$(dirname "$0")/../skills" && pwd)"
  local dest="$HOME/.hermes/skills"

  if [[ ! -d "$src" ]]; then
    warn "Source skills directory not found: $src"
    warn "Skipping skills installation"
    return 1
  fi

  info "Copying skills from $src to ~/.hermes/skills/ ..."

  mkdir -p "$dest"

  for agent_dir in "$src"/*/; do
    [[ -d "$agent_dir" ]] || continue
    agent_name=$(basename "$agent_dir")
    echo "  Copying skill: $agent_name"
    cp -r "$agent_dir" "$dest/"
    success "  $agent_name"
  done

  echo ""
  success "Skills installed to ~/.hermes/skills/"
  echo ""
}

# ── Copy agent sheets ─────────────────────────────────────────────────────────
install_agent_sheets() {
  # hermes-ops/agent-sheets → LLM-WIKI/wiki/scratchpad/agent-sheets/
  local src="$(cd "$(dirname "$0")/../agent-sheets" && pwd)"
  local wiki_path="${WIKI_PATH:-$HOME/Documents/LLM-WIKI}"
  local dest="$wiki_path/wiki/scratchpad/agent-sheets"

  if [[ ! -d "$src" ]]; then
    warn "Source agent-sheets directory not found: $src"
    warn "Skipping agent-sheets installation"
    return 1
  fi

  info "Copying agent-sheets from $src to $dest ..."

  mkdir -p "$dest"

  for sheet in "$src"/*.md; do
    [[ -f "$sheet" ]] || continue
    sheet_name=$(basename "$sheet")
    cp "$sheet" "$dest/"
    success "  $sheet_name"
  done

  echo ""
  success "Agent sheets installed to $dest"
  echo ""
}

# ── Copy wiki guides ──────────────────────────────────────────────────────────
install_wiki_guides() {
  local src="$HOME/Documents/LLM-WIKI/wiki/synthesis/synapse-llm-wiki-operating-guide.md"
  local dest="$HOME/Documents/LLM-WIKI/wiki/synthesis/synapse-llm-wiki-operating-guide.md"
  local out_dir="wiki-guides"

  info "Copying wiki operating guides ..."

  mkdir -p "$out_dir"

  if [[ -f "$src" ]]; then
    cp "$src" "$out_dir/"
    success "  synapse-llm-wiki-operating-guide.md"
  else
    warn "Operating guide not found at: $src"
  fi

  # Also copy the jobs index if it exists
  local jobs_src="$HOME/Documents/LLM-WIKI/wiki/scratchpad/jobs/index.md"
  if [[ -f "$jobs_src" ]]; then
    cp "$jobs_src" "$out_dir/"
    success "  jobs/index.md"
  fi

  echo ""
  success "Wiki guides installed to wiki-guides/"
  echo ""
}

# ── Copy templates ─────────────────────────────────────────────────────────────
install_templates() {
  info "Creating templates directory ..."

  mkdir -p templates

  # Carryover template
  cat > templates/carryover-template.md << 'EOF'
---
summary: Carryover state for {agent-name}
tags: [carryover, {agent-name}]
updated: {YYYY-MM-DD}
---

## Established
- **[Entity/Fact]** What was confirmed or decided (cite sources)
- ...

## Open
- **[Question]** What remains unresolved
- **[Risk]** What could go wrong
- ...

## Heading
- **[Intent]** Next session priority
- **[Constraint]** Budget, time, scope limits

---

*Hard cap: ~512 tokens (~2000 characters). Prioritize Open > Established > Heading.*
EOF
  success "  templates/carryover-template.md"

  # Report template
  cat > templates/report-template.md << 'EOF'
---
summary: {Agent} report — {YYYY-MM-DD}
tags: [{agent}, report]
updated: {YYYY-MM-DD}
---

# {Agent} Report — {YYYY-MM-DD}

## Summary
[Brief one-paragraph summary of what was done]

## Actions Taken
- [list of concrete actions]

## Wiki Updates
- New pages: N
- Updated pages: N
- Cross-links added: N

## Flagged Items
- [items needing human judgment or follow-up]

## Open Items
- [unresolved issues for next cycle]

## Notes
[Any errors, edge cases, or observations]
EOF
  success "  templates/report-template.md"

  echo ""
  success "Templates created in templates/"
  echo ""
}

# ── Print next steps ──────────────────────────────────────────────────────────
print_next_steps() {
  echo ""
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}                         NEXT STEPS${RESET}"
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
  echo ""
  echo "1. ${BOLD}Verify hermes-agent:${RESET}"
  echo "   hermes --version"
  echo ""
  echo "2. ${BOLD}Configure environment variables:${RESET}"
  echo "   export NEO4J_URI=bolt://localhost:7687"
  echo "   export NEO4J_USER=neo4j"
  echo "   export NEO4J_PASSWORD=<your-password>"
  echo "   export WIKI_PATH=/home/ty/Documents/LLM-WIKI"
  echo ""
  echo "3. ${BOLD}Install project-synapse-mcp (separate repo):${RESET}"
  echo "   git clone https://github.com/your-org/project-synapse-mcp.git"
  echo "   cd project-synapse-mcp && pip install -e ."
  echo ""
  echo "4. ${BOLD}Schedule the kanban dispatcher cron:${RESET}"
  echo "   hermes cron create \\"
  echo "     --name kanban-dispatcher \\"
  echo "     --prompt 'Run the kanban-dispatcher skill. Load it with skill_view(\"kanban-dispatcher\"), then execute the dispatch loop: query kanban for ready tasks with no task_runs, route to agent skills, dispatch via delegate_task. Report any tasks that need attention.' \\"
  echo "     --schedule '0 */2 * * *' \\"
  echo "     --model MiniMax-M2.7 \\"
  echo "     --skills kanban-dispatcher \\"
  echo "     --toolset '[\"terminal\",\"file\",\"skills\",\"delegation\"]' \\"
  echo "     --deliver origin"
  echo ""
  echo "5. ${BOLD}Schedule individual agent crons (or use the wiki/scratchpad/jobs/sheet.md pattern):${RESET}"
  echo "   hermes cron create \\"
  echo "     --name world-news-daily \\"
  echo "     --prompt 'Run the news-agent skill...' \\"
  echo "     --schedule '0 8 * * *' \\"
  echo "     --model MiniMax-M2-7 \\"
  echo "     --skills news-agent \\"
  echo "     --toolset '[\"terminal\",\"file\",\"web\",\"skills\",\"search\",\"patch\"]' \\"
  echo "     --deliver origin"
  echo ""
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${BOLD}${BLUE}hermes-ops setup${RESET}"
  echo -e "${BOLD}Operational layer for autonomous knowledge curation${RESET}"
  echo ""

  # Check hermes-agent
  if ! check_hermes; then
    echo ""
    warn "hermes-agent not found. Install it first:"
    echo "  pip install hermes-agent"
    echo "  or: https://github.com/NousResearch/hermes-agent"
    echo ""
    if ! confirm "Continue anyway (skills/sheets will still be copied)?"; then
      exit 0
    fi
  fi

  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo ""

  # Install components
  install_skills    && echo "" || true
  install_agent_sheets && echo "" || true
  install_wiki_guides && echo "" || true
  install_templates && echo "" || true

  echo "─────────────────────────────────────────────────────────"
  echo ""

  success "hermes-ops setup complete!"
  echo ""

  print_next_steps
}

main "$@"