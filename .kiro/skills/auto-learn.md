# Auto-Learn Skill

When discovering valuable patterns during work, append to `.kiro/learned/LEARNED.md`.

## Trigger Conditions

- Found a solution after hitting a bug (error message + fix)
- Discovered user preferences or habits
- Repeated operation patterns (can be abstracted as templates)
- User corrected agent's mistake (record correct approach)

## Format

```markdown
### [YYYY-MM-DD] AgentName — Short title

Description (1-3 lines, key info only)
```

## Do NOT Record

- One-time temporary info
- Content already in RESUME.md or WORKFLOW.md
- Obvious common knowledge

## Archival (avoid context bloat)

`LEARNED.md` should not grow unbounded. Apply these rules:

1. **Per-agent file**: When entries from a single agent exceed ~30, split into `learned/<agent-name>.md` and reference from the main file.
2. **Monthly archive**: At the end of each month, move entries older than 90 days into `learned/archive/YYYY-MM.md`. Keep only a one-line index in `LEARNED.md`:
   ```markdown
   ## Archive
   - [2026-03] 12 entries — [archive/2026-03.md](archive/2026-03.md)
   ```
3. **Keep recent N**: The active `LEARNED.md` should contain at most ~50 most-recent entries.
4. **Loadable subset**: agentSpawn hooks should load only `LEARNED.md` (not archives) to keep context lean.
