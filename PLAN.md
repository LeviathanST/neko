# Neko — Implementation Plan

**Phase:** Brain Layer Pivot
**Date:** 2026-03-13

## Architectural Decision

Neko is a **portable brain layer**, not an agent runtime. AI runtimes (Gemini CLI, Claude Code, etc.) already provide agent loops, tool calling, and MCP support. Neko's value is personality, memory, and reflection — these should be portable across runtimes.

**Why the pivot:** The previous approach (NullClaw fork) locked Neko into one runtime that required API keys for full functionality. CLI providers couldn't do tool calling. The runtime was redundant — we were building infrastructure our host already provides.

## Phase 1: Brain Layer

| Task | Status |
|------|--------|
| Define brain files (SOUL.md, IDENTITY.md, USER.md, AGENTS.md) | Done |
| Set up Neural Memory MCP server | Done |
| Create setup scripts (Linux/macOS/Windows) | Done |
| Create Gemini CLI extension adapter | Done |
| Create Claude Code adapter | Done |
| Test Gemini CLI with full brain + MCP | TODO |
| Test Claude Code with full brain + MCP | TODO |

## Phase 2: Runtime Adapters

| Task | Status |
|------|--------|
| Research Gemini CLI architecture | Done |
| Research Claude Code architecture | TODO |
| Gemini CLI: hooks for session start/end memory | TODO |
| Gemini CLI: skills (strategist, reflection) | TODO |
| Claude Code: hooks for memory lifecycle | TODO |

## Phase 3: Reflection & Consolidation

| Task | Status |
|------|--------|
| Design reflection trigger (end-of-session hook) | Done |
| Create brain/REFLECTION.md (memory discipline) | Done |
| Claude Code: Stop hook with prompt-type reflection | Done |
| Gemini CLI: command hooks + session-end-save script | Done |
| OpenClaw: REFLECTION.md instructions (mcporter calls) | Done |
| Create consolidation script (daily/weekly/monthly) | Done |
| Create cron setup script (OpenClaw + system crontab) | Done |
| Test memory recall → session → save cycle | TODO |

## Phase 4: Dogfood

| Task | Status |
|------|--------|
| Use Neko daily via Gemini CLI | TODO |
| Use Neko daily via Claude Code | TODO |
| Iterate on personality based on real usage | TODO |
| Tune memory and consolidation | TODO |

## Decisions Log

| Decision | Why | Date |
|----------|-----|------|
| 3-layer memory, not flat | Avoids chaos; mirrors note → remember → identity | 2026-03-12 |
| Neural Memory for persistent memory | Graph-based, 45 tools via MCP, cognitive reasoning | 2026-03-12 |
| Pivot from NullClaw fork to brain layer | CLIs already provide runtime; Neko's value is the brain, not the loop | 2026-03-13 |
| Gemini CLI extension as first adapter | User has gemini installed, no API key needed, rich extension system | 2026-03-13 |

## Next Action

Test Gemini CLI with the full brain layer: `gemini extensions link runtimes/gemini`, then run `gemini` and verify personality + Neural Memory tools work.
