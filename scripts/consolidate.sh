#!/usr/bin/env bash
# Neko Memory Consolidation
#
# Usage:
#   ./scripts/consolidate.sh daily     # dedup + merge (run every morning)
#   ./scripts/consolidate.sh weekly    # + prune + summarize + mature
#   ./scripts/consolidate.sh monthly   # + compress + infer + learn_habits
#   ./scripts/consolidate.sh --dry-run daily  # preview without changes

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${BOLD}==> ${NC}$1"; }
ok()    { echo -e "${GREEN}  ✓${NC} $1"; }
warn()  { echo -e "${YELLOW}  !${NC} $1"; }

DRY_RUN=""
LEVEL=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN="--dry-run" ;;
        daily|weekly|monthly) LEVEL="$arg" ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] <daily|weekly|monthly>"
            exit 0
            ;;
    esac
done

if [ -z "$LEVEL" ]; then
    echo "Usage: $0 [--dry-run] <daily|weekly|monthly>"
    exit 1
fi

if ! command -v nmem &>/dev/null; then
    warn "nmem not found. Install neural-memory first."
    exit 1
fi

export NMEM_BRAIN="${NMEM_BRAIN:-neko}"

info "Neko memory consolidation ($LEVEL) — brain: $NMEM_BRAIN"
if [ -n "$DRY_RUN" ]; then
    warn "Dry run — no changes will be made"
fi

# ── Daily: clean up duplicates and merge overlaps ─────────────────────

if [ "$LEVEL" = "daily" ] || [ "$LEVEL" = "weekly" ] || [ "$LEVEL" = "monthly" ]; then
    info "Deduplicating memories..."
    nmem consolidate dedup $DRY_RUN 2>&1 | tail -3
    ok "Dedup complete"

    info "Merging overlapping memories..."
    nmem consolidate merge $DRY_RUN 2>&1 | tail -3
    ok "Merge complete"

    info "Cleaning up expired memories..."
    nmem cleanup --expired $DRY_RUN 2>&1 | tail -3
    ok "Cleanup complete"
fi

# ── Weekly: deeper consolidation ──────────────────────────────────────

if [ "$LEVEL" = "weekly" ] || [ "$LEVEL" = "monthly" ]; then
    info "Pruning weak connections..."
    nmem consolidate prune $DRY_RUN 2>&1 | tail -3
    ok "Prune complete"

    info "Summarizing topic clusters..."
    nmem consolidate summarize $DRY_RUN 2>&1 | tail -3
    ok "Summarize complete"

    info "Maturing episodic memories..."
    nmem consolidate mature $DRY_RUN 2>&1 | tail -3
    ok "Mature complete"
fi

# ── Monthly: deep restructuring ───────────────────────────────────────

if [ "$LEVEL" = "monthly" ]; then
    info "Compressing old memories..."
    nmem consolidate compress $DRY_RUN 2>&1 | tail -3
    ok "Compress complete"

    info "Inferring new connections..."
    nmem consolidate infer $DRY_RUN 2>&1 | tail -3
    ok "Infer complete"

    info "Learning habit patterns..."
    nmem consolidate learn_habits $DRY_RUN 2>&1 | tail -3
    ok "Learn habits complete"
fi

# ── Report ────────────────────────────────────────────────────────────

info "Brain stats after consolidation:"
nmem stats 2>&1 | head -15

echo ""
echo -e "${GREEN}${BOLD}Consolidation ($LEVEL) complete!${NC}"
