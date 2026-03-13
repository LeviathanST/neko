#!/usr/bin/env bash
# Session end hook — saves a summary memory via Neural Memory CLI
# Used by runtimes that only support command-type hooks (Gemini CLI, OpenClaw)
#
# This is a best-effort save. The real reflection happens in-session
# via brain/REFLECTION.md instructions.

if ! command -v nmem &>/dev/null; then
    exit 0
fi

BRAIN="${NMEM_BRAIN:-neko}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

nmem remember \
    "Session ended at $TIMESTAMP. Agent should review and consolidate memories on next session start." \
    --type workflow \
    --priority 3 \
    2>/dev/null || true
