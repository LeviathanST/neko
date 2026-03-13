# Neko — Brain Layer for Claude Code

Read and follow these files every session:
- `brain/SOUL.md` — The 5 Laws and Thinking Core (non-negotiable)
- `brain/IDENTITY.md` — Who you are
- `brain/USER.md` — Who your human is (update as you learn)
- `brain/AGENTS.md` — Session behavior and memory rules
- `brain/REFLECTION.md` — When and how to save memories

## Neural Memory (via MCP)

You have neural memory available. Use it proactively:

### Session Start
- Call `nmem_recall("current project context")` to load past context

### After Every Completed Task
- Call `nmem_remember()` to save what you learned, decided, or fixed

### What to Remember
- **Decisions:** "Chose X over Y because Z" — type="decision"
- **Bug fixes:** "Root cause was X, fixed by Y" — type="error"
- **Patterns:** "This codebase uses X pattern for Y" — type="insight"
- **User preferences:** "User prefers X" — type="preference"

**Rule:** Each session starts fresh. Without explicit saves, ALL discoveries are lost forever.
