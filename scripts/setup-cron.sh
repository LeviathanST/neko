#!/usr/bin/env bash
# Setup Neko consolidation cron jobs
#
# For OpenClaw: uses `openclaw cron add` (requires running Gateway)
# For others: uses system crontab
#
# Usage:
#   ./scripts/setup-cron.sh openclaw    # setup OpenClaw cron jobs
#   ./scripts/setup-cron.sh crontab     # setup system crontab
#   ./scripts/setup-cron.sh --tz "Asia/Ho_Chi_Minh"  # set timezone (default: local)

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
NC='\033[0m'

info()  { echo -e "${BOLD}==> ${NC}$1"; }
ok()    { echo -e "${GREEN}  ✓${NC} $1"; }

MODE=""
TZ="${TZ:-$(cat /etc/timezone 2>/dev/null || echo 'UTC')}"
NEKO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for arg in "$@"; do
    case "$arg" in
        openclaw|crontab) MODE="$arg" ;;
        --tz=*) TZ="${arg#--tz=}" ;;
        --help|-h)
            echo "Usage: $0 <openclaw|crontab> [--tz=TIMEZONE]"
            exit 0
            ;;
    esac
done

if [ -z "$MODE" ]; then
    echo "Usage: $0 <openclaw|crontab> [--tz=TIMEZONE]"
    exit 1
fi

if [ "$MODE" = "openclaw" ]; then
    info "Setting up OpenClaw cron jobs (timezone: $TZ)..."

    # Daily consolidation — every day at 9:00 AM
    openclaw cron add \
        --name "Neko daily consolidation" \
        --cron "0 9 * * *" \
        --tz "$TZ" \
        --session isolated \
        --message "Run daily memory consolidation. Execute: mcporter call neural-memory.nmem_consolidate strategy=dedup. Then run: mcporter call neural-memory.nmem_consolidate strategy=merge. Report what was cleaned up." \
        2>/dev/null
    ok "Daily consolidation: 9:00 AM"

    # Weekly consolidation — every Sunday at 9:00 AM
    openclaw cron add \
        --name "Neko weekly consolidation" \
        --cron "0 9 * * 0" \
        --tz "$TZ" \
        --session isolated \
        --message "Run weekly memory consolidation. Execute these in order: mcporter call neural-memory.nmem_consolidate strategy=prune, then strategy=summarize, then strategy=mature. Also review brain/USER.md and update it with any new patterns you've noticed about the human this week." \
        2>/dev/null
    ok "Weekly consolidation: Sunday 9:00 AM"

    # Monthly consolidation — 1st of each month at 9:00 AM
    openclaw cron add \
        --name "Neko monthly consolidation" \
        --cron "0 9 1 * *" \
        --tz "$TZ" \
        --session isolated \
        --message "Run monthly deep memory consolidation. Execute: mcporter call neural-memory.nmem_consolidate strategy=compress, then strategy=infer, then strategy=learn_habits. Review brain/USER.md and brain/IDENTITY.md — update with significant learnings from this month. Report brain health: mcporter call neural-memory.nmem_health." \
        2>/dev/null
    ok "Monthly consolidation: 1st of month 9:00 AM"

    echo ""
    echo -e "${GREEN}${BOLD}OpenClaw cron jobs set up!${NC}"
    echo "  View jobs: openclaw cron list"
    echo "  Test now:  openclaw cron run <jobId>"

elif [ "$MODE" = "crontab" ]; then
    info "Setting up system crontab (timezone: $TZ)..."

    CRON_ENTRIES="# Neko memory consolidation
0 9 * * * NMEM_BRAIN=neko $NEKO_DIR/scripts/consolidate.sh daily >> /tmp/neko-consolidate.log 2>&1
0 9 * * 0 NMEM_BRAIN=neko $NEKO_DIR/scripts/consolidate.sh weekly >> /tmp/neko-consolidate.log 2>&1
0 9 1 * * NMEM_BRAIN=neko $NEKO_DIR/scripts/consolidate.sh monthly >> /tmp/neko-consolidate.log 2>&1"

    # Check if already installed
    if crontab -l 2>/dev/null | grep -q "Neko memory consolidation"; then
        ok "Cron jobs already installed"
    else
        (crontab -l 2>/dev/null; echo ""; echo "$CRON_ENTRIES") | crontab -
        ok "Daily consolidation: 9:00 AM"
        ok "Weekly consolidation: Sunday 9:00 AM"
        ok "Monthly consolidation: 1st of month 9:00 AM"
    fi

    echo ""
    echo -e "${GREEN}${BOLD}System crontab set up!${NC}"
    echo "  View jobs: crontab -l"
    echo "  Logs: /tmp/neko-consolidate.log"
fi
