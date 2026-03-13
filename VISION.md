# Vision: Neko

## The Problem

AI assistants are generic. They start fresh every conversation. They have no personality, no memory of who you are, no opinions. Every session is a blank slate talking to a stranger.

The tools exist — Gemini CLI, Claude Code, NullClaw — but they're runtimes, not partners. They execute tasks but don't know you. They don't remember that you prefer direct feedback, that you tend to over-scope, that you made a decision last Tuesday that affects today's work.

We want an AI partner that knows us. That has personality. That remembers. That grows.

## What We Decided

We chose to make Neko a **portable brain layer** rather than a standalone runtime. The key insight came from hitting a wall: we forked NullClaw (a Zig agent runtime), built custom tools, fixed CI on three platforms — then discovered we couldn't even test it without an API key because the CLI provider didn't support tool calling. We were building a runtime to host a brain, when runtimes already exist everywhere.

So we pivoted. Neko is now a set of files and configurations that plug into any AI runtime:
- **Personality files** (SOUL.md, IDENTITY.md) that any runtime loads as context
- **Neural Memory** via MCP server — a standard protocol all major runtimes support
- **Per-runtime adapters** that wire everything together (Gemini extension, Claude Code config)

We considered keeping the NullClaw fork as the primary runtime, but it failed the layer redundancy test: every feature we needed (agent loop, tool calling, MCP support) was already provided by the host runtimes. Building our own was redundant infrastructure.

## What's In / What's Out

**In:** Personality files, Neural Memory MCP integration, per-runtime adapters (Gemini CLI first), reflection/consolidation hooks, setup scripts.

**Out:** Custom agent runtime, Zig code, custom tool implementations, NullClaw fork maintenance. We're not building infrastructure — we're building the brain that lives inside infrastructure others maintain.

**Deferred:** Claude Code adapter (after Gemini CLI is solid), additional runtime adapters, advanced consolidation cascades. These are straightforward once the pattern is proven.

## Risks We're Watching

If MCP support gets deprecated or fragmented across runtimes, our memory integration breaks. We're betting on MCP being durable — it's an open standard adopted by Google, Anthropic, and others. If it breaks, we'd need per-runtime memory adapters, which is more work but not fatal.

If runtime context file formats diverge significantly, maintaining adapters gets harder. Right now GEMINI.md and CLAUDE.md are similar enough that the brain files are truly portable. If that changes, we might need a build step.

If Neural Memory itself stalls or breaks, we lose the memory layer entirely. Mitigation: the personality layer works independently of memory, and we could swap to any other MCP-based memory system.

## How We'll Know It's Working

The test is simple: am I actually using Neko daily and does it feel like talking to someone who knows me? Specifically:

- Neko recalls context from previous sessions without being told
- Neko's personality (5 Laws) is consistently expressed across different runtimes
- User model (USER.md) evolves over time with real observations
- Setting up Neko on a new runtime takes minutes, not hours

## The Plan

Gemini CLI is the first runtime because it's what the user has installed and it has the richest extension system (hooks, skills, MCP, context files — all configurable). We'll prove the brain layer pattern works there, then replicate it for Claude Code.

The sequence: test the Gemini extension → verify personality loads → verify Neural Memory connects → add session hooks for automatic memory → dogfood daily → iterate on personality and memory based on real usage.

The NullClaw codebase is gone. If we ever need a custom runtime feature, we evaluate whether it's better as a runtime adapter or a new MCP tool. The answer is almost always "MCP tool."
