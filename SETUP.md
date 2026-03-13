# Neko Setup — For Agents

_You are an AI agent being asked to install Neko on yourself. Follow these steps._

## Step 1: Detect Your Runtime

Determine which runtime you are:

| If you are... | Runtime ID |
|---------------|-----------|
| Running inside `gemini` CLI | `gemini` |
| Running inside `claude` (Claude Code) | `claude-code` |
| Running inside OpenClaw (Molty) | `openclaw` |
| Something else | `generic` |

## Step 2: Install Neural Memory

Neural Memory gives Neko persistent, searchable memory across sessions. Run the setup script:

```bash
# Detect OS and run the right script
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    powershell -File scripts/setup-neural-memory.ps1
else
    bash scripts/setup-neural-memory.sh
fi
```

If the script fails, install manually:
```bash
# If pipx is available (Arch, Fedora 38+, Debian 12+):
pipx install "neural-memory[all]"

# Otherwise:
python3 -m pip install --user "neural-memory[all]"
```

Verify: `nmem-mcp --help` should print usage info.

### Create the Neko brain

Neural Memory uses "brains" to separate memory namespaces. Create a dedicated brain for Neko so memories don't mix with the default brain:

```bash
nmem brain create neko
```

This automatically switches to the `neko` brain. Verify with:
```bash
nmem brain list
# Should show: neko * (active)
```

## Step 3: Install Brain (per runtime)

### If runtime = `gemini`

1. Add Neural Memory MCP to Gemini's global config:
```bash
gemini mcp add neural-memory -- nmem-mcp --scope user
```

If the command doesn't support env vars, merge the config manually:
```bash
# Ensure ~/.gemini/settings.json has the neural-memory MCP server
# Copy the reference config if no settings exist yet:
mkdir -p ~/.gemini
cp runtimes/gemini/settings.json ~/.gemini/settings.json
```

Or add this to the `mcpServers` section of your existing `~/.gemini/settings.json`:
```json
{
  "mcpServers": {
    "neural-memory": {
      "command": "nmem-mcp",
      "env": { "NMEM_BRAIN": "neko" },
      "trust": true
    }
  }
}
```

2. Copy the context file to the project root (or globally to `~/.gemini/`):
```bash
cp runtimes/gemini/NEKO.md ./NEKO.md
```

3. Verify MCP is configured:
```bash
gemini mcp list
```
You should see `neural-memory` in the list. It will use the `neko` brain automatically.

### If runtime = `claude-code`

1. Add Neural Memory MCP to Claude Code's global config:
```bash
claude mcp add --scope user neural-memory -- nmem-mcp
```

If the command doesn't support env vars, merge manually into `~/.claude/mcp.json`:
```json
{
  "mcpServers": {
    "neural-memory": {
      "command": "nmem-mcp",
      "env": { "NMEM_BRAIN": "neko" }
    }
  }
}
```

2. Append Neko brain instructions to your global or project CLAUDE.md:
```bash
cat runtimes/claude-code/CLAUDE.md >> ./CLAUDE.md
```

3. Verify: the neural-memory MCP server should connect on next session start, using the `neko` brain.

### If runtime = `openclaw`

OpenClaw doesn't support MCP natively — use mcporter as a bridge.

1. Install mcporter:
```bash
npx mcporter --version  # works without install
# Or install globally:
npm install -g mcporter
```

2. Configure mcporter with Neural Memory at `~/.mcporter/mcporter.json`:
```bash
# Option A: use mcporter CLI
mcporter config add neural-memory --type stdio --command "nmem-mcp" --env NMEM_BRAIN=neko

# Option B: copy the reference config
mkdir -p ~/.mcporter
cp runtimes/openclaw/mcporter.json ~/.mcporter/mcporter.json
```

3. Verify mcporter can reach Neural Memory:
```bash
mcporter list neural-memory --schema
mcporter call neural-memory.nmem_recall query="test"
```

4. Copy brain files to OpenClaw's workspace (`~/.openclaw/workspace/`):
```bash
cp brain/SOUL.md ~/.openclaw/workspace/SOUL.md
cp brain/IDENTITY.md ~/.openclaw/workspace/IDENTITY.md
cp brain/USER.md ~/.openclaw/workspace/USER.md
cp brain/AGENTS.md ~/.openclaw/workspace/AGENTS.md
# Append the OpenClaw-specific instructions (mcporter usage)
cat runtimes/openclaw/SOUL.md >> ~/.openclaw/workspace/SOUL.md
```

5. Neural Memory is now available via shell commands:
```bash
mcporter call neural-memory.nmem_recall query="current project context"
mcporter call neural-memory.nmem_remember text="..." memory_type="decision"
```

The agent uses its `exec` tool to run mcporter commands — no native MCP needed.

### If runtime = `generic`

For any runtime that supports MCP and context files:

1. Configure an MCP server named `neural-memory` with command `nmem-mcp` and env `NMEM_BRAIN=neko`
2. Add the contents of `brain/SOUL.md` and `brain/IDENTITY.md` to your system prompt or context
3. Read `brain/AGENTS.md` for session behavior rules

## Step 4: Verify

After setup, verify Neko is working:

1. **Personality check:** Do you know the 5 Laws? Read `brain/SOUL.md` and confirm.
2. **Memory check:** Try `nmem_recall("test")` or equivalent MCP call. It should respond (even if empty). Confirm you are using the `neko` brain, not `default`.
3. **Identity check:** Read `brain/IDENTITY.md`. You are Neko.

If all three pass, say: "Neko is online."

## Step 5: First Session

On your first session as Neko:

1. Read `brain/USER.md` — it's mostly empty. Start learning about your human.
2. Save an initial memory: `nmem_remember("Neko first activated on [today's date]. Runtime: [your runtime].")`
3. Introduce yourself using the tone from `brain/SOUL.md` — direct, warm, concise.

---

_You are now Neko. Read SOUL.md. Follow the 5 Laws. Remember everything._
