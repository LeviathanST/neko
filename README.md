# Neko

**A Personalized-First AI Partner** — personality, memory, and reflection that plugs into any AI runtime.

Not a runtime. Not a framework. A brain.

## The 5 Laws

1. **Partner, Not Machine** — disagree, offer opinions, push back
2. **Constant Presence (Lighthouse)** — always available, continuous context
3. **Drive to Understand** — know the person, not just their tasks
4. **Simplicity Discipline (Zig Law)** — complexity is the enemy
5. **Identity Anchor** — keeper of history, pattern watcher

## Architecture

Neko is a portable brain layer. It doesn't need its own agent runtime — it plugs into existing ones.

```
brain/              Neko's soul — portable across all runtimes
  SOUL.md           The 5 Laws, Thinking Core, tone
  IDENTITY.md       Name, creature type, vibe
  USER.md           About the human (filled over time)
  AGENTS.md         Session behavior, memory rules
  STRATEGIST.md     Strategic advisor mode

runtimes/           Per-runtime adapters
  gemini/           Gemini CLI extension
  claude-code/      Claude Code config
  openclaw/         OpenClaw via mcporter bridge

scripts/            Setup utilities
  setup-neural-memory.sh   Install Neural Memory (Linux/macOS)
  setup-neural-memory.ps1  Install Neural Memory (Windows)
```

## How It Works

Neko's brain is just files. Any AI runtime that reads context files gets Neko's personality. Memory comes from Neural Memory via MCP — a standard protocol supported by all major runtimes.

| Component | What | How |
|-----------|------|-----|
| Personality | SOUL.md + IDENTITY.md | Context files (loaded every session) |
| Memory | Neural Memory MCP | 45 tools via MCP server |
| User Model | USER.md | Self-updating profile |
| Reflection | Hooks/prompts | Triggered by session lifecycle |

## Setup

Just tell your AI agent:

> "Set up Neko on yourself. Read SETUP.md and follow the instructions."

That's it. The agent reads [SETUP.md](SETUP.md) and installs Neko on itself — detects its runtime, installs Neural Memory, configures MCP, and verifies everything works.

### Supported Runtimes

- **Gemini CLI** — via extension (`gemini extensions link runtimes/gemini`)
- **Claude Code** — via `.mcp.json` + `CLAUDE.md`
- **OpenClaw** — via mcporter bridge (`mcporter call neural-memory.nmem_*`)
- **Any MCP-compatible runtime** — configure `nmem-mcp` as MCP server + load brain files as context

## Thinking Core

Three behavioral modes (not modules — behaviors expressed situationally):

- **Navigator** — map options before suggesting a path
- **Guardian** — watch for burnout, scope creep, bad patterns
- **Mentor** — E.V.A. Loop (Evidence, Validation, Adaptation)

## Memory

Neural Memory provides 45 tools via MCP:

- `nmem_remember` / `nmem_recall` — store and retrieve
- `nmem_explain` — trace connections
- `nmem_hypothesize` / `nmem_predict` / `nmem_verify` — cognitive reasoning
- `nmem_context` — session context
- `nmem_health` — brain health check

## Adding a New Runtime

To support a new AI runtime, create a directory under `runtimes/` with:

1. A context file that tells the runtime to load `brain/` files
2. MCP configuration pointing to `nmem-mcp` (native or via mcporter bridge)
3. (Optional) Hooks for session start/end memory operations

See `runtimes/gemini/` for a native MCP example, or `runtimes/openclaw/` for a mcporter bridge example.

## License

MIT — see [LICENSE](LICENSE)

---

**Neko** — Your partner, not your tool.
